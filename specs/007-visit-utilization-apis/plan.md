# Implementation Plan: Inpatient, Emergency Care, and Unified Visit Utilization APIs

**Branch**: `007-visit-utilization-apis` | **Date**: Thu Aug 20 2026 | **Spec**: [specs/007-visit-utilization-apis/spec.md](spec.md)

**Input**: Feature specification from `specs/007-visit-utilization-apis/spec.md`

## Summary

Enhance the HERMES cohort utilization enricher family with:
1. **`addInpatients()`**: Rename from `addHospitalizations()`, preserving `addHospitalizations()` and `addInpatient()` as aliases. Enrich with granular `specialties` breakdown and `stratifySpecialty` support.
2. **`addEmergencyCare()`**: Dedicated emergency care enricher capturing acute encounters via **both** OMOP emergency visit concepts (9203, 262, 581478) and Emergency Medicine provider specialty concepts (38004510), with `specialties` breakdown and aliases `addEmergency()`, `addEmergencyVisits()`.
3. **`addVisits()`**: Unified composite enricher orchestrating Inpatient, Outpatient, and Emergency care in a single, streamlined function with unified specialty stratification.

All functions strictly use `lowerCamelCase` names and parameters, produce `snake_case` database column names, and return registered `omopgenerics::cohort_table` objects.

## Technical Context

**Language/Version**: R (>= 4.1.0)

**Primary Dependencies**: `omopgenerics` (>= 0.3.0), `CDMConnector` (>= 1.4.0), `dbplyr` (>= 2.4.0), `dplyr` (>= 1.1.0), `rlang`, `glue`, `cli`

**Storage**: OMOP CDM v5.3 / v5.4 via DBI / dbplyr (DuckDB / Eunomia for unit tests; PostgreSQL / SQL Server for production)

**Testing**: `testthat` (3.0.0+) with `hermes_test_cdm()` fixtures

**Performance Goals**: 100% database-side windowed joins and aggregations; retain zero-utilization subjects with 0L/0.0 values; sub-second execution on test fixtures

**Constraints**:
- Read-only queries against OMOP CDM tables (`visit_occurrence`, `provider`, `person`)
- Temporary/new tables registered via `omopgenerics::insertTable()` and `omopgenerics::newCohortTable()`
- Base R pipe `|>`
- `<-` assignment (never `=`)
- DARWIN EU naming: `lowerCamelCase` for functions & arguments; `snake_case` for database columns
- Output tables preserve 100% of cohort subjects with 0-fill for non-utilizers

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] **I. Zero Wheel-Reinvention**: Leverages `omopgenerics`, `CDMConnector`, `dbplyr`, and existing validation helpers (`validateWindow`, `validateIndexDate`, `validateCensorDate`, `validateName`).
- [x] **II. Standardized OMOP CDM Integration**: Directly maps standard OMOP concept identifiers for Inpatient, Emergency Room, ICU, and Provider Specialties.
- [x] **III. Pipeable S3 & DARWIN EU Architecture**: Strict `lowerCamelCase` functions/arguments, `snake_case` columns, base R pipe `|>`, returning registered `cohort_table` objects.
- [x] **IV. Test-First & Coverage**: Accompanied by unit tests covering `addInpatients`, `addEmergencyCare`, `addVisits`, provider specialty stratification, dual-emergency detection, and backward compatibility aliases.
- [x] **V. 6-Stage Pipeline Alignment**: Directly enhances Stage 2 (Descriptive Baseline & HCRU Characterization).

## Project Structure

### Documentation (this feature)

```text
specs/007-visit-utilization-apis/
├── spec.md              # Feature specification
├── plan.md              # This implementation plan
├── research.md          # Technical research & design decisions
├── data-model.md        # Entities, schemas, relationships, and validation rules
├── quickstart.md        # Usage examples and validation guide
├── contracts/
│   └── visit-enrichers-api.md  # Public API signatures and return schemas
└── checklists/
    └── requirements.md  # Specification quality checklist
```

### Source Code (repository root)

```text
R/
├── addInpatients.R       # addInpatients(), addHospitalizations(), addInpatient()
├── addEmergencyCare.R    # addEmergencyCare(), addEmergency(), addEmergencyVisits()
├── addVisits.R           # addVisits() composite multi-setting runner
├── addOutpatientVisits.R # addOutpatientVisits()
└── utilities.R          # Windowing, date, and table validation helpers

tests/testthat/
├── test-add-inpatients.R # Inpatient admissions, LOS, ICU, readmissions, and specialty tests
├── test-add-emergency.R  # Emergency care dual-detection (visit concepts + provider specialty) tests
└── test-add-visits.R     # Composite multi-setting visit utilization tests
```

## Complexity Tracking

*No constitutional violations. Design strictly adheres to standard DARWIN EU / OHDSI principles.*
