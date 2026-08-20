# Tasks: Open-Ended & Infinite Window Support for Cohort Enrichers

**Input**: Design documents from `specs/009-fix-infinite-windows/` (`spec.md`, `plan.md`, `data-model.md`, `research.md`, `contracts/infinite-windows-api.md`, `quickstart.md`)

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: Enforcing Test-Driven Development (TDD). Tests MUST be updated/written first before modifying package implementation R files.

## Format: `- [ ] [TaskID] [P?] [Story?] Description with file path`

- **Checkbox**: `- [ ]`
- **Task ID**: T001, T002, T003...
- **[P]**: Parallelizable task
- **[Story?]**: [US1], [US2], [US3] for user story tasks
- Exact file paths in description

---

## Phase 1: Foundational (Window Normalization & Lowercase Suffixes)

**Purpose**: Update shared `validateWindow()` in `R/utilities.R` to normalize `NA` and `Inf` bounds and generate 100% lowercase `snake_case` column suffixes.

- [X] T001 Update `validateWindow()` in `R/utilities.R` to normalize `NA` to `-Inf`/`Inf`, lowercased auto-generated names (`0_to_inf`, `minf_to_0`, `minf_to_inf`), and lowercased user-supplied window names

---

## Phase 2: User Story 1 - Inpatient & Emergency Enrichers with Infinite Windows (Priority: P1) 🎯 MVP

**Goal**: Enable `addInpatients()`, `addHospitalizations()`, and `addEmergencyCare()` to execute cleanly with `window = c(0, Inf)`, `window = list(c(0, NA))`, and named infinite windows without column-case mismatches or date arithmetic crashes.

**Independent Test**: Execute `addInpatients(window = c(0, Inf))` and `addEmergencyCare(window = c(0, NA))` on a test cohort; verify that all events after index date are counted and table successfully registers into database write schema with `*_0_to_inf` columns.

### Tests for User Story 1 (TDD)

- [X] T002 [P] [US1] Write unit tests for `addInpatients()` and `addEmergencyCare()` with infinite (`c(0, Inf)`), `NA` (`c(0, NA)`), and bilateral (`c(-Inf, Inf)`) windows in `tests/testthat/test-add-inpatients.R` and `tests/testthat/test-add-emergency.R`

### Implementation for User Story 1

- [X] T003 [US1] Update date boundary and event filtering logic in `R/addInpatients.R` and `R/addEmergencyCare.R` to safely handle `Inf`/`-Inf` bounds and lowercase column assembly

**Checkpoint**: User Story 1 complete and testable via `devtools::test(filter = 'add-inpatients|add-emergency')`.

---

## Phase 3: User Story 2 - Outpatient, Prescriptions, Procedures, and Costs Enrichers (Priority: P1) 🎯 MVP

**Goal**: Extend open-ended and infinite window support across `addOutpatientVisits()`, `addPrescriptions()`, `addProcedures()`, and `addCosts()`.

**Independent Test**: Execute `addOutpatientVisits()`, `addPrescriptions()`, `addProcedures()`, and `addCosts()` with `window = c(0, Inf)`; verify all domain events are aggregated with 0-fill for non-utilizers and registered into the database without error.

### Tests for User Story 2 (TDD)

- [X] T004 [P] [US2] Write unit tests for `addOutpatientVisits()`, `addPrescriptions()`, `addProcedures()`, and `addCosts()` with `window = c(0, Inf)` and `window = list(c(0, NA))` in `tests/testthat/test-add-outpatient.R`, `tests/testthat/test-add-prescriptions.R`, `tests/testthat/test-add-procedures.R`, and `tests/testthat/test-add-costs.R`

### Implementation for User Story 2

- [X] T005 [US2] Update date boundary calculation, censoring, and PDC logic in `R/addOutpatientVisits.R`, `R/addPrescriptions.R`, `R/addProcedures.R`, and `R/addCosts.R`

**Checkpoint**: User Story 2 complete and testable via `devtools::test(filter = 'add-')`.

---

## Phase 4: User Story 3 - Composite `addVisits` and Censoring Support (Priority: P2)

**Goal**: Ensure `addVisits()` composite orchestrator cleanly passes open-ended windows down to all constituent care settings and respects `censorDate`.

**Independent Test**: Run `addVisits(window = list(baseline = c(-365, -1), all_followup = c(0, Inf)), censorDate = "cohort_end_date")`; verify that all active settings populate expected columns bounded by cohort end date.

### Tests for User Story 3 (TDD)

- [X] T006 [P] [US3] Write unit tests for `addVisits()` with infinite windows and `censorDate` in `tests/testthat/test-add-visits.R`

### Implementation for User Story 3

- [X] T007 [US3] Verify and adjust `addVisits()` in `R/addVisits.R` to pass down infinite windows and censoring configurations

**Checkpoint**: User Story 3 complete and testable via `devtools::test(filter = 'add-visits')`.

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Verify entire test suite passes with 0 failures, style code, and check linting.

- [X] T008 [P] Execute full test suite via `devtools::test()` ensuring 100% test pass rate
- [X] T009 [P] Run `styler::style_dir()` and `lintr::lint_package(".", linters = lintr::linters_with_defaults(lintr::object_name_linter(styles = "camelCase")))`

---

## Dependencies & Execution Order

```text
Phase 1: Foundational (T001 - validateWindow)
   │
   ▼
Phase 2: User Story 1 (T002 Tests ──> T003 Implementation) 🎯 MVP
   │
   ▼
Phase 3: User Story 2 (T004 Tests ──> T005 Implementation) 🎯 MVP
   │
   ▼
Phase 4: User Story 3 (T006 Tests ──> T007 Implementation)
   │
   ▼
Phase 5: Polish & Verification (T008, T009)
```

---

## Parallel Execution Opportunities

- **Phase 2 & 3 Tests**: T002 and T004 unit tests can be written in parallel.
- **Phase 2 & 3 Implementation**: Inpatient/Emergency (T003) and Outpatient/Rx/Proc/Costs (T005) can be implemented in parallel across separate files.
- **Phase 5**: Full test execution (T008) and styler/linting (T009) can run concurrently.

---

## Implementation Strategy

1. **MVP (Phases 1-3)**: Deliver `validateWindow` normalization and open-ended window support across all individual `add*` verbs.
2. **Unified Interface (Phase 4)**: Ensure composite `addVisits` supports full-follow-up windows.
3. **Polish & Verification (Phase 5)**: Guarantee 100% test pass rate and clean linting.
