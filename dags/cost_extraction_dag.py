#!/usr/bin/env python3
"""
dags/cost_extraction_dag.py - Airflow DAG for HERMES Spanish Healthcare Cost ETL Pipeline.

Defines a 4-stage reproducible ETL DAG:
1. Ingestion: Download raw gazettes, web tables, and Excel Casemix workbooks.
2. Deflation: Query official INE Healthcare CPI series (Subgroup 06) and export canonical index datasets.
3. Extraction & Normalization: Parse, standardize codes (APR-GRD, ICD-9-CM, ICD-10-PCS, CN), infer settings/domains.
4. Validation & Export: Assert 0 nulls, unique IDs, CCAA completeness, and write CSV/Parquet/JSON catalogs.
"""

import os
import sys
from datetime import datetime, timedelta

# Ensure repo root is on sys.path
REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
if REPO_ROOT not in sys.path:
    sys.path.insert(0, REPO_ROOT)

from airflow import DAG

try:
    from airflow.providers.standard.operators.python import PythonOperator
except ImportError:
    from airflow.operators.python import PythonOperator

from scripts.scrape_costs_es import (
    TARGET_YEAR,
    download_source,
    export_ine_tables,
    extract_grd_excel,
    extract_html_catalog,
    extract_pdf_catalog,
    fetch_ine_deflators,
    run_pipeline,
)


def task_download_registries_fn(**context):
    """Task 1: Ingest all 22 ground sources into data/raw/."""
    import yaml

    registry_path = os.path.join(REPO_ROOT, "data/specs/registries.yml")
    with open(registry_path, "r", encoding="utf-8") as f:
        registry = yaml.safe_load(f)

    downloaded = []
    for src in registry.get("sources", []):
        path = download_source(src, raw_dir=os.path.join(REPO_ROOT, "data/raw"))
        downloaded.append((src["id"], path))
    print(f"[AIRFLOW] Successfully verified/downloaded {len(downloaded)} raw sources.")
    return len(downloaded)


def task_fetch_deflators_fn(**context):
    """Task 2: Fetch and compute INE Sanidad deflator index series and export canonical datasets."""
    raw_path = os.path.join(REPO_ROOT, "data/raw/ine-ipc-medicina.json")
    output_dir = os.path.join(REPO_ROOT, "data")
    deflators = fetch_ine_deflators(cache_path=raw_path)
    df_ine = export_ine_tables(output_dir=output_dir, raw_path=raw_path)
    print(
        f"[AIRFLOW] Loaded {len(deflators)} annual deflators. Target {TARGET_YEAR} = {deflators.get(TARGET_YEAR)}. Exported {len(df_ine)} INE index records."
    )
    return deflators


def task_extract_and_normalize_fn(**context):
    """Task 3 & 4: Extract, normalize, inflate, validate, and export catalogs using XCom deflators."""
    ti = context.get("ti")
    deflators = None
    if ti:
        deflators = ti.xcom_pull(task_ids="compute_ine_deflators")

    registry_path = os.path.join(REPO_ROOT, "data/specs/registries.yml")
    output_csv = os.path.join(REPO_ROOT, "data/costs_spain.csv")
    output_parquet = os.path.join(REPO_ROOT, "data/costs_spain.parquet")
    output_json = os.path.join(REPO_ROOT, "data/costs_spain.json")

    df, _ = run_pipeline(
        registry_path=registry_path,
        output_csv=output_csv,
        output_parquet=output_parquet,
        output_json=output_json,
        download_fresh=False,  # Already refreshed in Task 1
        deflators=deflators,
    )
    print(f"[AIRFLOW] Pipeline complete: {len(df):,} records validated and published.")
    return len(df)


default_args = {
    "owner": "hermes-heor",
    "depends_on_past": False,
    "start_date": datetime(2026, 1, 1),
    "email_on_failure": False,
    "email_on_retry": False,
    "retries": 2,
    "retry_delay": timedelta(minutes=5),
}

dag = DAG(
    dag_id="hermes_cost_catalogs_etl",
    default_args=default_args,
    description="Automated ETL pipeline for Spanish Healthcare Tariffs and Cost Catalogs",
    schedule="@monthly",
    catchup=False,
    tags=["heor", "hcru", "tariffs", "spain", "hermes"],
)

with dag:
    t1_download = PythonOperator(
        task_id="ingest_raw_registries",
        python_callable=task_download_registries_fn,
    )

    t2_deflators = PythonOperator(
        task_id="compute_ine_deflators",
        python_callable=task_fetch_deflators_fn,
    )

    t3_etl_export = PythonOperator(
        task_id="extract_normalize_validate_export",
        python_callable=task_extract_and_normalize_fn,
    )

    t1_download >> t2_deflators >> t3_etl_export


if __name__ == "__main__":
    print("[RUN] Executing Airflow DAG locally...")
    task_download_registries_fn()
    d = task_fetch_deflators_fn()
    task_extract_and_normalize_fn()
    print("[RUN] Finished DAG execution successfully.")
