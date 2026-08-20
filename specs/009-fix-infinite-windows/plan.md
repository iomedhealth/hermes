# Implementation Plan: Open-Ended & Infinite Window Support for Cohort Enrichers

**Branch**: `009-fix-infinite-windows` | **Date**: Thu Aug 20 2026 | **Spec**: [specs/009-fix-infinite-windows/spec.md](spec.md)

**Input**: Feature specification from `specs/009-fix-infinite-windows/spec.md`

## Summary

Fix bug in `validateWindow` and cohort utilization enrichers (`addInpatients`, `addEmergencyCare`, `addOutpatientVisits`, `addPrescriptions`, `addProcedures`, `addCosts`, `addVisits`) to seamlessly support open-ended observation windows (`c(0, Inf)`, `c(0, NA)`, `c(-Inf, 0)`, `c(-Inf, Inf)`) with 100% lowercase `snake_case` column naming (`0_to_inf`, `minf_to_0`, `minf_to_inf`) preventing database case-folding mismatch and `dplyr::select` table registration crashes.

## Technical Context

**Language/Version**: R (>= 4.1.0)

**Primary Dependencies**: `omopgenerics` (>= 0.3.0), `CDMConnector` (>= 1.4.0), `dbplyr` (>= 2.4.0), `dplyr` (>= 1.1.0), `rlang`, `glue`, `cli`

**Storage**: OMOP CDM v5.3 / v5.4 via DBI / dbplyr (DuckDB / Eunomia for unit tests)

**Testing**: `testthat` (3.0.0+) with `hermesTestCdm()` fixtures

**Constraints**:
- Base R pipe `|>`
- `<-` assignment
- DARWIN EU `lowerCamelCase` functions and arguments
- 100% lowercase `snake_case` column names in all generated tables

## Constitution Check

- [x] **I. Zero Wheel-Reinvention**: Extends existing `validateWindow` and date filtering in `R/utilities.R` and enricher functions.
- [x] **II. Standardized OMOP CDM Integration**: Aligns with `PatientProfiles` open-ended window conventions (`c(0, Inf)`, `c(0, NA)`).
- [x] **III. Pipeable S3 & DARWIN EU Architecture**: Returns registered `cohort_table` objects with valid database-safe column names.
- [x] **IV. Test-First & Coverage**: Accompanied by unit tests for `validateWindow` and all enrichers with infinite bounds.
- [x] **V. 6-Stage Pipeline Alignment**: Directly enhances Stage 2 (Descriptive Baseline & HCRU Characterization).

## Project Structure

### Documentation (this feature)

```text
specs/009-fix-infinite-windows/
├── spec.md              # Feature specification
├── plan.md              # This implementation plan
├── research.md          # Technical research & design decisions
├── data-model.md        # Entities, schemas, and validation rules
├── quickstart.md        # Usage examples and validation guide
├── contracts/
│   └── infinite-windows-api.md  # Public API signatures and return schemas
└── checklists/
    └── requirements.md  # Specification quality checklist
```

### Source Code (repository root)

```text
R/
├── utilities.R           # validateWindow with NA/Inf normalization & lowercase snake_case suffixes
├── addInpatients.R       # addInpatients() with safe date bounds
├── addEmergencyCare.R    # addEmergencyCare() with safe date bounds
├── addOutpatientVisits.R # addOutpatientVisits() with safe date bounds
├── addPrescriptions.R    # addPrescriptions() with safe date bounds & pdc handling
├── addProcedures.R       # addProcedures() with safe date bounds
├── addCosts.R            # addCosts() with safe date bounds
└── addVisits.R           # addVisits() pass-through

tests/testthat/
├── test-add-inpatients.R # Infinite window tests for inpatient
├── test-add-emergency.R  # Infinite window tests for emergency
├── test-add-visits.R     # Infinite window tests for addVisits
└── test-add-outpatient.R # Infinite window tests for outpatient
```
