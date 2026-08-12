<!--
Sync Impact Report:
- Version change: 0.1.0 -> 1.0.0
- Modified principles: Replaced template placeholders with 5 core HERMES principles:
  - I. Zero Wheel-Reinvention (DARWIN-EU over HADES)
  - II. Standardized OMOP CDM & COST Integration
  - III. Pipeable S3 Architecture
  - IV. Test-First & Coverage
  - V. 6-Stage Analytical Pipeline Alignment
- Added sections: Replaced placeholder sections with "Additional Constraints" and "Development Workflow & Quality Gates"
- Removed sections: None
- Templates requiring updates (✅ updated / ⚠ pending):
  - plan-template.md: ✅ No update needed (generic)
  - spec-template.md: ✅ No update needed (generic)
  - tasks-template.md: ✅ No update needed (generic)
- Follow-up TODOs: None
-->
# HERMES Constitution

## Core Principles

### I. Zero Wheel-Reinvention (Package Wrapping Strategy)
Implementation must wrap existing ecosystem packages (preferring DARWIN-EU tooling over HADES) rather than rebuilding functionality. Standard operations should leverage tools such as `CDMConnector`, `omopgenerics`, `PatientProfiles`, `CohortCharacteristics`, `CohortMethod`, and `Cyclops`.

### II. Standardized OMOP CDM & COST Integration
The package must strictly follow OHDSI OMOP CDM conventions. It must never modify core OMOP tables; temporary work tables must be stored in designated result or scratch schemas. Direct integration and querying of OMOP `COST` fields is required where applicable.

### III. Pipeable S3 Architecture
Development must target R >= 4.1. All code must use the base R pipe `|>` (never `%>%`) and the `<-` assignment operator (never `=`). Variable and function names must use `snake_case`. Outputs must follow a defined R S3 class hierarchy across pipeline stages.

### IV. Test-First & Coverage (NON-NEGOTIABLE)
All new logic requires comprehensive unit and integration tests placed in `tests/testthat/`. High code coverage is mandatory for database interaction and analytical routines. Test-Driven Development (TDD) principles apply.

### V. 6-Stage Analytical Pipeline Alignment
Every feature or module must align conceptually and architecturally with the HERMES 6-stage framework: (1) Cohort Generation, (2) Descriptive Baseline & HCRU, (3) Causal PS Adjustment, (4) Trajectories, (5) Economic Simulation, (6) Decision Analysis.

## Additional Constraints

All implementations must conform to standard R package structures. `styler::style_dir()` and `lintr::lint_dir()` must pass before committing. Roxygen2 must be used for documentation. Embedded databases like DuckDB/SQLite may be used for testing (e.g., Eunomia), but teardown must be clean.

## Development Workflow & Quality Gates

Code review requires verification of test coverage, adherence to OMOP/OHDSI read-only constraints on core tables, and proper S3 class returns. The preference for DARWIN-EU over HADES where functionality overlaps must be validated during PR review.

## Governance

This Constitution supersedes all local developer preferences. Amendments require documentation and team approval. Unjustified deviations from the 6-stage pipeline, OMOP constraints, or core dependency strategy will block merges.

**Version**: 1.0.0 | **Ratified**: 2026-08-12 | **Last Amended**: 2026-08-12
