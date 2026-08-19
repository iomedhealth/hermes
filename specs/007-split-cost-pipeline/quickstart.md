# Quickstart & Validation Guide: Decouple Cost Ingestion & Modernize Airflow

**Feature**: Decouple Cost Ingestion & Modernize Airflow Pipeline  
**Date**: Wed Aug 19 2026

---

## 1. Prerequisites

Ensure Python virtual environment is activated with dependencies installed:
```bash
source .venv/bin/activate
pip install -r requirements.txt  # or ensure pandas, pyarrow, pypdfium2, openpyxl, beautifulsoup4, requests, pyyaml are installed
```

---

## 2. Validation Scenarios

### Scenario 1: Standalone Ground-Source Ingestion
Download a single regional source or the full gazette registry:
```bash
# 1. Download a single regional source
python scripts/download_costs_sources.py --source-id and-2024-precios

# 2. Ingest all 22 sources and INE CPI series
python scripts/download_costs_sources.py
```
**Expected Outcome**:
- Files populated in `data/raw/<id>.<fmt>` with size > 200 bytes.
- `data/ine_indices_sanidad.csv`, `.parquet`, `.json` generated.

---

### Scenario 2: Sub-Second Offline Scraping & Heuristic Refinement
Test and refine extraction on cached raw files without any network requests:
```bash
# 1. Inspect extraction on a single source in sub-second time
python scripts/scrape_costs_es.py --source-id and-2024-precios --limit-preview 10

# 2. Run full 100% offline catalog compilation
python scripts/scrape_costs_es.py
```
**Expected Outcome**:
- Runtime < 4 seconds for all 22 sources.
- Produces `data/costs_spain.csv`, `data/costs_spain.parquet`, and `data/costs_spain.json`.
- Zero network requests initiated.

---

### Scenario 3: Automated Unit & Invariant Testing
Execute test suite to ensure all assertions pass without regression:
```bash
python -m unittest tests/test_scrape_costs_es.py
```
**Expected Outcome**:
- 100% tests pass (encoding, code formatting, noise filtering, setting inference, catalog invariants).

---

### Scenario 4: Airflow DAG Local Verification
Verify the modernized TaskFlow DAG executes locally:
```bash
python dags/cost_extraction_dag.py
```
**Expected Outcome**:
- Airflow DAG parses cleanly and tasks execute sequentially in local mode.
