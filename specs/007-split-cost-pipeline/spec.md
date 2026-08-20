# Feature Specification: Decouple Cost Ingestion & Modernize Airflow Pipeline

**Feature Branch**: `007-split-cost-pipeline`  
**Created**: Wed Aug 19 2026  
**Status**: Draft  
**Input**: "refactor the code" (Split cost data downloading and scraping into separate scripts for offline scraping refinement, and modernize Airflow pipeline implementation).

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - 100% Offline Scraper Execution & Rapid Heuristic Refinement (Priority: P1)

As an HEOR data engineer and researcher refining gazette parsing regexes and table decoders, I need the scraping and normalization script to operate strictly on locally cached raw files without making any network requests, so that I can refine extraction rules, fix table parsing bugs, and test individual regional sources in sub-second feedback loops.

**Why this priority**: Network downloads of 22 large gazettes and casemix workbooks take time, risk rate-limits or temporary SSL/domain outages, and introduce latency when iterating on parser code. Decoupling extraction ensures development and debugging are fast, offline, and deterministic.

**Independent Test**: Execute the scraper with local raw files present; confirm that no outgoing network connections are initiated, that `--source-id` or `--ccaa` flags allow targeted single-source extraction in < 1 second, and that all catalog artifacts (`data/costs_spain.*`) are generated identically to baseline.

**Acceptance Scenarios**:

1. **Given** raw source files existing in `data/raw/`, **When** `scrape_costs_es.py` is invoked with `--source-id <id>`, **Then** only that specific source is parsed and printed/saved without triggering any network calls.
2. **Given** missing raw files in `data/raw/`, **When** `scrape_costs_es.py` encounters a missing source, **Then** it issues a clear diagnostic warning directing the user to run the downloader script rather than hanging or silently failing.
3. **Given** all raw files cached in `data/raw/`, **When** the full offline pipeline executes, **Then** full catalog generation produces 100% valid records across CSV, Parquet, and JSON formats satisfying all data quality invariants.

---

### User Story 2 - Dedicated Ingestion Script for Ground Sources & Inflation Series (Priority: P1)

As a data engineer, I need a dedicated, standalone ingestion script (`scripts/download_costs_sources.py`) that downloads gazette PDFs, Excel spreadsheets, HTML pages, and official INE CPI series into `data/raw/`, with robust SSL handling, size validation, and selective re-download flags (`--source-id`, `--force`).

**Why this priority**: Ingestion has unique operational concerns (HTTP headers, legacy government SSL bypass, retry backoff, endpoint URL changes) that should not be entangled with text processing, regex parsing, and HEOR clinical classification logic.

**Independent Test**: Run `download_costs_sources.py` against individual source IDs or the full registry; verify that files are saved to `data/raw/` with verified non-zero sizes and valid file types, and that `--force` correctly overrides cached files.

**Acceptance Scenarios**:

1. **Given** a valid registry specification in `data/specs/registries.yml`, **When** `download_costs_sources.py` runs with `--source-id <id>`, **Then** only that specific file is fetched from its remote URL and verified in `data/raw/`.
2. **Given** existing valid files in `data/raw/`, **When** `download_costs_sources.py` runs without `--force`, **Then** existing valid cached files are preserved without redundant network requests.
3. **Given** official INE CPI endpoints, **When** deflator ingestion executes, **Then** the raw JSON response is cached and canonical index tables are generated in `data/ine_indices_sanidad.*`.

---

### User Story 3 - Airflow TaskFlow & Dynamic Task Mapping Orchestration (Priority: P2)

As an MLOps and pipeline engineer, I need the Airflow DAG (`dags/cost_extraction_dag.py`) refactored to modern Airflow 2+ standards using the TaskFlow API (`@dag`, `@task`), Dynamic Task Mapping (`.expand()`), lightweight scheduler parsing, and Airflow `Dataset` outlets.

**Why this priority**: Monolithic loops in a single task create a single point of failure (if 1 of 22 regional downloads fails, the entire task aborts). Dynamic task mapping allows parallel extraction, independent task retries per CCAA, and event-driven downstream pipeline triggers.

**Independent Test**: Load and execute the Airflow DAG; verify that DAG definition parses without top-level heavy import overhead, tasks map dynamically across sources, failures in one source do not block others, and task outputs trigger dataset outlets.

**Acceptance Scenarios**:

