# Implementation Plan: Spanish Ground-Source Healthcare Cost Pipeline Remediation

**Branch**: `006-fix-cost-pipeline` | **Date**: Wed Aug 19 2026 | **Spec**: [specs/006-fix-cost-pipeline/spec.md](spec.md)

**Input**: Feature specification from `specs/006-fix-cost-pipeline/spec.md` with Clarification on INE index dataset persistence.

## Summary

Remediate data extraction, clinical standardization, taxonomy inference, HEOR inflation modeling, offline-first INE index persistence, and orchestration in the ground-source healthcare cost extraction pipeline for Spain (`scripts/scrape_costs_es.py`, `dags/cost_extraction_dag.py`, and `data/specs/registries.yml`). The updated pipeline eliminates character encoding corruption, joins multi-line PDF descriptions, purges non-sanitary gazette noise, enforces strict clinical code grammars (fixing `ICD-10-PCS` and Balearic `APR-GRD` parsing), rebalances setting/OMOP domain classification (reducing outpatient bias from ~85% to <35%), parses and exports official INE Healthcare CPI series (ECOICOP 06 Sanidad, 06.2, 06.3) to `data/ine_indices_sanidad.*`, and synchronizes Airflow XCom tasks.

## Technical Context

**Language/Version**: Python 3.10+ / Python 3.14 (dedicated `.venv`)

**Primary Dependencies**: `pandas`, `pyarrow`, `pypdfium2`, `openpyxl`, `beautifulsoup4`, `requests`, `pyyaml`, `apache-airflow` (3.x standard provider)

**Storage**: 
- Canonical cost catalogs: `data/costs_spain.csv`, `data/costs_spain.parquet` (Snappy), `data/costs_spain.json`
- Canonical INE index tables: `data/ine_indices_sanidad.csv`, `data/ine_indices_sanidad.parquet`, `data/ine_indices_sanidad.json`
- Ground source registry: `data/specs/registries.yml`
- Raw cache: `data/raw/*`

**Testing**: Python test suite with unit tests in `tests/test_scrape_costs_es.py` and pipeline validation assertions.

**Target Platform**: macOS / Linux Airflow ETL Worker & CLI execution

**Project Type**: Data Pipeline / HEOR Ground-Source Tariff Catalog Extractor

**Performance Goals**: 
- Complete multi-format extraction, normalization, deflation, and export across all 22 sources in <45 seconds.
- 0 nulls across mandatory columns; 100% unique `cost_id`s; 100% valid INE series records.

**Constraints**: 
- Must adhere strictly to official gazette content (no synthetic or invented tariff numbers).
- Multi-format ingestion (PDF, HTML, Excel Casemix, API JSON).
- Standardized prefixes: `APR-GRD:`, `ICD-9-CM:`, `ICD-10-PCS:`, `CN:`, `SAP:`, `REGIONAL:`.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] **I. Zero Wheel-Reinvention**: Uses `pypdfium2` text stream processing, `BeautifulSoup4` for HTML, `openpyxl` for Casemix workbooks, `pandas`/`pyarrow` for data export, and standard Airflow operators.
- [x] **II. Standardized OMOP CDM & COST Integration**: Produces reference catalogs directly aligned with OMOP CDM domains (`Visit`, `Procedure`, `Measurement`, `Drug`) and HEOR unit cost structures.
- [x] **III. Pipeable & Modular Architecture**: Modular pure functions (`fetch_ine_deflators()`, `export_ine_tables()`, `extract_pdf_catalog()`, `extract_html_catalog()`, `extract_grd_excel()`, `format_code_std()`, `infer_setting()`, `infer_omop_domain()`, `infer_unit_type()`, `run_pipeline()`).
- [x] **IV. Test-First & Coverage**: Accompanied by automated unit tests validating parsing, encoding, code validation, deflator computation, and index file persistence.
- [x] **V. 6-Stage Pipeline Alignment**: Directly powers Stage 2 (HCRU Characterization) and Stage 4 (State-Cost Extraction) by providing accurate unit costs and deflator series for OMOP cost mapping.

## Project Structure

### Documentation (this feature)

```text
specs/006-fix-cost-pipeline/
├── spec.md              # Feature specification with clarifications
├── plan.md              # This implementation plan
├── research.md          # Technical research & design decisions
├── data-model.md        # Entities, schemas, validation rules, and taxonomy mapping
├── quickstart.md        # Verification guide & execution commands
├── contracts/
│   └── cost-pipeline-contracts.md  # Schema contracts and code grammar specifications
└── checklists/
    └── requirements.md  # Specification quality checklist
```

### Source Code (repository root)

```text
scripts/
└── scrape_costs_es.py   # Ground-source extraction, parsing, normalization, deflation & INE exporter

dags/
└── cost_extraction_dag.py  # Airflow DAG orchestrating ETL pipeline tasks

data/
├── specs/
│   └── registries.yml   # Metadata registry for 22 ground-source gazettes
├── raw/                 # Ingested raw gazettes (PDF, HTML, XLSX, JSON)
├── costs_spain.csv      # Canonical catalog (CSV)
├── costs_spain.parquet  # Canonical catalog (Snappy Parquet)
├── costs_spain.json     # Canonical catalog (JSON)
├── ine_indices_sanidad.csv      # Canonical INE index series (CSV)
├── ine_indices_sanidad.parquet  # Canonical INE index series (Parquet)
└── ine_indices_sanidad.json     # Canonical INE index series (JSON)

tests/
└── test_scrape_costs_es.py  # Automated test suite for parser and normalizer
```

## Complexity Tracking

*No constitutional violations. Remediation simplifies and stabilizes existing parsing logic and adds structured index persistence.*
