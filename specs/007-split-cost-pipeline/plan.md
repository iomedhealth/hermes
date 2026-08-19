# Implementation Plan: Decouple Cost Ingestion & Modernize Airflow Pipeline

**Branch**: `007-split-cost-pipeline` | **Date**: Wed Aug 19 2026 | **Spec**: [specs/007-split-cost-pipeline/spec.md](spec.md)

**Input**: Feature specification to decouple ground-source downloading from parsing/scraping and modernize the Airflow DAG to TaskFlow API and Dynamic Task Mapping.

---

## Summary

Decouple `scripts/scrape_costs_es.py` into two distinct scripts:
1. `scripts/download_costs_sources.py` (network ingestion, SSL handling, raw caching in `data/raw/`, INE CPI query, and canonical index dataset export)
2. `scripts/scrape_costs_es.py` (100% offline parsing, multi-format extraction, clinical code standardization, taxonomy inference, and catalog consolidation/export).

Simultaneously modernize `dags/cost_extraction_dag.py` to leverage the modern Airflow 2+ TaskFlow API (`@dag`, `@task`), Dynamic Task Mapping (`.expand()`), lightweight scheduler parsing, and Airflow `Dataset` outlets.

---

## Technical Context

**Language/Version**: Python 3.10+ / Python 3.14 (dedicated `.venv`)

**Primary Dependencies**: `pandas`, `pyarrow`, `pypdfium2`, `openpyxl`, `beautifulsoup4`, `requests`, `pyyaml`, `apache-airflow`

**Storage & Files**:
- Downloader script: `scripts/download_costs_sources.py`
- Offline scraper script: `scripts/scrape_costs_es.py`
- Airflow DAG: `dags/cost_extraction_dag.py`
- Raw cache: `data/raw/*` (PDF, HTML, XLSX, JSON)
- Metadata registry: `data/specs/registries.yml`
- Canonical catalogs: `data/costs_spain.csv`, `data/costs_spain.parquet`, `data/costs_spain.json`
- Canonical deflators: `data/ine_indices_sanidad.csv`, `data/ine_indices_sanidad.parquet`, `data/ine_indices_sanidad.json`

**Testing**: Unit & integration tests in `tests/test_scrape_costs_es.py` + Airflow local execution check.

**Performance Goals**:
- Sub-second (<1.0s) offline extraction and inspection for any single regional source (`--source-id <id>`).
- Complete offline catalog generation from cached raw files in <4.0 seconds.
- 0 network requests during scraper execution.

---

## Constitution Check

- [x] **I. Zero Wheel-Reinvention**: Leverages Python stdlib, `requests`, `pypdfium2`, `openpyxl`, `bs4`, `pandas`, and Airflow TaskFlow API without unnecessary custom wrapper frameworks.
- [x] **II. Standardized OMOP CDM & COST Integration**: Preserves all OMOP domain assignments (`Visit`, `Procedure`, `Measurement`, `Drug`) and clinical settings (`Inpatient`, `Diagnostics`, `Procedures`, `Primary Care`, `Outpatient`).
- [x] **III. Pipeable & Modular Architecture**: Clean separation between I/O bound network ingestion (`download_source`, `fetch_ine_deflators`) and CPU-bound parsing/transformation (`extract_source_records`, `consolidate_and_export`).
- [x] **IV. Test-First & Coverage**: 100% preservation of unit test assertions in `tests/test_scrape_costs_es.py` with zero regressions.
- [x] **V. 6-Stage Pipeline Alignment**: Powers Stage 2 (HCRU Characterization) and Stage 4 (State-Cost Extraction) with zero downtime and reproducible offline tariffs.

---

## Project Structure

### Documentation (this feature)

```text
specs/007-split-cost-pipeline/
├── spec.md              # Feature specification
├── plan.md              # This implementation plan
├── research.md          # Design decisions & architectural research
├── data-model.md        # Entities, CLI schemas, and data structures
├── quickstart.md        # Verification guide & execution commands
├── contracts/
│   └── split-cost-pipeline-contracts.md  # CLI & Python API contracts
└── checklists/
    └── requirements.md  # Specification quality checklist
```

### Source Code

```text
scripts/
├── download_costs_sources.py  # [NEW] Network ingestion, SSL management, INE index persistence
└── scrape_costs_es.py         # [REFACTORED] Pure offline scraper, extractor, normalizer, and catalog exporter

dags/
└── cost_extraction_dag.py     # [REFACTORED] Modern TaskFlow DAG with dynamic task mapping (.expand)

tests/
└── test_scrape_costs_es.py    # Unit and integration test suite
```

---

## Phases & Deliverables

1. **Phase 0**: Research & Design Decisions (`research.md`)
2. **Phase 1**: Data Model (`data-model.md`), Contracts (`contracts/`), Quickstart Guide (`quickstart.md`)
3. **Phase 2**: Implementation of `download_costs_sources.py`, refactoring `scrape_costs_es.py`, modernizing `cost_extraction_dag.py`, updating tests and verifying full pipeline execution.
