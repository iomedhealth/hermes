# Implementation Plan: Eunomia Test Implementation

**Branch**: `001-eunomia-test-implementation` | **Date**: 2026-08-12 | **Spec**: [specs/001-eunomia-test-implementation/spec.md](spec.md)

**Input**: Feature specification from `/specs/001-eunomia-test-implementation/spec.md`

## Summary

Implement a standardized Eunomia-backed OMOP CDM test database fixture and comprehensive 6-stage pipeline unit/integration test suite for HERMES. The implementation adheres to the 6-stage pipeline architecture by wrapping OHDSI/DARWIN EU/HEOR packages (`CDMConnector`, `omopgenerics`, `PatientProfiles`, `CohortCharacteristics`, `CohortMethod`, `Cyclops`, `Cohort2Trajectory`, `TrajectoryMarkovAnalysis`, `hesim`/`heemod`, `BCEA`) and directly querying the OMOP `COST` table (`cost_domain_id`, `cost_type_concept_id`, `total_paid`, `total_charge`, `amount_allowed`).

## Technical Context

**Language/Version**: R >= 4.1

**Primary Dependencies**: `CDMConnector`, `omopgenerics`, `PatientProfiles`, `CohortCharacteristics`, `CohortMethod`, `Cyclops`, `Cohort2Trajectory`, `TrajectoryMarkovAnalysis`, `hesim`, `heemod`, `BCEA`, `dbplyr`, `duckdb`, `testthat`, `withr`, `covr`

**Storage**: Embedded DuckDB / SQLite temporary OMOP CDM database (Eunomia)

**Testing**: `testthat` (Target execution time <60s)

**Target Platform**: Cross-platform R environment (macOS, Linux, Windows, CI/CD)

**Project Type**: R package (`HERMES`)

**Performance Goals**: Complete all Eunomia-backed 6-stage pipeline integration tests in <60 seconds

**Constraints**:
- Base R pipe `|>` only (never `%>%`)
- Assignment using `<-` only (never `=`)
- `snake_case` naming conventions
- Temporary work tables only in write schemas
- Direct querying of OMOP `COST` table fields (`cost_domain_id`, `cost_type_concept_id`, `total_paid`, `total_charge`, `amount_allowed`)
- Clean database teardown with 0 leaked locks or temp files

**Scale/Scope**: Synthetic Eunomia dataset (~1,000 to ~10,000 patients)

## Constitution Check

*GATE: Passed. No constitutional violations.*

1. **Zero Wheel-Reinvention (Package Wrapping Strategy)**: PASS - Each stage wraps existing ecosystem packages (DARWIN-EU preferred).
2. **Standardized OMOP CDM & COST Integration**: PASS - Directly queries OMOP `COST` fields and respects table constraints.
3. **Pipeable S3 Architecture**: PASS - Base R pipe `|>` with S3 class flow (`hermes_study` -> `hermes_cea`).
4. **Test-First & Coverage**: PASS - Unit and integration test coverage across all 6 stages; enforces 80% coverage on database/cost routines.
5. **6-Stage Analytical Pipeline Alignment**: PASS - Aligns with 6 stages directly in implementation and tests.

## Project Structure

### Documentation (this feature)

```text
specs/001-eunomia-test-implementation/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # API contracts mapping function signatures
│   └── api-contract.md
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
R/
├── init.R               # Stage 1: hermes::init()
├── baseline.R           # Stage 2: hermes::summarise_baseline()
├── hcru.R               # Stage 2: hermes::extract_hcru() (OMOP COST queries)
├── ps.R                 # Stage 3: hermes::fit_ps(), adjust_ps(), assess_balance()
├── trajectories.R       # Stage 4: hermes::compile_trajectories(), extract_state_costs()
├── simulation.R         # Stage 5: hermes::run_simulation()
├── cea.R                # Stage 6: hermes::compute_cea(), plots, summaries
└── s3_classes.R         # Core S3 class constructor helpers

tests/testthat/
├── helper-eunomia.R                   # Eunomia test fixture setup & COST table population
├── test-fixture.R                     # Eunomia fixture unit tests
├── test-stage1-init.R                 # Stage 1 test cases
├── test-stage2-baseline-hcru.R        # Stage 2 test cases
├── test-stage3-causal-ps.R            # Stage 3 test cases
├── test-stage4-trajectories-costs.R   # Stage 4 test cases
├── test-stage5-economic-simulation.R  # Stage 5 test cases
└── test-stage6-cea-decision.R         # Stage 6 test cases
```

**Structure Decision**: Standard R package directory structure with `R/` containing package functions and `tests/testthat/` containing unit/integration tests and fixtures. The `plan.md` directory structure perfectly aligns with the required files for `tasks.md`.

## Complexity Tracking

> No constitutional violations. Table left blank.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| None | N/A | N/A |
