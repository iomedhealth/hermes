# Interface Contracts: Spanish Cost Extraction & Ingestion Pipeline

**Feature**: Decouple Cost Ingestion & Modernize Airflow Pipeline  
**Date**: Wed Aug 19 2026

---

## 1. CLI Contracts

### `scripts/download_costs_sources.py`
```text
usage: download_costs_sources.py [-h] [--registry REGISTRY] [--raw-dir RAW_DIR]
                                 [--source-id SOURCE_ID] [--ccaa CCAA] [--force]
                                 [--skip-ine]

Download raw healthcare tariff gazettes, workbooks, HTML tables, and INE CPI deflators.

optional arguments:
  -h, --help            show this help message and exit
  --registry REGISTRY   Path to registries.yml (default: data/specs/registries.yml)
  --raw-dir RAW_DIR     Path to raw cache directory (default: data/raw)
  --source-id SOURCE_ID Specific source ID to download (e.g. and-2024-precios)
  --ccaa CCAA           Filter downloads by CCAA (e.g. Andalucía)
  --force               Force re-download even if file already exists locally
  --skip-ine            Skip INE CPI deflator fetch and export
```

### `scripts/scrape_costs_es.py`
```text
usage: scrape_costs_es.py [-h] [--registry REGISTRY] [--raw-dir RAW_DIR]
                          [--source-id SOURCE_ID] [--ccaa CCAA]
                          [--output-csv OUTPUT_CSV] [--output-parquet OUTPUT_PARQUET]
                          [--output-json OUTPUT_JSON] [--limit-preview LIMIT_PREVIEW]

Extract, standardize, inflate, validate, and export healthcare cost catalogs 100% offline.

optional arguments:
  -h, --help            show this help message and exit
  --registry REGISTRY   Path to registries.yml (default: data/specs/registries.yml)
  --raw-dir RAW_DIR     Path to raw cache directory (default: data/raw)
  --source-id SOURCE_ID Specific source ID to extract (e.g. and-2024-precios)
  --ccaa CCAA           Filter extraction by CCAA (e.g. Andalucía)
  --output-csv OUTPUT_CSV
                        Destination CSV catalog (default: data/costs_spain.csv)
  --output-parquet OUTPUT_PARQUET
                        Destination Parquet catalog (default: data/costs_spain.parquet)
  --output-json OUTPUT_JSON
                        Destination JSON catalog (default: data/costs_spain.json)
  --limit-preview LIMIT_PREVIEW
                        Print preview of N records without overwriting canonical catalogs
```

---

## 2. Python API Contracts

### `scripts/download_costs_sources.py`
```python
def download_source(src: Dict[str, Any], raw_dir: str = "data/raw", force: bool = False) -> str:
    """Download a single ground-source from remote URL and save to raw_dir/<id>.<fmt>."""
    ...

def download_all_sources(
    registry_path: str = "data/specs/registries.yml",
    raw_dir: str = "data/raw",
    force: bool = False,
    source_id: Optional[str] = None,
    ccaa: Optional[str] = None,
) -> List[str]:
    """Download all (or filtered) registered ground sources."""
    ...

def fetch_ine_deflators(
    cache_path: str = "data/raw/ine-ipc-medicina.json",
    force: bool = False,
) -> Dict[int, float]:
    """Query official INE REST API or load cached JSON series."""
    ...

def export_ine_tables(
    output_dir: str = "data",
    raw_path: str = "data/raw/ine-ipc-medicina.json",
) -> pd.DataFrame:
    """Export canonical INE index datasets (CSV, Parquet, JSON)."""
    ...
```

### `scripts/scrape_costs_es.py`
```python
def extract_source_records(
    src: Dict[str, Any],
    filepath: str,
    deflators: Optional[Dict[int, float]] = None,
) -> List[CostRecord]:
    """Extract and standardize records from a single local file (PDF, XLSX, HTML)."""
    ...

def consolidate_and_export(
    records: List[CostRecord],
    output_csv: str = "data/costs_spain.csv",
    output_parquet: str = "data/costs_spain.parquet",
    output_json: str = "data/costs_spain.json",
) -> pd.DataFrame:
    """Deduplicate, assign sequential cost_ids, validate quality invariants, and write catalog artifacts."""
    ...

def run_pipeline(
    registry_path: str = "data/specs/registries.yml",
    raw_dir: str = "data/raw",
    output_csv: str = "data/costs_spain.csv",
    output_parquet: str = "data/costs_spain.parquet",
    output_json: str = "data/costs_spain.json",
    source_id: Optional[str] = None,
    ccaa: Optional[str] = None,
    deflators: Optional[Dict[int, float]] = None,
) -> Tuple[pd.DataFrame, pd.DataFrame]:
    """Execute complete 100% offline extraction, validation, and catalog compilation."""
    ...
```
