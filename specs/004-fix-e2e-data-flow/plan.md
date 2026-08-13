# Implementation Plan: Fix End-to-End Pipeline Data Flow & Remove Silent Fallbacks

**Branch**: `004-fix-e2e-data-flow` | **Date**: Thu Aug 13 2026 | **Spec**: [specs/004-fix-e2e-data-flow/spec.md](spec.md)

**Input**: Feature specification from `/specs/004-fix-e2e-data-flow/spec.md`

## Summary

Fix the end-to-end data flow gap between Stage 2 and Stage 3 by implementing automatic patient baseline covariate extraction (`age`, `sex`) from the CDM via `PatientProfiles` and fitting a regularized logistic regression propensity score model using `Cyclops`. Update Stage 3 (`fit_ps`, `adjust_ps`) to populate `cm_data`, `model`, and `matched_pop`. Update Stage 4 (`compile_trajectories`) to compute dynamic transition matrices and state costs from real matched cohorts. Remove silent fallback defaults in Stage 5 (`simulate_economics`) so pipeline failures fail fast with explicit errors. Validate the entire pipeline via `test-e2e.R` against DuckDB Eunomia.

## Technical Context

**Language/Version**: R (>= 4.1)

**Primary Dependencies**: `CDMConnector`, `omopgenerics`, `PatientProfiles`, `Cyclops`, `CohortCharacteristics`, `BCEA`, `dbplyr`, `dplyr`, `duckdb`

**Storage**: DuckDB / OMOP CDM v5.3 / v5.4

**Testing**: `testthat` (Edition 3) via `devtools::test()` / `test-e2e.R`

**Target Platform**: Cross-platform R session (macOS, Linux, Windows)

**Project Type**: R package (`HERMES`)

**Performance Goals**: End-to-end test execution in under 15 seconds on synthetic Eunomia DuckDB datasets.

**Constraints**: Base R pipe `|>`, assignment `<-`, strict `snake_case`, zero silent fallbacks in production pipeline functions.

**Scale/Scope**: 6-stage analytical pipeline (`init` -> `summarise_baseline`/`extract_hcru` -> `fit_ps`/`adjust_ps` -> `compile_trajectories` -> `simulate_economics` -> `run_cea`/`plot_*`).

## Constitution Check

*GATE: Passed. All development complies with R package standards and project guidelines.*

- Base pipe `|>` used exclusively.
- Assignment operator `<-` used exclusively.
- All functions exported with proper `@export` roxygen tags.
- Unit and integration tests located in `tests/testthat/`.

## Project Structure

### Documentation (this feature)

```text
specs/004-fix-e2e-data-flow/
├── plan.md              # Implementation plan
├── research.md          # Architectural decisions & research findings
├── data-model.md        # Pipeline S3 objects & entity flow
├── quickstart.md        # E2E pipeline usage example
├── contracts/           # API contracts per stage
│   └── pipeline.md
└── checklists/
    └── requirements.md  # Spec quality checklist
```

### Source Code (repository root)

```text
R/
├── init.R               # Stage 1: init()
├── baseline.R           # Stage 2: summarise_baseline()
├── hcru.R               # Stage 2: extract_hcru()
├── ps.R                 # Stage 3: fit_ps(), adjust_ps(), assess_balance()
├── trajectories.R       # Stage 4: compile_trajectories()
├── simulation.R         # Stage 5: simulate_economics()
├── cea.R                # Stage 6: run_cea(), plot_ceac(), plot_plane()
└── s3_classes.R         # S3 constructors and validators

tests/testthat/
├── test-e2e.R           # End-to-End integration test
├── test-stage3-ps.R     # Stage 3 unit tests
├── test-stage4-trajectories.R # Stage 4 unit tests
└── test-stage5-simulation.R # Stage 5 unit tests
```

**Structure Decision**: Standard single R package structure under `R/` and `tests/testthat/`.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| None | N/A | N/A |
