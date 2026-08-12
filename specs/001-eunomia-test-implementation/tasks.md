---
description: "Task list for Eunomia Test Implementation"
---

# Tasks: Eunomia Test Implementation

**Input**: Design documents from `/specs/001-eunomia-test-implementation/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/ (if any), quickstart.md

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `- [X] [ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2)
- Include exact file paths in descriptions

## Path Conventions

- Paths shown below assume standard R package structure (`R/`, `tests/testthat/`).

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [X] T001 Create project directory structure for R source code and tests in `R/` and `tests/testthat/`
- [X] T002 [P] Configure package dependencies and suggests in `DESCRIPTION` (Eunomia, CDMConnector, duckdb, testthat, covr, etc.)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T003 Define core S3 class constructor helpers (`hermes_study`, `hermes_hcru`, `hermes_ps`, `hermes_trajectories`, `hermes_sim`, `hermes_cea`) in `R/s3_classes.R`

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Eunomia Test Database Fixture Setup (Priority: P1) 🎯 MVP

**Goal**: Provision a Eunomia OMOP CDM dataset pre-populated with synthetic `COST` records for fast, offline testing.

**Independent Test**: Call `hermes_test_cdm()` and verify that a valid CDM reference connected to a Eunomia dataset containing required OMOP tables (including `COST`) is returned.

### Tests for User Story 1

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [X] T004 [P] [US1] Create unit test verifying `hermes_test_cdm()` initialization and table queries in `tests/testthat/test-fixture.R`

### Implementation for User Story 1

- [X] T005 [US1] Implement base Eunomia test fixture helper `hermes_test_cdm()` in `tests/testthat/helper-eunomia.R`
- [X] T006 [US1] Implement synthetic `COST` table population routine (`total_paid`, `amount_allowed`, etc.) in `tests/testthat/helper-eunomia.R`
- [X] T007 [US1] Implement database connection teardown logic (`cdmDisconnect()`) in `tests/testthat/helper-eunomia.R`

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently

---

## Phase 4: User Story 2 - End-to-End HERMES 6-Stage Pipeline Integration Tests (Priority: P2)

**Goal**: Implement the 6-stage HERMES API functions and matching integration tests against Eunomia data per `docs/API_SPECIFICATION.md`.

**Independent Test**: Run `devtools::test()` and verify all 6 stage test files execute deterministically and pass cleanly against the Eunomia CDM fixture.

### Tests & Implementation for User Story 2 (Stage-by-Stage)

- [X] T008 [P] [US2] Create Stage 1 integration test cases in `tests/testthat/test-stage1-init.R` (MUST use low-threshold or fallback synthetic cohort definitions)
- [X] T009 [US2] Implement Stage 1 `hermes::init()` function wrapping `CDMConnector` and `omopgenerics` in `R/init.R`
- [X] T010 [P] [US2] Create Stage 2 integration test cases for baseline characterization and direct `COST` table extractions in `tests/testthat/test-stage2-baseline-hcru.R`
- [X] T011 [US2] Implement Stage 2 `hermes::summarise_baseline()` wrapping `PatientProfiles` and `CohortCharacteristics` in `R/baseline.R`
- [X] T012 [US2] Implement Stage 2 `hermes::extract_hcru()` querying OMOP `COST` fields in `R/hcru.R`
- [X] T013 [P] [US2] Create Stage 3 integration test cases in `tests/testthat/test-stage3-causal-ps.R`
- [X] T014 [US2] Implement Stage 3 `hermes::fit_ps()`, `hermes::adjust_ps()`, and `hermes::assess_balance()` wrapping `CohortMethod` and `Cyclops` in `R/ps.R`
- [X] T015 [P] [US2] Create Stage 4 integration test cases in `tests/testthat/test-stage4-trajectories-costs.R`
- [X] T016 [US2] Implement Stage 4 `hermes::compile_trajectories()` and `hermes::extract_state_costs()` querying `COST` tables in `R/trajectories.R`
- [X] T017 [P] [US2] Create Stage 5 integration test cases in `tests/testthat/test-stage5-economic-simulation.R`
- [X] T018 [US2] Implement Stage 5 `hermes::run_simulation()` wrapping `hesim` / `heemod` state-transition engines in `R/simulation.R`
- [X] T019 [P] [US2] Create Stage 6 integration test cases in `tests/testthat/test-stage6-cea-decision.R`
- [X] T020 [US2] Implement Stage 6 `hermes::compute_cea()`, `hermes::plot_ceac()`, `hermes::plot_plane()`, and `hermes::table_summary()` wrapping `BCEA` in `R/cea.R`

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently. All 6 stages tested against Eunomia.

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories and non-functional requirements

- [X] T021 [P] Apply R code styling and linting via `styler::style_dir()` and `lintr::lint_dir()` across `R/` and `tests/testthat/`
- [X] T022 [P] Generate package documentation using `roxygen2::roxygenise()` in `R/`
- [X] T023 Run full `devtools::test()` verification following quickstart instructions and assert execution time < 60 seconds (SC-001)
- [X] T024 Run `covr::package_coverage()` to verify code coverage reaches at least 80% for database and cost extraction routines (SC-004, Constitution IV)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion
- **User Story 1 (Phase 3)**: Depends on Foundational completion (MVP Scope)
- **User Story 2 (Phase 4)**: Depends on User Story 1 completion
- **Polish (Phase 5)**: Depends on User Story 2 completion

### Parallel Opportunities

- T002 can run in parallel with T001
- T004 can run in parallel with T003
- Stage function implementations and matching test files marked `[P]` in Phase 4 can be developed in parallel per stage by different team members
- T021 and T022 can run in parallel in Phase 5

---

## Parallel Example: User Story 2

```bash
# Developer A: Stage 1 Cohort Init
Task: "Create Stage 1 integration test cases in tests/testthat/test-stage1-init.R"
Task: "Implement Stage 1 hermes::init() function in R/init.R"

# Developer B: Stage 2 Baseline & HCRU
Task: "Create Stage 2 integration test cases in tests/testthat/test-stage2-baseline-hcru.R"
Task: "Implement Stage 2 hermes::extract_hcru() querying OMOP COST fields in R/hcru.R"
```

---

## Implementation Strategy

### MVP First (User Story 1)
1. Complete Setup (Phase 1) and Foundational (Phase 2)
2. Complete User Story 1 (Phase 3)
3. **STOP and VALIDATE**: Test `hermes_test_cdm()` fixture independently

### Incremental Delivery (User Story 2)
1. Add Stage 1 tests & implementation (`R/init.R`)
2. Add Stage 2 tests & implementation (`R/baseline.R`, `R/hcru.R`)
3. Add Stage 3 tests & implementation (`R/ps.R`)
4. Add Stage 4 tests & implementation (`R/trajectories.R`)
5. Add Stage 5 tests & implementation (`R/simulation.R`)
6. Add Stage 6 tests & implementation (`R/cea.R`)
7. Run `devtools::test()` for full pipeline validation
