# Research & Technical Decisions: Decouple Cost Pipeline & Airflow Modernization

**Feature**: Decouple Cost Ingestion & Modernize Airflow Pipeline  
**Date**: Wed Aug 19 2026

---

## 1. Separation of Concerns: Ingestion vs. Transformation

### Decision
Split `scripts/scrape_costs_es.py` into:
1. `scripts/download_costs_sources.py`: Responsible exclusively for network I/O, session/SSL headers, downloading raw files into `data/raw/`, querying the INE REST API, and persisting canonical index series (`data/ine_indices_sanidad.*`).
2. `scripts/scrape_costs_es.py`: Pure offline computational engine that reads from `data/raw/`, applies multi-encoding text decoding, parsing (PDF, Excel, HTML), regex code standardization, clinical taxonomy inference, deflation, deduplication, and catalog export.

### Rationale
- **Development Feedback Loop**: Iterating on regexes or layout heuristics currently took seconds to minutes because the script validated or re-downloaded sources. Offline execution reduces iteration time to ~200ms per source.
- **Resilience**: Regional gazette URLs frequently have transient DNS/SSL or rate-limiting glitches. Separating ingestion prevents parser debugging from being blocked by third-party website downtime.
- **Single Responsibility Principle**: Ingestion handles network protocols, user agents, and file writes. Transformation handles data cleaning, standardization, and schema invariants.

### Alternatives Evaluated
- *Keep monolithic file with `--skip-download` flag*: Rejected because it leaves network dependencies and text parsing coupled in one 1,600+ line file, keeps scheduler parse time heavy, and complicates unit test isolation.
- *Full Python package / subpackage structure (`hermes_costs/`)*: Rejected under Ponytail / YAGNI principles; HERMES is an R package with lightweight helper Python scripts. Two focused scripts in `scripts/` provide the cleanest developer experience.

---

## 2. Airflow Modernization: TaskFlow API & Dynamic Task Mapping

### Decision
Refactor `dags/cost_extraction_dag.py` from Airflow 1.x-style `PythonOperator` to Airflow 2.3+ TaskFlow decorators (`@dag`, `@task`) using Dynamic Task Mapping (`.expand()`).

### Design
```python
# TaskFlow workflow with mapped tasks:
@dag(
    dag_id="hermes_cost_catalogs_etl",
    schedule="@monthly",
    catchup=False,
    tags=["heor", "hcru", "tariffs", "spain", "hermes"],
)
def hermes_cost_catalogs_pipeline():
    sources = load_registry_sources()
    deflators = fetch_deflators()
    
    # 22 dynamic parallel download tasks:
    raw_files = download_raw_source.expand(src=sources)
    
    # 22 dynamic parallel extraction tasks:
    extracted = extract_single_source.partial(deflators=deflators).expand(item=raw_files)
    
    # Consolidation, deduplication & export:
    consolidate_validate_and_export(extracted, deflators=deflators)
```

### Rationale
- **Granular Retries & Blast Radius**: Each CCAA runs as its own mapped task instance. If 1 source fails or times out, only that single mapped task retries; the other 21 succeed independently.
- **Parallelism**: Airflow workers download and extract multiple gazettes concurrently.
- **Top-Level Parse Performance**: Heavy modules (`pypdfium2`, `openpyxl`, `bs4`, `pandas`) are imported inside task functions rather than at module top-level, keeping scheduler DAG parsing under 10ms.
- **Data-Aware Reactivity**: Emits `Dataset("file://data/costs_spain.parquet")` for event-driven downstream pipelines.

---

## 3. Backward Compatibility & Test Guarantees

### Decision
- Keep all function signatures used by tests (`format_code_std`, `infer_setting`, `infer_omop_domain`, `infer_unit_type`, `is_noise_text`, `read_text_file`, `parse_price`) in `scripts/scrape_costs_es.py`.
- Re-export INE helper functions (`fetch_ine_deflators`, `export_ine_tables`, `DEFAULT_SANIDAD_INDICES`, `TARGET_YEAR`) in `scripts/scrape_costs_es.py` via clean module import from `scripts/download_costs_sources.py`.
- Ensure `python -m unittest tests/test_scrape_costs_es.py` runs without modification and passes all assertions.
