# Implementation Plan: DARWIN EU-Aligned Cohort Utilization & Cost APIs

**Branch**: `006-cohort-utilization-apis` | **Date**: Wed Aug 19 2026 | **Spec**: [specs/006-cohort-utilization-apis/spec.md](spec.md)

**Input**: Feature specification from `specs/006-cohort-utilization-apis/spec.md`

## Summary

Implement a modular, 3-layer analytical API suite in HERMES adhering to OHDSI / DARWIN EU standards (`CohortConstructor`, `PatientProfiles`, `CohortCharacteristics`):
1. **Layer 1 (Episode Constructors):** Standalone episode cohort generation (`computeHospitalizationCohorts()`, `computeInfusionCohorts()`).
2. **Layer 2 (Cohort Enrichers):** In-database cohort augmentation via `dbplyr` (`addHospitalizations()`, `addOutpatientVisits()`, `addPrescriptions()`, `addProcedures()`, `addCosts()`) appending windowed metrics (`baseline`, `followup`) without dropping zero-utilization subjects.
3. **Layer 3 (Analytics & Reporting):** Standardised result generation and rendering (`summariseUtilization()`, `summariseCosts()`, `tableUtilization()`, `tableCosts()`, `plotUtilization()`, `plotCosts()`).

All public R functions and parameters strictly use `lowerCamelCase` and cohort table columns use `snake_case`.

## Technical Context

**Language/Version**: R (>= 4.1.0)

**Primary Dependencies**: `omopgenerics` (>= 0.3.0), `CDMConnector` (>= 1.4.0), `PatientProfiles` (>= 1.2.0), `CohortCharacteristics` (>= 0.3.0), `CohortConstructor` (>= 0.2.0), `dbplyr` (>= 2.4.0), `dplyr` (>= 1.1.0), `rlang`, `glue`, `visOmopResults`

**Storage**: OMOP CDM v5.3 / v5.4 via DBI / dbplyr (DuckDB / Eunomia for tests, PostgreSQL / SQL Server / Oracle for production)

**Testing**: `testthat` (3.0.0+) with Eunomia synthetic test database and mock CDM fixtures

**Target Platform**: Cross-platform (macOS, Linux, Windows) R package

**Project Type**: R analytical package / HEOR & RWE pipeline library

**Performance Goals**: 100% database-side windowed joins and aggregation via `dbplyr`; sub-second execution on standard synthetic cohorts; scalable to cohorts with 100k+ patients without client-side memory blowup

**Constraints**:
- Read-only queries against source OMOP CDM tables
- Write temporary / permanent cohort tables only to the designated CDM write schema
- Base R pipe `|>`
- `<-` assignment (never `=`)
- DARWIN EU naming: `lowerCamelCase` for functions & arguments; `snake_case` for database columns
- Output of summary functions must adhere to `omopgenerics::summarised_result`

**Scale/Scope**: 5 core clinical utilization domains, direct medical costs, care episode generation, and standardised result reporting

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] **I. Zero Wheel-Reinvention**: Leverages `omopgenerics`, `PatientProfiles`, `CohortConstructor`, `CohortCharacteristics`, and `dbplyr` rather than building custom SQL engines or proprietary data formats.
- [x] **II. Standardized OMOP CDM & COST Integration**: Directly maps standard concept identifiers across `visit_occurrence`, `drug_exposure`, `procedure_occurrence`, `measurement`, `provider`, and `cost`.
- [x] **III. Pipeable S3 & DARWIN EU Architecture**: Enforces base R pipe `|>`, `lowerCamelCase` functions/arguments, `snake_case` columns, and returns registered `cohort_table` and `summarised_result` objects.
- [x] **IV. Test-First & Coverage**: Accompanied by comprehensive unit tests in `tests/testthat/test-cohort-utilization.R` and integration testing in `tests/testthat/test-e2e.R`.
- [x] **V. 6-Stage Pipeline Alignment**: Directly enhances Stage 2 (Descriptive Baseline & HCRU Characterization) while providing modular primitives for Stage 3 (PS Adjustment) and Stage 4 (Trajectories & State-Cost Extraction).

## Project Structure

### Documentation (this feature)

```text
specs/006-cohort-utilization-apis/
├── spec.md              # Feature specification
├── plan.md              # This implementation plan
├── research.md          # Technical research & design decisions
├── data-model.md        # Entities, schemas, relationships, and validation rules
├── quickstart.md        # Usage examples and code walkthrough
├── contracts/
│   └── cohort-utilization-api.md  # Public API signatures and return schemas
└── checklists/
    └── requirements.md  # Specification quality checklist
```

### Source Code (repository root)

```text
R/
├── hospitalizations.R       # computeHospitalizationCohorts(), compute_hospitalization_cohorts()
├── addHospitalizations.R    # Layer 2: addHospitalizations()
├── addOutpatientVisits.R    # Layer 2: addOutpatientVisits()
├── addPrescriptions.R       # Layer 2: addPrescriptions(), computeInfusionCohorts()
├── addProcedures.R          # Layer 2: addProcedures() (diagnostics, imaging, procedures)
├── addCosts.R               # Layer 2: addCosts() (financial linkage)
├── summariseUtilization.R   # Layer 3: summariseUtilization(), summariseCosts()
├── tableUtilization.R       # Layer 3: tableUtilization(), tableCosts(), plotUtilization(), plotCosts()
├── hcru.R                   # Legacy wrapper extract_hcru() dispatching to modular verbs
└── s3_classes.R             # S3 constructors and method dispatches

tests/testthat/
├── helper-eunomia.R         # Test CDM creation with multi-domain tables
├── test-add-hospitalizations.R  # Inpatient & ICU unit tests
├── test-add-outpatient.R        # Outpatient & specialty unit tests
├── test-add-prescriptions.R     # Pharmacy & infusion unit tests
├── test-add-procedures.R        # Diagnostics & procedure unit tests
├── test-add-costs.R             # Cost linkage unit tests
├── test-summarise-utilization.R # Summarised result & table tests
└── test-e2e.R                   # Full 6-stage pipeline regression test
```

## Complexity Tracking

*No constitutional violations. Design strictly adheres to standard DARWIN EU / OHDSI principles.*
