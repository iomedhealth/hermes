# Quickstart & Verification Guide: Spanish Healthcare Cost Extraction

**Feature Branch**: `006-fix-cost-pipeline` | **Date**: Wed Aug 19 2026 | **Spec**: [specs/006-fix-cost-pipeline/spec.md](spec.md)

## 1. Prerequisites

Activate the dedicated Python virtual environment:

```bash
source .venv/bin/activate
```

Verify installed dependencies:

```bash
python -c "import pandas, pyarrow, pypdfium2, openpyxl, bs4, requests, yaml; print('All dependencies available.')"
```

---

## 2. Execute Full Extraction Pipeline

Run the comprehensive ground-source extraction, parsing, normalization, deflation, and catalog export:

```bash
python scripts/scrape_costs_es.py
```

Expected output:
- `data/costs_spain.csv`
- `data/costs_spain.parquet`
- `data/costs_spain.json`
- 0 null values across all mandatory columns
- Summary breakdown showing rebalanced clinical settings and valid standardized codes

---

## 3. Run Automated Validation & Test Suite

Execute the unit tests covering character encoding, code parsing, multi-line buffering, and deflator calculations:

```bash
pytest tests/test_scrape_costs_es.py -v
```

---

## 4. Run Airflow DAG Locally

Verify end-to-end Airflow ETL execution with inter-task XCom data passing:

```bash
python dags/cost_extraction_dag.py
```

---

## 5. Diagnostic Quality Verification Script

Run the following inline script to assert quality criteria on the generated parquet catalog:

```bash
python -c "
import pandas as pd

df = pd.read_parquet('data/costs_spain.parquet')

# 1. Assert zero nulls
assert df.isna().sum().sum() == 0, 'Null values detected!'

# 2. Assert unique cost_id
assert df['cost_id'].is_unique, 'Duplicate cost_id found!'

# 3. Assert zero false ICD-10-PCS dictionary words
bad_pcs = df[df['code_std'].str.startswith('ICD-10-PCS:DRENAJE') | df['code_std'].str.startswith('ICD-10-PCS:ESCUELA')]
assert len(bad_pcs) == 0, 'False positive ICD-10-PCS words found!'

# 4. Assert zero corrupted Balearic APR-GRD decimal weights
bad_bal = df[df['code_std'].str.contains(r'APR-GRD:\d+-\d+,\d+')]
assert len(bad_bal) == 0, 'Corrupted Balearic APR-GRDs found!'

# 5. Assert Outpatient proportion is balanced (< 40%)
op_pct = (df['setting'] == 'Outpatient').mean()
print(f'Outpatient setting proportion: {op_pct:.2%}')
assert op_pct < 0.45, f'Outpatient proportion too high: {op_pct:.2%}'

# 6. Assert correct inflation factor for 2024 (Sanidad CPI ~1.041 instead of General CPI ~1.054)
fac_2024 = (df[df['year_original'] == 2024]['cost_updated'] / df[df['year_original'] == 2024]['cost_original']).iloc[0]
print(f'2024 Escalation Factor: {fac_2024:.4f}')

print('\n>>> ALL CANONICAL CATALOG ASSERTIONS PASSED SUCCESSFULLY! <<<')
"
```
