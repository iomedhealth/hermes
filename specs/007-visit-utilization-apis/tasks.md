# Tasks: Inpatient, Emergency Care, and Unified Visit Utilization APIs

**Input**: Design documents from `specs/007-visit-utilization-apis/` (`spec.md`, `plan.md`, `data-model.md`, `research.md`, `contracts/visit-enrichers-api.md`, `quickstart.md`)

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: Enforcing Test-Driven Development (TDD). Unit tests MUST be written first before modifying/adding package implementation R files.

## Format: `- [ ] [TaskID] [P?] [Story?] Description with file path`

- **Checkbox**: `- [ ]`
- **Task ID**: T001, T002, T003...
- **[P]**: Parallelizable task
- **[Story?]**: [US1], [US2], [US3] for user story tasks
- Exact file paths in description

---

## Phase 1: Setup (Test Fixtures & Mock Data)

**Purpose**: Provide synthetic CDM test fixtures with provider specialties (Emergency Medicine, Oncology, Cardiology, General Practice) and visit records covering all care settings.

- [X] T001 Update synthetic test CDM generator with Emergency Medicine (concept ID 38004510) and specialty-linked visit records in `tests/testthat/helper-eunomia.R`

---

## Phase 2: Foundational (Utilities & Common Validation)

**Purpose**: Ensure shared windowing, date, and table lifecycle utilities support the new visit enricher family.

- [X] T002 [P] Verify and ensure windowing and table validation utilities in `R/utilities.R` support the new visit enrichers

---

## Phase 3: User Story 1 - Inpatient Care Cohort Enrichment with Specialty Stratification (Priority: P1) 🎯 MVP

**Goal**: Implement `addInpatients()` (renamed from `addHospitalizations()`, with backward-compatible aliases `addHospitalizations()` and `addInpatient()`), supporting admissions, length of stay, ICU utilization, 30d/90d readmissions, and granular provider specialty stratification.

**Independent Test**: Execute `addInpatients()` on a study cohort; verify admissions, LOS, ICU stays, readmissions, and specialty-stratified inpatient admission columns are populated and zero-filled for non-admitted subjects.

### Tests for User Story 1 (TDD)

- [X] T003 [P] [US1] Write unit tests for `addInpatients()` (admissions, LOS, ICU, readmissions, specialty breakdown, and backward-compat aliases) in `tests/testthat/test-add-inpatients.R`

### Implementation for User Story 1

- [X] T004 [US1] Implement `addInpatients()` with `stratifySpecialty`, `specialties`, admissions, LOS, ICU stays, readmissions, and exported aliases `addHospitalizations` and `addInpatient` in `R/addInpatients.R`

**Checkpoint**: User Story 1 complete and independently testable via `devtools::test(filter = 'add-inpatients')`.

---

## Phase 4: User Story 2 - Comprehensive Emergency Care Identification & Enrichment (Priority: P1) 🎯 MVP

**Goal**: Implement `addEmergencyCare()` to identify emergency encounters via **both** emergency room visit concept IDs and Emergency Medicine provider specialty concept IDs, with optional specialty stratification and aliases `addEmergency()` and `addEmergencyVisits()`.

**Independent Test**: Execute `addEmergencyCare()` on a test cohort containing both visit-concept-tagged ER visits and outpatient/inpatient visits attended by emergency specialists; verify all emergency care acts are counted under `emergency_visits_*`.

### Tests for User Story 2 (TDD)

- [X] T005 [P] [US2] Write unit tests for `addEmergencyCare()` (visit concepts + emergency provider specialty dual-detection, specialty stratification, aliases) in `tests/testthat/test-add-emergency.R`

### Implementation for User Story 2

- [X] T006 [US2] Implement `addEmergencyCare()` with dual-criteria detection, `specialties` breakdown, and aliases `addEmergency` and `addEmergencyVisits` in `R/addEmergencyCare.R`

**Checkpoint**: User Story 2 complete and independently testable via `devtools::test(filter = 'add-emergency')`.

---

## Phase 5: User Story 3 - Unified Multi-Setting Visit Utilization Enrichment (Priority: P2)

**Goal**: Implement `addVisits()` composite enricher to coordinate Inpatient, Outpatient, and Emergency care enrichment in a single execution with unified specialty stratification.

**Independent Test**: Execute `addVisits()` with `settings = c("inpatient", "outpatient", "emergency")` and `specialties` list; verify that metrics across all three settings and granular specialties are appended in a single cohort table.

### Tests for User Story 3 (TDD)

- [X] T007 [P] [US3] Write unit tests for `addVisits()` (multi-setting orchestration, setting filtering, and unified specialty breakdown) in `tests/testthat/test-add-visits.R`

### Implementation for User Story 3

- [X] T008 [US3] Implement `addVisits()` coordinating `addInpatients()`, `addOutpatientVisits()`, and `addEmergencyCare()` in `R/addVisits.R`

**Checkpoint**: User Story 3 complete and independently testable via `devtools::test(filter = 'add-visits')`.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Update summarisation pattern matching, documentation, package exports, and verify 100% test pass rate and DARWIN EU style compliance.

- [X] T009 Update `summariseUtilization()` auto-detection patterns in `R/summariseUtilization.R` for new visit columns
- [X] T010 [P] Update package exports in `NAMESPACE` and function catalog in `_pkgdown.yml`
- [X] T011 [P] Execute full test suite via `devtools::test()` ensuring 100% test pass rate
- [X] T012 [P] Run `styler::style_dir()` and `lintr::lint_package(".", linters = lintr::linters_with_defaults(lintr::object_name_linter(styles = "camelCase")))`

---

## Dependencies & Execution Order

```text
Phase 1: Setup (T001) & Phase 2: Foundational (T002)
   │
   ▼
Phase 3: User Story 1 (P1 - Inpatient Care & Specialty) 🎯 MVP
   ├── Tests: T003
   └── Implementation: T004
   │
   ▼
Phase 4: User Story 2 (P1 - Emergency Care Dual Detection) 🎯 MVP
   ├── Tests: T005
   └── Implementation: T006
   │
   ▼
Phase 5: User Story 3 (P2 - Unified addVisits Composite)
   ├── Tests: T007
   └── Implementation: T008
   │
   ▼
Phase 6: Polish & Verification (T009, T010, T011, T012)
```

---

## Parallel Execution Opportunities

- **Phase 3 (US1) & Phase 4 (US2)**: Tests (T003, T005) and implementations (T004, T006) for `addInpatients` and `addEmergencyCare` can be authored independently in parallel.
- **Phase 6**: Package documentation/exports (T010), test suite verification (T011), and styling/linting (T012) can be verified concurrently.

---

## Implementation Strategy

1. **MVP (Phases 1-4)**: Deliver `addInpatients()` and `addEmergencyCare()` with dual-criteria emergency detection and specialty stratification.
2. **Unified Interface (Phase 5)**: Deliver `addVisits()` composite enricher for all three care settings.
3. **Polish & Verification (Phase 6)**: Ensure comprehensive test coverage, documentation, and camelCase linter compliance.
