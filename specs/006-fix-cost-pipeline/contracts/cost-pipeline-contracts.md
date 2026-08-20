# Interface Contracts: Spanish Healthcare Cost Extraction Engine

**Feature Branch**: `006-fix-cost-pipeline` | **Date**: Wed Aug 19 2026 | **Spec**: [specs/006-fix-cost-pipeline/spec.md](spec.md)

## 1. Python Extraction Engine API (`scripts/scrape_costs_es.py`)

### A. `fetch_ine_deflators(cache_dir: str = "data/raw") -> Dict[int, float]`
* **Description**: Fetches official Healthcare CPI series (ECOICOP 06 Sanidad) from INE Table 50913 with verified historical fallback values.
* **Returns**: Dictionary mapping integer years (`2002` through `2026`) to index floats (e.g. `{2013: 97.12, 2021: 100.0, 2026: 109.43}`).
* **Error Behavior**: Logs warning and returns base verified series if network fails.

### B. `export_ine_tables(output_dir: str = "data") -> pd.DataFrame`
* **Description**: Parses all ECOICOP 06 sub-series (06 Sanidad, 06.1 Productos farmacéuticos, 06.2 Servicios ambulatorios, 06.3 Servicios hospitalarios) and exports structured datasets:
  - `data/ine_indices_sanidad.csv`
  - `data/ine_indices_sanidad.parquet`
  - `data/ine_indices_sanidad.json`
* **Returns**: DataFrame containing annual index series and 2026 escalation factors.

### C. `format_code_std(raw_code: Any, context: str = "") -> str`
* **Description**: Standardizes raw procedure/tariff codes to canonical prefixed notation.
* **Input**: `raw_code` (string/number), `context` (description string).
* **Validation Grammar**:
  - `APR-GRD:<grd>[-<sev>]` (rejects decimal weights)
  - `ICD-9-CM:<xx.xx>`
  - `ICD-10-PCS:<7-char authentic PCS>` (rejects Spanish words `DRENAJE`, `ESCUELA`, `VENDAJE`, `PRUEBAS`)
  - `CN:<6-digit>`
  - `SAP:<7-digit>`
  - `REGIONAL:<authentic regional code>` (rejects section titles `B1`, `B2`, `DOG`)
* **Returns**: Standardized string or empty string `""`.

### D. `infer_setting(desc: str, code_std: str = "") -> str`
* **Description**: Infers clinical operational setting based on code prefix and expanded clinical taxonomy keywords.
* **Precedence Rule**: If `code_std.startswith("APR-GRD:")`, returns `"Inpatient"` (unless `CMA` in description -> `"Procedures"`).
* **Returns**: One of: `"Inpatient"`, `"ICU"`, `"Outpatient"`, `"Emergency"`, `"Diagnostics"`, `"Procedures"`, `"Primary Care"`.

### E. `infer_omop_domain(setting: str) -> str`
* **Description**: Maps clinical setting to OMOP CDM domain.
* **Mapping**:
  - `Inpatient`, `ICU`, `Outpatient`, `Emergency`, `Primary Care` -> `"Visit"`
  - `Diagnostics` -> `"Measurement"`
  - `Procedures` -> `"Procedure"`
  - `Pharmacy` -> `"Drug"`
* **Returns**: Standard OMOP domain string.

### F. `infer_unit_type(setting: str, desc: str) -> str`
* **Description**: Assigns appropriate HEOR unit metric.
* **Returns**: `"per_episode"`, `"per_diem"`, `"per_visit"`, `"per_procedure"`, `"per_test"`, or `"per_session"`.

### G. `run_pipeline(...) -> Tuple[pd.DataFrame, pd.DataFrame]`
* **Parameters**:
  - `registry_path: str = "data/specs/registries.yml"`
  - `output_csv: str = "data/costs_spain.csv"`
  - `output_parquet: str = "data/costs_spain.parquet"`
  - `output_json: str = "data/costs_spain.json"`
  - `download_fresh: bool = False`
  - `deflators: Optional[Dict[int, float]] = None`
* **Output**: Tuple of `(df_costs, df_ine)` validated DataFrames.
* **Invariants**: 
  - `cost_id` is unique.
  - 0 nulls across mandatory columns.
  - Files exported to CSV, Parquet, and JSON for both costs and INE index series.

---

## 2. Airflow 3.x DAG Contract (`dags/cost_extraction_dag.py`)

### DAG Definition
* **DAG ID**: `hermes_cost_catalogs_etl`
* **Schedule**: `@monthly`
* **Catchup**: `False`

### Task Dependency & XCom Data Flow
```text
[ingest_raw_registries] ──> [compute_ine_deflators] ──> [extract_normalize_validate_export]
                                     │                                  ▲
                                     └──────────(XCom: deflators)───────┘
```

1. **Task 1: `ingest_raw_registries`**:
   - Ingests/refreshes 22 ground-source gazettes into `data/raw/`.
   - Returns number of verified sources.
2. **Task 2: `compute_ine_deflators`**:
   - Queries INE Sanidad API series (ECOICOP 06).
   - Exports canonical INE index tables to `data/ine_indices_sanidad.*`.
   - Pushes deflator dictionary to Airflow XCom.
3. **Task 3: `extract_normalize_validate_export`**:
   - Pulls `deflators` from Task 2 XCom.
   - Executes multi-format extraction and normalization.
   - Exports CSV, Parquet, and JSON canonical catalogs.

---

## 3. CLI Command Contract

```bash
# Execute standalone extraction and index export pipeline
python scripts/scrape_costs_es.py \
  --registry data/specs/registries.yml \
  --output-csv data/costs_spain.csv \
  --output-parquet data/costs_spain.parquet \
  --output-json data/costs_spain.json

# Execute Airflow DAG locally
python dags/cost_extraction_dag.py
```
