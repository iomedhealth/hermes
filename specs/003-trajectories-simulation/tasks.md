# Tasks: Stage 4 (Trajectories) and Stage 5 (Economic Simulation)

**Input**: Design documents from `specs/003-trajectories-simulation/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: Enforcing Test-Driven Development (TDD) as explicitly requested by the user. Tests MUST be updated/written first before modifying package implementation R files.

## Format: `- [ ] [TaskID] [P?] [Story?] Description with file path`

- **Checkbox**: `- [ ]`
- **Task ID**: T001, T002, T003...
- **[P]**: Parallelizable task
- **[Story?]**: [US1], [US2], [US3] for user story tasks
- Exact file paths in description

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Verify dependencies and test setup.

- [X] T001 Verify R package test environment and dependencies (`Cohort2Trajectory`, `TrajectoryMarkovAnalysis`, `hesim`, `BCEA`) in `tests/testthat.R`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Test database financial data injection required for native DuckDB execution.

- [X] T002 Update test helper `tests/testthat/helper-eunomia.R` to inject synthetic OMOP `COST` records linked to Target (4285898L), Comparator (4266809L), and Outcome (192671L) condition occurrences in DuckDB.

---

## Phase 3: User Story 3 - Test Lifecycle & Synthetic Cost Injection Integration (Priority: P1)

**Goal**: Integrate synthetic financial data into the testing lifecycle so that Stage 2, Stage 4, Stage 5, and E2E tests execute natively against DuckDB without inline package mocks.

**Independent Test**: Execute `devtools::test(filter = 'fixture|stage2')` and verify real cost data is populated and extracted from DuckDB.

### Tests for User Story 3 (TDD)

- [X] T003 [US3] Write test asserting injected synthetic `COST` table records in `tests/testthat/test-fixture.R`
- [X] T004 [US3] Update Stage 2 test in `tests/testthat/test-stage2-hcru.R` to assert `extract_hcru()` retrieves real cost records from DuckDB

---

## Phase 4: User Story 1 - Stage 4: Trajectory Compilation & State Cost Analysis (Priority: P1) 🎯 MVP

**Goal**: Implement dynamic transition probability matrix computation across 30-day cycles and health-state cost grouping with mean and standard error metrics in `compile_trajectories()`, removing static matrix mocks.

**Independent Test**: Pass a `hermes_ps` object with matched cohorts and extracted costs to `compile_trajectories()`; verify dynamic transition matrices and state cost summaries (`mean_cost`, `se_cost`).

### Tests for User Story 1 (TDD)

- [X] T005 [US1] Update Stage 4 test in `tests/testthat/test-stage4-trajectories.R` to assert dynamic transition probability matrices and state cost summary statistics (`mean_cost`, `se_cost`) without static matrix mocks

### Implementation for User Story 1

- [X] T006 [US1] Implement dynamic transition probability matrix computation in `R/trajectories.R` using 30-day cohort state transitions, removing static `matrix(c(0.8...))` mock
- [X] T007 [US1] Implement cost aggregation logic in `R/trajectories.R` grouping patient costs from `ps_obj$hcru_obj$costs` by trajectory health state, computing `mean_cost` and `se_cost` (`sd / sqrt(n)`)
- [X] T008 [US1] Implement fallback logic in `R/trajectories.R` for single-state populations or sparse transitions to ensure valid matrix structures and cost statistics

**Checkpoint**: User Story 1 complete and independently testable via `devtools::test(filter = 'stage4')`.

---

## Phase 5: User Story 2 - Stage 5: Economic Simulation (Priority: P1)

**Goal**: Implement a Markov Probabilistic Sensitivity Analysis (PSA) simulation in `simulate_economics()` drawing parameters from transition matrices and health state cost/utility distributions, formatting outputs into `hesim_ce` structure for Stage 6 `run_cea()`, removing `stats::rnorm()` mocks.

**Independent Test**: Pass a `hermes_trajectories` object to `simulate_economics()`; verify generated `hesim_ce` output containing `costs` and `qalys` data frames and compatibility with `run_cea()`.

### Tests for User Story 2 (TDD)

- [X] T009 [US2] Update Stage 5 test in `tests/testthat/test-stage5-simulation.R` to assert PSA Markov simulation execution without `stats::rnorm()` hardcoded placeholder mocks

### Implementation for User Story 2

- [X] T010 [US2] Implement PSA Markov simulation sampling engine in `R/simulation.R` drawing parameter samples (transition probabilities, state costs, state utilities) according to uncertainty distributions
- [X] T011 [US2] Structure simulation results into standard `hesim_ce` format (`costs` and `qalys` data frames with `sample`, `strategy_id`, and metric columns) in `R/simulation.R` for seamless Stage 6 `run_cea()` consumption

**Checkpoint**: User Story 2 complete and independently testable via `devtools::test(filter = 'stage5')`.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Ensure end-to-end pipeline execution and code standards compliance.

- [X] T012 Update end-to-end integration test `tests/testthat/test-e2e.R` verifying pipeline execution from Stage 1 through Stage 6 natively on DuckDB without mocked data injection
- [X] T013 [P] Execute full test suite via `devtools::test()` ensuring 100% test pass rate in under 60 seconds (SC-001)
- [X] T014 [P] Run `styler::style_dir()` and `lintr::lint_dir()` to enforce HERMES style guidelines (Base pipe `|>`, `<-` assignment, `snake_case`)

---

## Dependencies & Execution Order

```text
Foundational (T001, T002)
   └── User Story 3 Tests & Fixtures (T003, T004)
          └── User Story 1 Trajectories (T005 -> T006, T007, T008)
                 └── User Story 2 Simulation (T009 -> T010, T011)
                        └── Polish & E2E (T012, T013, T014)
```

## Parallel Execution Opportunities

- T013 and T014 (Polish tasks) can run in parallel after implementation is complete.
