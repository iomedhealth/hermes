#!/usr/bin/env python3
"""
dags/cost_extraction_dag.py - Modern TaskFlow Airflow DAG for HERMES Spanish Healthcare Cost ETL Pipeline.

Features:
- TaskFlow API (@dag, @task) with deferred scheduler-safe imports.
- Dynamic Task Mapping (.expand()) for parallel, isolated per-source download and extraction tasks.
- Data-aware scheduling via Airflow Dataset outlet (`data/costs_spain.parquet`).
- Dual-mode execution: full cluster execution and local standalone testing.
"""

import os
import sys
from datetime import datetime, timedelta

# Ensure repo root is on sys.path
REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../.."))
if REPO_ROOT not in sys.path:
    sys.path.insert(0, REPO_ROOT)

# Support both Airflow 2.x and Airflow 3.x TaskFlow imports
try:
    from airflow.sdk import dag, task
except ImportError:
    from airflow.decorators import dag, task

# Support both Airflow 2.x and 3.x Dataset/Asset definitions
try:
    from airflow.datasets import Dataset
    SPAIN_COSTS_DATASET = Dataset(f"file://{os.path.join(REPO_ROOT, 'packages/CohortCosts/data/processed/costs_spain.parquet')}")
except (ImportError, AttributeError):
    try:
        from airflow.sdk.definitions.asset import Asset
        SPAIN_COSTS_DATASET = Asset(f"file://{os.path.join(REPO_ROOT, 'packages/CohortCosts/data/processed/costs_spain.parquet')}")
    except Exception:
        SPAIN_COSTS_DATASET = None

DEFAULT_ARGS = {
    "owner": "hermes-heor",
    "depends_on_past": False,
    "start_date": datetime(2026, 1, 1),
    "email_on_failure": False,
    "email_on_retry": False,
    "retries": 2,
    "retry_delay": timedelta(minutes=2),
}


@dag(
    dag_id="hermes_cost_catalogs_etl",
    default_args=DEFAULT_ARGS,
    description="Automated ETL pipeline for Spanish Healthcare Tariffs and Cost Catalogs",
    schedule="@monthly",
    catchup=False,
    tags=["heor", "hcru", "tariffs", "spain", "hermes"],
)
def hermes_cost_catalogs_pipeline():
    """Airflow TaskFlow ETL DAG for Spanish ground-source cost extraction."""

    @task
    def get_registered_sources() -> list:
        """Read source metadata from registries.yml."""
        import yaml

        registry_path = os.path.join(
            REPO_ROOT, "packages/CohortCosts/data/specs/registries.yml"
        )
        with open(registry_path, "r", encoding="utf-8") as f:
            registry = yaml.safe_load(f)
        return registry.get("sources", [])

    @task(retries=3, retry_delay=timedelta(seconds=20))
    def download_source_task(src: dict) -> dict:
        """Download or verify a single raw source in packages/CohortCosts/data/raw/."""
        from packages.CohortCosts.scripts.download_costs_sources import download_source

        raw_dir = os.path.join(REPO_ROOT, "packages/CohortCosts/data/raw")
        file_path = download_source(src, raw_dir=raw_dir)
        return {"source": src, "file_path": file_path}

    @task
    def compute_ine_deflators_task() -> dict:
        """Fetch INE ECOICOP 06 Sanidad price indices and export canonical datasets."""
        from packages.CohortCosts.scripts.download_costs_sources import (
            export_ine_tables,
            fetch_ine_deflators,
        )

        raw_path = os.path.join(
            REPO_ROOT, "packages/CohortCosts/data/external/ine-ipc-medicina.json"
        )
        output_dir = os.path.join(REPO_ROOT, "packages/CohortCosts/data/external")
        deflators = fetch_ine_deflators(cache_path=raw_path)
        export_ine_tables(output_dir=output_dir, raw_path=raw_path)
        return {str(k): float(v) for k, v in deflators.items()}

    @task
    def extract_single_source_task(downloaded_item: dict, deflators: dict) -> list:
        """Extract and normalize cost records from a single downloaded file."""
        from dataclasses import asdict
        from packages.CohortCosts.scripts.scrape_costs_es import extract_source_records

        src = downloaded_item["source"]
        file_path = downloaded_item["file_path"]

        if not os.path.exists(file_path) or os.path.getsize(file_path) < 100:
            return []

        # Convert string year keys to ints if serialized over XCom
        deflators_int = {int(k): float(v) for k, v in deflators.items()}
        records = extract_source_records(src, file_path, deflators_int)
        return [asdict(r) for r in records]

    outlets = [SPAIN_COSTS_DATASET] if SPAIN_COSTS_DATASET else []

    @task(outlets=outlets)
    def consolidate_and_export_task(extracted_batches: list, deflators: dict) -> int:
        """Consolidate mapped extractions, apply deduplication, validate invariants, and export catalogs."""
        from packages.CohortCosts.scripts.scrape_costs_es import CostRecord, consolidate_and_export

        all_records = []
        for batch in extracted_batches:
            for item in batch:
                all_records.append(CostRecord(**item))

        output_csv = os.path.join(
            REPO_ROOT, "packages/CohortCosts/data/processed/costs_spain.csv"
        )
        output_parquet = os.path.join(
            REPO_ROOT, "packages/CohortCosts/data/processed/costs_spain.parquet"
        )
        output_json = os.path.join(
            REPO_ROOT, "packages/CohortCosts/data/processed/costs_spain.json"
        )

        df = consolidate_and_export(
            records=all_records,
            output_csv=output_csv,
            output_parquet=output_parquet,
            output_json=output_json,
        )
        return len(df)

    # TaskFlow Dynamic Mapping Workflow
    sources = get_registered_sources()
    deflators = compute_ine_deflators_task()
    raw_files = download_source_task.expand(src=sources)
    extracted = extract_single_source_task.partial(deflators=deflators).expand(
        downloaded_item=raw_files
    )
    consolidate_and_export_task(extracted, deflators=deflators)


