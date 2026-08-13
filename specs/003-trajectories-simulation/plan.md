# Implementation Plan: Stage 4 (Trajectories) and Stage 5 (Economic Simulation)

**Branch**: `003-trajectories-simulation` | **Date**: 2026-08-13 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/003-trajectories-simulation/spec.md`

## Summary

Implement the true analytical logic for Stage 4 (`compile_trajectories()`) and Stage 5 (`simulate_economics()`) in the HERMES pipeline, replacing mock placeholders. Integrate synthetic cost injection into DuckDB Eunomia test setup to enable native TDD testing for Stage 4, Stage 5, and E2E.

## Technical Context

**Language/Version**: R >= 4.1

**Primary Dependencies**: CDMConnector, omopgenerics, Cohort2Trajectory, TrajectoryMarkovAnalysis, hesim, BCEA, dplyr, dbplyr, stats

**Storage**: DuckDB in-memory (Eunomia GiBleed dataset) for testing; OMOP CDM

**Testing**: testthat

**Target Platform**: Linux/macOS/Windows (R package)

**Project Type**: R package

**Performance Goals**: <60 seconds for unit tests on Eunomia fixture

**Constraints**: Base R pipe `|>`, `<-` assignment, `snake_case`, read-only access to core OMOP tables.

**Scale/Scope**: Stage 4 (Trajectories) and Stage 5 (Economic Simulation) of the 6-stage pipeline.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. Zero Wheel-Reinvention**: Pass. Using `Cohort2Trajectory` / `TrajectoryMarkovAnalysis` and `hesim` / `BCEA`.
- **II. Standardized OMOP CDM & COST Integration**: Pass. Adheres to read-only constraints on OMOP tables.
- **III. Pipeable S3 Architecture**: Pass. S3 classes (`hermes_trajectories`, `hermes_sim`) and base pipe `|>` strictly used.
- **IV. Test-First & Coverage**: Pass. Relying on Eunomia GiBleed fixture with injected cost records for sub-60s native tests.
- **V. 6-Stage Analytical Pipeline Alignment**: Pass. Aligns directly with Stages 4 & 5.

## Project Structure

### Documentation (this feature)

```text
specs/003-trajectories-simulation/
├── plan.md              
├── research.md          
├── data-model.md        
├── quickstart.md        
├── contracts/           
│   └── trajectories-simulation.md
└── checklists/
    └── requirements.md
```

### Source Code (repository root)

```text
R/
├── trajectories.R
├── simulation.R
└── s3_classes.R

tests/testthat/
├── helper-eunomia.R
├── test-stage4-trajectories.R
├── test-stage5-simulation.R
└── test-e2e.R
```

**Structure Decision**: Maintained existing R package structure, modifying `R/trajectories.R`, `R/simulation.R`, `tests/testthat/helper-eunomia.R`, `tests/testthat/test-stage4-trajectories.R`, `tests/testthat/test-stage5-simulation.R`, and `tests/testthat/test-e2e.R`.
