# Tasks: [FEATURE_NAME]

**Branch**: `[BRANCH_NAME]` | **Spec**: [spec.md](spec.md) | **Plan**: [plan.md](plan.md)

## Tasks

### Phase 1: Setup

- [ ] T001 Initialize task tracking and verify environment setup

### Phase 2: Foundational

- [ ] T002 Verify test suite baseline in `tests/testthat/`

### Phase 3: User Story 1 - Stage 2-to-3 Causal Data Bridge (Priority: P1)

- [ ] T003 [US1] Implement baseline covariate extraction (`age`, `sex`) in `R/ps.R`
- [ ] T004 [US1] Update `fit_ps()` to create Cyclops data and fit regularized logistic regression model in `R/ps.R`
- [ ] T005 [US1] Update `adjust_ps()` to perform caliper matching on propensity scores in `R/ps.R`
- [ ] T006 [US1] Write unit tests for Stage 3 covariate extraction and propensity score matching in `tests/testthat/test-stage3-ps.R`

### Phase 4: User Story 2 - Stage 3-to-4 Trajectory & State-Cost Data Propagation (Priority: P2)

- [ ] T007 [US2] Update `compile_trajectories()` to compute dynamic transition matrices and state costs from `matched_pop` in `R/trajectories.R`
- [ ] T008 [US2] Write unit tests for Stage 4 trajectory matrix compilation in `tests/testthat/test-stage4-trajectories.R`

### Phase 5: User Story 3 - Fail-Fast Pipeline Verification & Integration Testing (Priority: P3)

- [ ] T009 [US3] Remove silent mock fallbacks and add explicit validation in `R/simulation.R`
- [ ] T010 [US3] Update `tests/testthat/test-e2e.R` to assert real CDM data flow across all 6 stages
- [ ] T011 [US3] Update unit tests in `tests/testthat/test-stage5-simulation.R` for fail-fast error checking

### Phase 6: Polish & Cross-Cutting Concerns

- [ ] T012 Run full package test suite `devtools::test()` and formatting checks
