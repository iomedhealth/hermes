# Implementation Plan: HCRU Domain Extraction and Financial Linkage

**Branch**: `005-hcru-domain-extraction` | **Date**: Fri Aug 14 2026 | **Spec**: [specs/005-hcru-domain-extraction/spec.md](spec.md)

**Input**: Feature specification from `specs/005-hcru-domain-extraction/spec.md`

## Summary

Enhance `extract_hcru()` to join patient cohort members (target, comparator, and outcome cohorts), enforce configurable baseline (`[-365, -1]`) and follow-up (`[0, 365]`) temporal windows, extract 5 core HEOR utilization domains via database-side `dbplyr` queries (Inpatient/ICU with LOS and readmissions, Outpatient/Emergency stratified by GP/Specialist/ED, Pharmacotherapy with fills and days supply, Diagnostics/Procedures, and Post-Acute SNF/Hospice), link domain events directly to the OMOP `cost` table, and return an enriched flat `hermes_hcru` S3 object.

## Technical Context

**Language/Version**: R (>= 4.1.0)

**Primary Dependencies**: `omopgenerics`, `CDMConnector`, `dbplyr`, `dplyr`, `tibble`, `rlang`, `CohortCharacteristics`, `PatientProfiles`, `CohortMethod`, `Cyclops`, `hesim`, `BCEA`

**Storage**: OMOP CDM v5.3+ via DBI / dbplyr (DuckDB / Eunomia for tests, PostgreSQL / SQL Server / Oracle for production)

**Testing**: `testthat` (3.0.0+) with Eunomia synthetic test database and mock CDM fixtures

**Target Platform**: Cross-platform (macOS, Linux, Windows) R package

**Project Type**: R analytical package / HEOR pipeline library

**Performance Goals**: 100% database-side filtering, joining, and aggregation via `dbplyr` before collection; sub-second execution on standard synthetic cohorts; scalable to cohorts with 100k+ patients

**Constraints**: Read-only queries against OMOP CDM tables; base R pipe `|>`; `<-` assignment; strict S3 class hierarchy (`c("hermes_hcru", "hermes_study", "list")`); no silent mock fallbacks

**Scale/Scope**: 5 core clinical utilization domains, financial cost linkage, temporal windowing across target/comparator/outcome cohorts

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] **I. Zero Wheel-Reinvention**: Leverages `dbplyr`, `dplyr`, `CDMConnector`, and `omopgenerics` for database queries and cohort handling rather than custom SQL engines.
- [x] **II. Standardized OMOP CDM & COST Integration**: Queries OMOP CDM v5.3+ tables (`visit_occurrence`, `provider`, `drug_exposure`, `procedure_occurrence`, `measurement`, `cost`) without modifying core tables.
- [x] **III. Pipeable S3 Architecture**: Uses base R pipe `|>`, `<-` assignment, `snake_case`, and returns flat `hermes_hcru` S3 class constructed via `new_hermes_hcru()`.
- [x] **IV. Test-First & Coverage**: Accompanied by unit tests in `tests/testthat/test-stage2-hcru.R` and full verification in `tests/testthat/test-e2e.R`.
- [x] **V. 6-Stage Pipeline Alignment**: Directly enhances Stage 2 (Descriptive Baseline & HCRU Characterization) and feeds into Stage 3 (PS Adjustment) and Stage 4 (Trajectories & State-Cost Extraction).

## Project Structure

### Documentation (this feature)

```text
specs/005-hcru-domain-extraction/
├── spec.md              # Feature specification
├── plan.md              # This implementation plan
├── research.md          # Technical research & design decisions
├── data-model.md        # Entities, schemas, relationships, and validation rules
├── quickstart.md        # Usage examples and code walkthrough
├── contracts/
│   └── extract-hcru-api.md  # API signature and return schemas
└── checklists/
    └── requirements.md  # Specification quality checklist
```

### Source Code (repository root)

```text
R/
├── init.R               # Stage 1: init() study constructor
├── baseline.R           # Stage 2: summarise_baseline()
├── hcru.R               # Stage 2: extract_hcru() core domain & cost extraction
├── ps.R                 # Stage 3: fit_ps(), adjust_ps(), assess_balance()
├── trajectories.R       # Stage 4: compile_trajectories()
├── simulation.R         # Stage 5: simulate_economics()
├── cea.R                # Stage 6: run_cea(), plot_ceac(), plot_plane()
└── s3_classes.R         # S3 constructors (new_hermes_hcru, etc.)

tests/testthat/
├── helper-eunomia.R     # Test CDM creation and fixtures
├── helper-stage2.R      # Stage 2 mock data generators
├── test-stage2-hcru.R   # Stage 2 unit tests
└── test-e2e.R           # End-to-end 6-stage pipeline integration test
```

**Structure Decision**: Standard R package directory layout with logic in `R/` and tests in `tests/testthat/`. Enhancements will be focused in `R/hcru.R`, supported by updated tests in `tests/testthat/test-stage2-hcru.R` and `tests/testthat/test-e2e.R`.

## Complexity Tracking

*No constitutional violations. Design strictly adheres to standard HERMES principles.*
