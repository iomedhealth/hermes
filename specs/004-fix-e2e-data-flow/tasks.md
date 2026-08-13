# Tasks: Fix End-to-End Pipeline Data Flow & Remove Silent Fallbacks

**Branch**: `004-fix-e2e-data-flow` | **Spec**: [spec.md](spec.md) | **Plan**: [plan.md](plan.md)

## Implementation Strategy & MVP Scope

- **MVP Scope**: User Story 1 (Stage 2-to-3 Causal Data Bridge) is the core MVP requirement. Completing US1 enables real baseline covariate extraction (`age`, `sex`) and Cyclops propensity score fitting (`fit_ps`, `adjust_ps`).
- **Incremental Delivery**:
  1. **Phase 1 & 2**: Setup task tracking and verify existing test environment.
  2. **Phase 3 (US1 - Priority P1)**: Implement CDM covariate extraction and propensity score model fitting in Stage 3 (`R/ps.R`), and update unit tests in `tests/testthat/test-stage3-ps.R`.
  3. **Phase 4 (US2 - Priority P2)**: Validate matched populations in Stage 4 trajectory compilation (`R/trajectories.R`) and calculate dynamic transition probability matrices from real patient entries, updating `tests/testthat/test-stage4-trajectories.R`.
  4. **Phase 5 (US3 - Priority P3)**: Remove silent fallback defaults in Stage 5 economic simulation (`R/simulation.R`) to fail fast on empty inputs, and update `tests/testthat/test-e2e.R` and `tests/testthat/test-stage5-simulation.R`.
  5. **Phase 6**: Package checks and formatting.

---

## Tasks

### Phase 1: Setup

- [x] T001 Verify active git branch `004-fix-e2e-data-flow` and specification documents in `specs/004-fix-e2e-data-flow/`

### Phase 2: Foundational

- [x] T002 Verify existing test suite baseline by running `Rscript -e "testthat::test_local()"`

---

### Phase 3: User Story 1 - Stage 2-to-3 Causal Data Bridge (Priority: P1)

**Story Goal**: Extract real patient baseline covariates (`age`, `sex`) from CDM cohort tables in `fit_ps()`, fit a regularized logistic regression model via `Cyclops`, and perform caliper matching on propensity scores in `adjust_ps()`.

**Independent Test Criteria**: Pass a `hermes_hcru` object with target and comparator cohorts to `fit_ps()` and `adjust_ps()`; assert `ps_obj$cm_data` contains patient covariates, `ps_obj$model` contains a fitted `Cyclops` model object, and `ps_obj$matched_pop` contains matched patient rows with propensity scores.

- [x] T003 [US1] Implement baseline covariate extraction (`age`, `sex`, `sex_num`) from target and comparator cohort tables using `PatientProfiles` in `R/ps.R`
- [x] T004 [US1] Update `fit_ps()` to build `Cyclops` data via `Cyclops::createCyclopsData` and fit regularized logistic regression via `Cyclops::fitCyclopsModel` in `R/ps.R`
- [x] T005 [US1] Update `adjust_ps()` to calculate propensity score predictions and perform caliper matching (default caliper 0.2) in `R/ps.R`
- [x] T006 [P] [US1] Update unit tests to verify real covariate extraction, model fitting, and non-empty `matched_pop` outputs in `tests/testthat/test-stage3-ps.R`

---

### Phase 4: User Story 2 - Stage 3-to-4 Trajectory & State-Cost Data Propagation (Priority: P2)

**Story Goal**: Validate `ps_obj$matched_pop` in Stage 4 (`compile_trajectories()`) to calculate dynamic transition probability matrices and state-grouped cost summaries (`mean_cost`, `se_cost`) from matched patient records.

**Independent Test Criteria**: Pass a `hermes_ps` object with populated `matched_pop` and `costs` to `compile_trajectories()`; assert generated `matrices` contains target and comparator transition matrices and `costs` contains state-grouped summary metrics.

- [x] T007 [US2] Update `compile_trajectories()` to validate `matched_pop` and calculate dynamic 30-day transition matrices and state cost summaries in `R/trajectories.R`
- [x] T008 [P] [US2] Update unit tests to verify dynamic transition matrices and state cost calculations in `tests/testthat/test-stage4-trajectories.R`

---

### Phase 5: User Story 3 - Fail-Fast Pipeline Verification & Integration Testing (Priority: P3)

**Story Goal**: Remove silent mock fallback logic from `simulate_economics()`, throw explicit validation errors when inputs are missing, and update `test-e2e.R` to assert real CDM data flow across all pipeline stages.

**Independent Test Criteria**:
1. Pass empty trajectory matrices or state costs to `simulate_economics()` and verify an explicit error is raised (`stop(...)`).
2. Run `test-e2e.R` against DuckDB Eunomia and verify that all 6 pipeline stages process real database records and produce valid CEA plots without invoking fallback defaults.

- [x] T009 [US3] Remove hardcoded mock default fallbacks and add explicit validation checks in `R/simulation.R`
- [x] T010 [P] [US3] Update unit tests to verify fail-fast error behavior when passed empty trajectory inputs in `tests/testthat/test-stage5-simulation.R`
- [x] T011 [US3] Update integration assertions in `tests/testthat/test-e2e.R` to verify real CDM data flow (`cm_data`, `model`, `matched_pop`, `matrices`, `costs`, `hesim_ce`) across all 6 pipeline stages

---

### Phase 6: Polish & Cross-Cutting Concerns

- [x] T012 Run full package test suite `devtools::test()` and verify all unit and E2E integration tests pass
- [x] T013 Run code formatting `styler::style_dir()` and linter `lintr::lint_dir()` across `R/` and `tests/testthat/`

---

## Dependencies & Story Completion Order

```
Phase 1: Setup (T001)
  │
  ▼
Phase 2: Foundational (T002)
  │
  ▼
Phase 3: User Story 1 [P1] (T003 -> T004 -> T005 -> T006)
  │
  ▼
Phase 4: User Story 2 [P2] (T007 -> T008)
  │
  ▼
Phase 5: User Story 3 [P3] (T009 -> T010 -> T011)
  │
  ▼
Phase 6: Polish (T012 -> T013)
```

## Parallel Execution Opportunities

- **US1**: `T006` (Stage 3 unit tests in `tests/testthat/test-stage3-ps.R`) can be developed in parallel with `T005` once Stage 3 implementation interface is finalized.
- **US2**: `T008` (Stage 4 unit tests in `tests/testthat/test-stage4-trajectories.R`) can be developed in parallel with `T007`.
- **US3**: `T010` (Stage 5 fail-fast unit tests in `tests/testthat/test-stage5-simulation.R`) can be developed in parallel with `T009`.
