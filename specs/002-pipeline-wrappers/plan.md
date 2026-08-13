# Implementation Plan: Implement Pipeline Wrappers

**Branch**: `002-pipeline-wrappers` | **Date**: 2026-08-13 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/002-pipeline-wrappers/spec.md`

## Summary

Replace current pipeline stubs with actual OHDSI/OMOP clinical logic by wrapping existing ecosystem packages (CDMConnector, PatientProfiles, CohortMethod, hesim, BCEA) for all 6 stages of the HERMES pipeline. Ensure tests target the `GiBleed` Eunomia dataset.

## Technical Context

**Language/Version**: R >= 4.1

**Primary Dependencies**: CDMConnector, omopgenerics, PatientProfiles, CohortCharacteristics, CohortMethod, Cyclops, Cohort2Trajectory, TrajectoryMarkovAnalysis, hesim, BCEA

**Storage**: DuckDB in-memory (Eunomia GiBleed fixture) for testing; OMOP CDM

**Testing**: testthat

**Target Platform**: Linux/macOS/Windows (R package)

**Project Type**: R package

**Performance Goals**: <60 seconds for unit tests on Eunomia fixture

**Constraints**: Base R pipe `|>`, `<-` assignment, snake_case, no modification of core OMOP tables.

**Scale/Scope**: E2E pipeline wrappers for 6 analytic stages.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. Zero Wheel-Reinvention**: Pass. Using designated DARWIN-EU/OHDSI packages.
- **II. Standardized OMOP CDM & COST Integration**: Pass. Adheres to read-only constraints on OMOP tables.
- **III. Pipeable S3 Architecture**: Pass. S3 classes and base pipe strictly used.
- **IV. Test-First & Coverage**: Pass. Relying on Eunomia GiBleed fixture for sub-60s tests.
- **V. 6-Stage Analytical Pipeline Alignment**: Pass. Work is explicitly bounded to the 6 stages.

## Project Structure

### Documentation (this feature)

```text
specs/002-pipeline-wrappers/
├── plan.md              
├── research.md          
├── data-model.md        
├── quickstart.md        
├── contracts/           
│   └── pipeline.md
└── tasks.md             
```

### Source Code (repository root)

```text
# R Package structure
R/
├── init.R
├── baseline.R
├── hcru.R
├── ps.R
├── trajectories.R
├── simulation.R
├── cea.R
└── s3_classes.R

tests/testthat/
├── helper-eunomia.R
├── test-stage1-init.R
├── test-stage2-hcru.R
└── test-e2e.R
```

**Structure Decision**: Maintained existing R package structure, modifying the contents of the `R/` directory files and their corresponding `tests/testthat/` files.