1. **Given** the Airflow DAG file, **When** parsed by the Airflow Scheduler, **Then** no heavy text/PDF processing libraries are imported at the top level, keeping DAG parse time minimal.
2. **Given** 22 registered regional ground sources, **When** the ingestion task executes, **Then** tasks map dynamically to download/verify sources in parallel with independent retry configurations.
3. **Given** successful catalog compilation, **When** the export task finishes, **Then** an Airflow `Dataset` outlet is emitted to notify downstream analytical or OMOP pipelines.

---

### User Story 4 - Full Backward Compatibility & Test Suite Integrity (Priority: P1)

As a package maintainer, I need all existing unit and integration tests in `tests/test_scrape_costs_es.py` and downstream R/Python workflows to continue operating seamlessly without breaking API changes.

**Why this priority**: Refactoring must improve developer ergonomics and architecture without causing regressions in catalog outputs or test assertions.

**Independent Test**: Run `python -m unittest tests/test_scrape_costs_es.py` and verify all tests pass with zero failures.

**Acceptance Scenarios**:

1. **Given** existing test suites, **When** unit tests execute, **Then** all parser functions (`format_code_std`, `infer_setting`, `infer_omop_domain`, `is_noise_text`, `read_text_file`) pass their assertions.
2. **Given** the refactored modules, **When** shared constants or functions are imported, **Then** aliases or backward-compatible imports prevent broken dependencies.

---

## Edge Cases

- **Missing local files during offline scraping**: When a user runs the scraper but one or more raw files are missing from `data/raw/`, the system MUST log a clear message identifying the missing source and giving the exact command to download it.
- **Corrupted or empty download**: The downloader MUST check downloaded file size (> 200 bytes) and valid HTTP status before marking a download as successful.
- **Airflow runtime without mapped tasks support**: Fallback sequential execution helper MUST remain available for local CLI debugging (`python dags/cost_extraction_dag.py`).

---

## Requirements

### Functional Requirements

- **FR-001**: Ingestion logic (`download_source`, `fetch_ine_deflators`, `export_ine_tables`, `SSL_CTX`, `HEADERS`) MUST be extracted to `scripts/download_costs_sources.py`.
- **FR-002**: `scripts/download_costs_sources.py` MUST provide a CLI with `--registry`, `--raw-dir`, `--source-id`, `--ccaa`, and `--force` flags.
- **FR-003**: `scripts/scrape_costs_es.py` MUST operate 100% offline, loading files exclusively from `data/raw/` and using cached/default INE deflators.
- **FR-004**: `scripts/scrape_costs_es.py` MUST provide CLI flags `--source-id`, `--ccaa`, `--raw-dir`, `--output-csv`, `--output-parquet`, and `--output-json`.
- **FR-005**: `dags/cost_extraction_dag.py` MUST be refactored to use the Airflow TaskFlow API (`@dag`, `@task`) with dynamic task mapping (`.expand()`) where appropriate and deferred task-level imports.
- **FR-006**: All existing unit tests in `tests/test_scrape_costs_es.py` MUST pass and maintain verification of data quality invariants (zero nulls, unique `cost_id`, correct code formatting, setting rebalancing).

### Key Technical Entities & Contracts

- **Downloader Module**: `scripts/download_costs_sources.py`
  - Function: `download_source(src: dict, raw_dir: str = "data/raw", force: bool = False) -> str`
  - Function: `download_all_sources(registry_path: str = "data/specs/registries.yml", raw_dir: str = "data/raw", force: bool = False, source_id: Optional[str] = None) -> list[str]`
  - Function: `fetch_ine_deflators(cache_path: str = "data/raw/ine-ipc-medicina.json", force: bool = False) -> dict[int, float]`
- **Scraper / Normalizer Module**: `scripts/scrape_costs_es.py`
  - Function: `extract_source_records(src: dict, filepath: str, deflators: dict) -> list[CostRecord]`
  - Function: `consolidate_and_export(all_records: list[CostRecord], output_csv: str, output_parquet: str, output_json: str) -> pd.DataFrame`
  - Function: `run_pipeline(...) -> tuple[pd.DataFrame, pd.DataFrame]`
- **Airflow DAG**: `dags/cost_extraction_dag.py`
  - DAG ID: `hermes_cost_catalogs_etl`
  - Pattern: `@dag` + `@task` with dynamic mapping and dataset outlet.

---

## Success Criteria

- **Measurable Refinement Speed**: Individual source scraping and inspection executes in under 1 second via CLI (`--source-id`).
- **Complete Ingestion Decoupling**: Zero network requests are made during `scrape_costs_es.py` execution.
- **Pipeline Reliability**: 100% of unit and integration tests pass without regression.
- **Airflow Native Design**: Scheduler parse time reduced, DAG uses native TaskFlow idioms, and sources can be processed in parallel.
