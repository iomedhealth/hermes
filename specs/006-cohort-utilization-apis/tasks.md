# Tasks: DARWIN EU-Aligned Cohort Utilization & Cost APIs

**Input**: Design documents from `specs/006-cohort-utilization-apis/` (`spec.md`, `plan.md`, `data-model.md`, `research.md`, `contracts/cohort-utilization-api.md`, `quickstart.md`)

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: Enforcing Test-Driven Development (TDD). Tests MUST be updated/written first before modifying package implementation R files.

## Format: `- [ ] [TaskID] [P?] [Story?] Description with file path`

- **Checkbox**: `- [ ]`
- **Task ID**: T001, T002, T003...
- **[P]**: Parallelizable task
- **[Story?]**: [US1], [US2], [US3] for user story tasks
- Exact file paths in description

---

## Phase 1: Setup (Shared Infrastructure & Validation Helpers)

**Purpose**: Provide CDM test fixtures and shared validation utilities mirroring `PatientProfiles` and `CohortConstructor`.

- [X] T001 Update synthetic test CDM generators with complete visit, provider, drug, measurement, procedure, and cost tables in `tests/testthat/helper-eunomia.R`
- [X] T002 [P] Implement shared validation helpers (`validateWindowArgument`, `validateNameStyle`, `validateCdmTables`) in `R/utilities.R`

---

## Phase 2: Foundational (In-Database Query & Scaffolding Primitives)

**Purpose**: Provide core `dbplyr` windowing, column name generation, and table cleanup routines shared across enrichers.

- [X] T003 Implement in-database window expansion and date interval query builder in `R/utilities.R`
- [X] T004 [P] Implement temporary table naming and cleanup lifecycle helpers (`tmpPrefix`, `uniqueTableName`, `dropSourceTable`) in `R/utilities.R`

---

## Phase 3: User Story 1 - In-Database Cohort Enrichment across Core Domains (Priority: P1) 🎯 MVP

**Goal**: Implement modular `add*` verbs (`addHospitalizations`, `addOutpatientVisits`, `addPrescriptions`, `addProcedures`, `addCosts`) that enrich study cohorts in-database with windowed metrics and direct medical costs using `PatientProfiles` patterns.

**Independent Test**: Pipe a study cohort through all 5 enricher functions; verify that all original rows are preserved, 0-count fill semantics hold, and columns match the API contract across baseline and follow-up windows.

### Tests for User Story 1 (TDD)

- [X] T005 [P] [US1] Write unit tests for `addHospitalizations()` (admissions, LOS, ICU, readmissions) in `tests/testthat/test-add-hospitalizations.R`
- [X] T006 [P] [US1] Write unit tests for `addOutpatientVisits()` (GP, Specialist, ED stratification) in `tests/testthat/test-add-outpatient.R`
- [X] T007 [P] [US1] Write unit tests for `addPrescriptions()` (fills, days supply, PDC, infusions) in `tests/testthat/test-add-prescriptions.R`
- [X] T008 [P] [US1] Write unit tests for `addProcedures()` (lab measurements, imaging, procedures) in `tests/testthat/test-add-procedures.R`
- [X] T009 [P] [US1] Write unit tests for `addCosts()` (inpatient, outpatient, drug, procedure, total costs) in `tests/testthat/test-add-costs.R`

### Implementation for User Story 1

- [X] T010 [US1] Implement `addHospitalizations()` with inpatient/ICU visit concepts, LOS calculation, and optional readmissions in `R/addHospitalizations.R`
- [X] T011 [US1] Implement `addOutpatientVisits()` with provider specialty join and GP/Specialist/ED classification in `R/addOutpatientVisits.R`
- [X] T012 [US1] Implement `addPrescriptions()` with `drug_exposure` aggregation, days supply, PDC calculation, and infusion route filtering in `R/addPrescriptions.R`
- [X] T013 [US1] Implement `addProcedures()` with `measurement` and `procedure_occurrence` filtering for labs, imaging, and procedures in `R/addProcedures.R`
- [X] T014 [US1] Implement `addCosts()` with polymorphic OMOP `cost` table linkage by domain and event ID in `R/addCosts.R`

**Checkpoint**: User Story 1 complete and independently testable via `devtools::test(filter = 'add-')`.

---

## Phase 4: User Story 2 - Discrete Care Episode Cohort Generation (Priority: P2)

**Goal**: Implement standalone care episode constructors (`computeHospitalizationCohorts`, `computeInfusionCohorts`) returning valid `omopgenerics::cohort_table` objects.

**Independent Test**: Run episode constructors on synthetic data; verify that contiguous hospital stays are collapsed, readmissions are flagged within the washout window, and infusion episodes are registered in the write schema.

### Tests for User Story 2 (TDD)

- [X] T015 [P] [US2] Write unit tests for `computeHospitalizationCohorts()` and `computeInfusionCohorts()` in `tests/testthat/test-compute-episodes.R`

