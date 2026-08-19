# Task List: Decouple Cost Ingestion & Modernize Airflow Pipeline

**Feature Branch**: `007-split-cost-pipeline` | **Date**: Wed Aug 19 2026 | **Spec**: [specs/007-split-cost-pipeline/spec.md](spec.md) | **Plan**: [specs/007-split-cost-pipeline/plan.md](plan.md)

---

## Tasks

### Phase 1: Setup
- [x] T001 Verify virtual environment and python dependencies in requirements.txt

### Phase 2: Foundational
- [x] T002 [P] Create baseline directory structure and cache checks in data/raw/

### Phase 3: User Story 2 - Dedicated Ingestion Script (Priority: P1)
**Goal**: Isolate all network operations, SSL workarounds, gazette downloads, and INE CPI persistence into a dedicated CLI script.
- [x] T003 [P] [US2] Implement SSL context, headers, and download_source in scripts/download_costs_sources.py
- [x] T004 [P] [US2] Implement fetch_ine_deflators and export_ine_tables in scripts/download_costs_sources.py
- [x] T005 [US2] Implement download_all_sources and CLI interface with --source-id, --ccaa, and --force in scripts/download_costs_sources.py

### Phase 4: User Story 1 - 100% Offline Scraper Execution & Rapid Heuristic Refinement (Priority: P1)
**Goal**: Make scraping, regex parsing, clinical taxonomy inference, and catalog generation 100% offline from local raw cache.
- [x] T006 [P] [US1] Refactor scripts/scrape_costs_es.py to remove network calls and load files 100% offline from data/raw/
- [x] T007 [P] [US1] Implement single-source and CCAA filtering (--source-id, --ccaa, --limit-preview) in scripts/scrape_costs_es.py
- [x] T008 [US1] Implement graceful missing file diagnostics directing users to download_costs_sources.py in scripts/scrape_costs_es.py
- [x] T009 [US1] Add consolidate_and_export helper for modular dataset compilation in scripts/scrape_costs_es.py

### Phase 5: User Story 3 - Airflow TaskFlow & Dynamic Task Mapping Orchestration (Priority: P2)
**Goal**: Modernize Airflow DAG with TaskFlow decorators, dynamic task mapping, deferred imports, and dataset outlets.
- [x] T010 [US3] Refactor dags/cost_extraction_dag.py to modern TaskFlow API (@dag, @task)
- [x] T011 [US3] Implement dynamic task mapping (.expand()) for parallel downloads and extractions in dags/cost_extraction_dag.py
- [x] T012 [US3] Add Airflow Dataset outlet for data/costs_spain.parquet and deferred task imports in dags/cost_extraction_dag.py
- [x] T013 [US3] Retain local execution entrypoint in dags/cost_extraction_dag.py

### Phase 6: User Story 4 - Backward Compatibility & Test Suite Integrity (Priority: P1)
**Goal**: Preserve 100% test compatibility and maintain invariant checks across modules.
- [x] T014 [US4] Re-export shared symbols (DEFAULT_SANIDAD_INDICES, TARGET_YEAR, fetch_ine_deflators, export_ine_tables) in scripts/scrape_costs_es.py for backward compatibility
- [x] T015 [US4] Update tests/test_scrape_costs_es.py to verify both standalone CLI modules and offline scraping performance

### Phase 7: Polish & End-to-End Validation
- [x] T016 Execute full offline catalog build with python scripts/scrape_costs_es.py and verify data/costs_spain.* artifacts
- [x] T017 Execute test suite with python -m unittest tests/test_scrape_costs_es.py
- [x] T018 Execute Airflow DAG locally with python dags/cost_extraction_dag.py

---

## Dependencies & Completion Order

```text
Setup (T001, T002)
   ↓
US2: Ingestion Module (T003 -> T004 -> T005)
   ↓
US1: Offline Scraper (T006 -> T007 -> T008 -> T009)
   ↓
US4: Compatibility & Tests (T014 -> T015)
   ↓
US3: Airflow Modernization (T010 -> T011 -> T012 -> T013)
   ↓
Polish & Verification (T016, T017, T018)
```
