---
description: "Task list template for feature implementation"
---

# Tasks: Implement Pipeline Wrappers

**Input**: Design documents from `specs/002-pipeline-wrappers/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: The examples below include test tasks, enforcing the Test-First & Coverage constitution requirement using the `GiBleed` dataset.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure.
*(Skipped as the basic R package structure and DuckDB setup are already in place)*

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented
*(Skipped as the `helper-eunomia.R` fixture targeting GiBleed is already assumed to be in place based on the specs.)*

---

## Phase 3: User Story 1 - Stage 1: Cohort Generation (Priority: P1) 🎯 MVP

**Goal**: Validate provided target, comparator, and outcome cohorts exist in the provided OMOP CDM reference, and attach cohort counts to the `hermes_study` object using `CDMConnector` and `omopgenerics`.

**Independent Test**: Provide Eunomia GiBleed `cdm` reference, verify `hermes_study` object validates existing cohorts and includes their counts.

### Tests for User Story 1 ⚠️

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [X] T001 [US1] Write test for successful Stage 1 cohort validation and count extraction in `tests/testthat/test-stage1-init.R`
- [X] T002 [US1] Write test for Stage 1 error handling when required cohorts are missing in `tests/testthat/test-stage1-init.R`

### Implementation for User Story 1

- [X] T003 [US1] Implement `init` wrapper logic to validate cohorts and extract counts using `CDMConnector` in `R/init.R`
- [X] T004 [US1] Ensure `init` wrapper returns a properly formatted `hermes_study` S3 object with cohort count metrics attached in `R/init.R`

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently

---

## Phase 4: User Story 2 - Stage 2: Baseline & HCRU Characterization (Priority: P1)

**Goal**: Generate baseline demographics/comorbidity tables and extract unadjusted care utilization and direct medical costs directly from the OMOP `COST` table.

**Independent Test**: Use a valid `hermes_study` object against the Eunomia fixture; verify output `hermes_hcru` object contains demographics, comorbidities, and raw cost queries.

### Tests for User Story 2 ⚠️

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [X] T005 [US2] Write test for baseline demographics and comorbidity generation in `tests/testthat/test-stage2-hcru.R`
- [X] T006 [US2] Write test for HCRU unadjusted care utilization and medical cost extraction from the `COST` table in `tests/testthat/test-stage2-hcru.R`

### Implementation for User Story 2

- [X] T007 [P] [US2] Implement `summarise_baseline` wrapper using `PatientProfiles` and `CohortCharacteristics` to generate Table 1 in `R/baseline.R`
- [X] T008 [P] [US2] Implement `extract_hcru` logic querying the OMOP `COST` table via `dplyr`/`dbplyr` in `R/hcru.R`
- [X] T009 [US2] Ensure both Stage 2 wrappers return a properly structured `hermes_hcru` S3 object by appending data in `R/baseline.R` and `R/hcru.R`

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently

---

## Phase 5: User Story 6 - Stage 6: CEA Decision Analysis (Priority: P1)

**Goal**: Extract actual simulated cost and effect matrices from `hermes_sim` to run final Cost-Effectiveness Analysis via `BCEA`, replacing mocked data.

**Independent Test**: Pass a valid `hermes_sim` object (can be synthesized explicitly for testing here if preceding stages aren't run) and verify real matrices are extracted and passed to `BCEA::bcea()`.

### Tests for User Story 6 ⚠️

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [X] T010 [US6] Write test verifying CEA analysis execution without mocked random normal data in `tests/testthat/test-stage6-cea.R` (Note: Need to create this file)

### Implementation for User Story 6

- [X] T011 [US6] Refactor `run_cea` wrapper to extract real `c` and `e` matrices from the `hermes_sim` object in `R/cea.R`
- [X] T012 [US6] Remove all mathematical mocking (`rnorm()`) from the CEA wrapper and ensure it passes real data to `BCEA::bcea()` in `R/cea.R`
- [X] T013 [US6] Ensure output is a properly structured `hermes_cea` S3 object containing ICER, NMB, CEAC plots/summaries in `R/cea.R`

**Checkpoint**: Core P1 requirements (Init, Baseline, CEA) are fully implemented.

---

## Phase 6: User Story 3 - Stage 3: Causal Propensity Score Adjustment (Priority: P2)

**Goal**: Adjust for confounding by fitting regularized logistic regression models using baseline features, outputting matched/weighted populations and SMD summaries.

**Independent Test**: Use a valid `hermes_hcru` object to verify model fitting and valid SMD balance summary output.

### Tests for User Story 3 ⚠️

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [X] T014 [US3] Write test for regularized logistic regression model fitting and matched population generation in `tests/testthat/test-stage3-ps.R` (Note: Need to create this file)

### Implementation for User Story 3

- [X] T015 [US3] Implement `fit_ps` and `adjust_ps` wrappers using `CohortMethod` and `Cyclops` for baseline feature modeling in `R/ps.R`
- [X] T016 [US3] Implement `assess_balance` wrapper to extract SMD balance summaries in `R/ps.R`
- [X] T017 [US3] Ensure Stage 3 wrappers return a properly structured `hermes_ps` S3 object containing the model and matched population in `R/ps.R`

**Checkpoint**: Causal inference pipeline stage is fully functional.

---

## Phase 7: User Story 4 - Stage 4: Trajectories & State Costs (Priority: P2)

**Goal**: Aggregate timelines into discrete health states, calculate transition probability matrices, and group extracted costs by health states.

**Independent Test**: Use a valid `hermes_ps` object to verify timelines are aggregated, matrices generated, and costs correctly grouped.

### Tests for User Story 4 ⚠️

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [X] T018 [US4] Write test for trajectory aggregation and transition probability matrix generation in `tests/testthat/test-stage4-trajectories.R` (Note: Need to create this file)

### Implementation for User Story 4

- [X] T019 [US4] Implement `compile_trajectories` wrapper using `Cohort2Trajectory` and `TrajectoryMarkovAnalysis` in `R/trajectories.R`
- [X] T020 [US4] Implement logic to group `COST` table extractions (from Stage 2) into the discrete health states in `R/trajectories.R`
- [X] T021 [US4] Ensure Stage 4 wrappers return a properly structured `hermes_trajectories` S3 object in `R/trajectories.R`

**Checkpoint**: Trajectories and cost-groupings are ready for economic simulation.

---

## Phase 8: User Story 5 - Stage 5: Economic Simulation (Priority: P2)

**Goal**: Run a probabilistic sensitivity analysis (PSA) or deterministic Markov model using transition matrices and state costs, outputting simulated Costs and Effects matrices.

**Independent Test**: Use a valid `hermes_trajectories` object; verify the simulation runs and outputs valid matrices.

### Tests for User Story 5 ⚠️

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [X] T022 [US5] Write test for economic simulation execution returning simulated cost and effect matrices in `tests/testthat/test-stage5-simulation.R` (Note: Need to create this file)

### Implementation for User Story 5

- [X] T023 [US5] Implement `simulate_economics` wrapper using `hesim` or `heemod` to process transition matrices and state costs in `R/simulation.R`
- [X] T024 [US5] Ensure the output is a properly structured `hermes_sim` S3 object containing the large `c` and `e` matrices in `R/simulation.R`

**Checkpoint**: All user stories should now be independently functional.

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories and ensure end-to-end cohesion.

- [X] T025 Update E2E test `test-e2e.R` to ensure data flows flawlessly from Stage 1 through Stage 6 utilizing the newly integrated wrappers and the Eunomia GiBleed fixture.
- [X] T026 Run complete test suite and ensure total execution time is under 60 seconds (SC-001).
- [X] T027 Run `styler::style_dir()` and `lintr::lint_dir()` to ensure pipeline adheres to project R syntax standards (Base pipe `|>`, snake_case, etc).

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup / Foundational**: Currently assumed complete via existing package scaffolding.
- **User Stories (Phase 3+)**: Can technically be worked on somewhat independently by mocking inputs from the previous stages (e.g. creating a dummy `hermes_study` for Stage 2), though a sequential approach (P1s -> P2s) is recommended to ensure smooth data flow.
- **Polish (Final Phase)**: Depends on all desired user stories being complete.

### User Story Dependencies

- **User Story 1 (P1)**: No dependencies.
- **User Story 2 (P1)**: Depends structurally on US1, but can be built independently by passing a dummy `hermes_study`.
- **User Story 6 (P1)**: Highly dependent structurally on US5, but prioritized as P1. Build by passing a dummy `hermes_sim` object.
- **User Story 3 (P2)**: Depends structurally on US2.
- **User Story 4 (P2)**: Depends structurally on US3.
- **User Story 5 (P2)**: Depends structurally on US4.

### Parallel Opportunities

- All tests for a user story marked [P] can run in parallel
- US2 Implementations (`baseline.R` vs `hcru.R`) marked [P] can run in parallel
- If team capacity allows, multiple stages can be developed simultaneously by mocking the incoming S3 object for that stage.