dag_instance = hermes_cost_catalogs_pipeline()


if __name__ == "__main__":
    print("[RUN] Executing Airflow TaskFlow DAG locally (sequential test mode)...")
    import yaml
    from packages.CohortCosts.scripts.download_costs_sources import (
        download_source,
        export_ine_tables,
        fetch_ine_deflators,
    )
    from packages.CohortCosts.scripts.scrape_costs_es import (
        consolidate_and_export,
        extract_source_records,
    )

    registry_path = os.path.join(
        REPO_ROOT, "packages/CohortCosts/data/specs/registries.yml"
    )
    with open(registry_path, "r", encoding="utf-8") as f:
        registry = yaml.safe_load(f)

    raw_dir = os.path.join(REPO_ROOT, "packages/CohortCosts/data/raw")
    raw_path = os.path.join(
        REPO_ROOT, "packages/CohortCosts/data/external/ine-ipc-medicina.json"
    )
    output_dir = os.path.join(REPO_ROOT, "packages/CohortCosts/data/processed")
    external_dir = os.path.join(REPO_ROOT, "packages/CohortCosts/data/external")

    deflators = fetch_ine_deflators(cache_path=raw_path)
    export_ine_tables(output_dir=external_dir, raw_path=raw_path)

    all_records = []
    for src in registry.get("sources", []):
        file_path = download_source(src, raw_dir=raw_dir)
        if os.path.exists(file_path) and os.path.getsize(file_path) >= 100:
            recs = extract_source_records(src, file_path, deflators)
            all_records.extend(recs)

    output_csv = os.path.join(output_dir, "costs_spain.csv")
    output_parquet = os.path.join(output_dir, "costs_spain.parquet")
    output_json = os.path.join(output_dir, "costs_spain.json")

    df = consolidate_and_export(
        records=all_records,
        output_csv=output_csv,
        output_parquet=output_parquet,
        output_json=output_json,
    )
    print(f"[RUN] Airflow local runner completed successfully with {len(df):,} catalog rows.")