### Implementation for User Story 2

- [X] T016 [US2] Refactor and align `computeHospitalizationCohorts()` with DARWIN EU standards and camelCase arguments in `R/hospitalizations.R`
- [X] T017 [US2] Implement `computeInfusionCohorts()` delegating to `CohortConstructor::conceptCohort()` with parenteral route filtering in `R/computeInfusionCohorts.R`

**Checkpoint**: User Story 2 complete and independently testable via `devtools::test(filter = 'compute-episodes')`.

---

## Phase 5: User Story 3 - Standardized Analytical Summarisation & Reporting (Priority: P3)

**Goal**: Implement DARWIN EU standardised result summarisation and table/plot formatting functions (`summariseUtilization`, `summariseCosts`, `tableUtilization`, `tableCosts`, `plotUtilization`, `plotCosts`).

**Independent Test**: Aggregate an enriched cohort table using `summariseUtilization()` and `summariseCosts()`; verify output passes `omopgenerics::validateResultArgument()` and formats into GT tables via `tableUtilization()`.

### Tests for User Story 3 (TDD)

- [X] T018 [P] [US3] Write unit tests for `summariseUtilization()`, `summariseCosts()`, and table/plot rendering in `tests/testthat/test-summarise-utilization.R`

### Implementation for User Story 3

- [X] T019 [US3] Implement `summariseUtilization()` and `summariseCosts()` returning `omopgenerics::summarised_result` in `R/summariseUtilization.R`
- [X] T020 [US3] Implement `tableUtilization()`, `tableCosts()`, `plotUtilization()`, and `plotCosts()` delegating to `visOmopResults` in `R/tableUtilization.R`

**Checkpoint**: User Story 3 complete and independently testable via `devtools::test(filter = 'summarise-utilization')`.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Refactor legacy wrapper `extract_hcru()`, verify full pipeline regression, document functions, and enforce DARWIN EU style compliance.

- [X] T021 Refactor `extract_hcru()` in `R/hcru.R` to compose the new modular `add*` verbs while maintaining backward compatibility
- [X] T022 Update end-to-end integration test `tests/testthat/test-e2e.R` verifying 6-stage pipeline execution with modular enrichers
- [X] T023 [P] Generate package documentation and NAMESPACE exports via `devtools::document()`
- [X] T024 [P] Execute full test suite via `devtools::test()` ensuring 100% test pass rate
- [X] T025 [P] Run `styler::style_dir()` and `lintr::lint_package(".", linters = lintr::linters_with_defaults(lintr::object_name_linter(styles = "camelCase")))`

---

## Dependencies & Execution Order

```text
Foundational (T001, T002, T003, T004)
   │
   ▼
Phase 3: User Story 1 (P1 - In-Database Cohort Enrichers) 🎯 MVP
   ├── Tests: T005, T006, T007, T008, T009
   └── Implementation: T010 ──> T011 ──> T012 ──> T013 ──> T014
   │
   ▼
Phase 4: User Story 2 (P2 - Discrete Care Episode Generation)
   ├── Tests: T015
   └── Implementation: T016 ──> T017
   │
   ▼
Phase 5: User Story 3 (P3 - Summarisation & Reporting)
   ├── Tests: T018
   └── Implementation: T019 ──> T020
   │
   ▼
Phase 6: Polish, Legacy Composition & Compliance (T021, T022, T023, T024, T025)
```

---

## Parallel Execution Opportunities

- **Phase 1 & 2**: T001, T002, and T004 can be prepared in parallel.
- **Phase 3 (US1 Tests)**: T005, T006, T007, T008, and T009 can all be authored in parallel.
- **Phase 3 (US1 Implementation)**: Inpatient (T010), Outpatient (T011), Pharmacy (T012), Procedures (T013), and Costs (T014) can be developed in separate files.
- **Phase 4 (US2)**: Hospitalizations (T016) and Infusions (T017) are completely independent files.
- **Phase 5 (US3)**: Summarisation (T019) and Table/Plot rendering (T020) can be implemented in parallel.
- **Phase 6**: Documentation (T023), full test run (T024), and linter/styler (T025) can run concurrently.

---

## Implementation Strategy

1. **MVP (Phases 1-3)**: Deliver the 5 in-database cohort enricher verbs (`addHospitalizations`, `addOutpatientVisits`, `addPrescriptions`, `addProcedures`, `addCosts`) with 100% test coverage.
2. **Episode Modeling (Phase 4)**: Provide discrete hospitalization and infusion cohort constructors for time-to-event and survival analyses.
3. **Reporting & Summary (Phase 5)**: Deliver DARWIN EU standardized `summarised_result` and publication-ready table outputs.
4. **Integration & Compliance (Phase 6)**: Ensure seamless 6-stage HERMES pipeline execution and complete camelCase linter compliance.
