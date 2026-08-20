# Task List: Spanish Ground-Source Healthcare Cost Pipeline Remediation

**Feature Branch**: `006-fix-cost-pipeline` | **Date**: Wed Aug 19 2026 | **Spec**: [specs/006-fix-cost-pipeline/spec.md](spec.md) | **Plan**: [specs/006-fix-cost-pipeline/plan.md](plan.md)

## Tasks

### Phase 1: Ingestion, Multi-Encoding & Noise Filtering
- [x] **T-001**: Implement `read_text_file` with dynamic multi-encoding fallback (`utf-8` -> `iso-8859-1` -> `windows-1252`) in `scripts/scrape_costs_es.py`.
- [x] **T-002**: Implement 2-line sliding text stream buffer in `extract_pdf_catalog` to join wrapped multi-line procedure descriptions.
- [x] **T-003**: Implement `is_noise_text` negative filtering to purge gazette headers, footers, publication dates, decree titles, page numbers, and non-sanitary tax rate brackets.
- [x] **T-004**: Synchronize `data/specs/registries.yml` metadata with valid file format declarations (`sns-2024-siap` -> `pdf`, `ine-ipc-medicina` -> `json`).

### Phase 2: Code Standardization & Layout Precedence
- [x] **T-005**: Reorder HTML table parsing precedence in `extract_html_catalog` so specific 6-column Balearic tables (`[GRD, Severity, Weight, Description, Price, SAP]`) take precedence over generic 5-column formats.
- [x] **T-006**: Refactor `format_code_std` with strict grammar validation for `APR-GRD`, `ICD-9-CM`, `ICD-10-PCS`, `SAP`, `CN`, and `REGIONAL` prefixes.
- [x] **T-007**: Eliminate false-positive `ICD-10-PCS` classifications for Spanish dictionary words and regional alphanumeric codes.

### Phase 3: Clinical Taxonomy & OMOP Domain Rebalancing
- [x] **T-008**: Update `infer_setting` to default `APR-GRD` casemix categories to `Inpatient` and `per_episode` (or `Procedures` if marked as `CMA`).
- [x] **T-009**: Expand clinical keyword mappings for `Diagnostics` (`Measurement` / `per_test`), `Procedures` (`Procedure` / `per_procedure`), and `Primary Care` (`Visit` / `per_visit`).
- [x] **T-010**: Align `infer_omop_domain` and `infer_unit_type` across all 7 operational healthcare settings.

### Phase 4: HEOR Deflation & Canonical Dataset Persistence
- [x] **T-011**: Refactor `fetch_ine_deflators` in `scripts/scrape_costs_es.py` to strictly query ECOICOP 06 Sanidad (Target 2026 Index = 109.43, Base 2021 = 100.0, 2024 = 105.09) and reject General CPI.
- [x] **T-012**: Implement `export_ine_tables` to parse and persist canonical INE index datasets in `data/ine_indices_sanidad.csv`, `data/ine_indices_sanidad.parquet`, and `data/ine_indices_sanidad.json`.
- [x] **T-013**: Apply exact year-specific deflation factors across all historical source years (2013–2024).

### Phase 5: Airflow 3.x DAG Orchestration & Test Verification
- [x] **T-014**: Update `dags/cost_extraction_dag.py` so Task 2 exports INE index tables and pushes `deflators` dict to XCom, and Task 3 pulls deflators from XCom.
- [x] **T-015**: Write comprehensive automated unit and integration tests in `tests/test_scrape_costs_es.py`.
- [x] **T-016**: Execute local test suite (`python -m unittest tests/test_scrape_costs_es.py`) and Airflow DAG local execution (`python dags/cost_extraction_dag.py`).
