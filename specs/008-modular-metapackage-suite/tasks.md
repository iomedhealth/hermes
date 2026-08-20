# Tasks: Modular DARWIN EU Package Suite & Metapackage

**Input**: Design documents from `specs/008-modular-metapackage-suite/` (`spec.md`, `plan.md`, `data-model.md`, `research.md`, `contracts/monorepo-suite-contracts.md`, `quickstart.md`)

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: Enforcing Test-Driven Development (TDD). Each sub-package must pass its own isolated test suite.

## Format: `- [ ] [TaskID] [P?] [Story?] Description with file path`

- **Checkbox**: `- [ ]`
- **Task ID**: T001, T002, T003...
- **[P]**: Parallelizable task
- **[Story?]**: [US1], [US2], [US3], [US4], [US5] for user story tasks
- Exact file paths in description

---

## Phase 1: Setup (Monorepo Directory Structure)

**Purpose**: Establish the monorepo folder layout with subdirectories for `CohortUtilisation`, `CohortCosts`, and `CohortEconomics`.

- [X] T001 Create monorepo directory hierarchy under `packages/CohortUtilisation`, `packages/CohortCosts`, and `packages/CohortEconomics`

---

## Phase 2: Foundational (Package Manifests & Shared Helpers)

**Purpose**: Create `DESCRIPTION` files and shared validation utilities across all three domain packages.

- [X] T002 Create `DESCRIPTION` and validation utilities in `packages/CohortUtilisation/DESCRIPTION` and `packages/CohortUtilisation/R/utilities.R`
- [X] T003 [P] Create `DESCRIPTION` in `packages/CohortCosts/DESCRIPTION`
- [X] T004 [P] Create `DESCRIPTION` in `packages/CohortEconomics/DESCRIPTION`

---

## Phase 3: User Story 1 - Standalone Healthcare Resource Utilization (`CohortUtilisation`) (Priority: P1) 🎯 MVP

**Goal**: Implement and test `CohortUtilisation` as an isolated, lightweight package for HCRU extraction without simulation/CEA dependencies.

**Independent Test**: Run `devtools::test("packages/CohortUtilisation")`; verify all visit, prescription, procedure, and utilization summary tests pass in isolation.

### Tests for User Story 1 (TDD)

- [X] T005 [P] [US1] Set up test fixtures and migrate HCRU unit tests in `packages/CohortUtilisation/tests/testthat/`

### Implementation for User Story 1

- [X] T006 [US1] Migrate and implement all HCRU enrichers and formatters in `packages/CohortUtilisation/R/`
- [X] T007 [US1] Generate documentation and verify isolated package check via `devtools::document("packages/CohortUtilisation")` and `devtools::test("packages/CohortUtilisation")`

**Checkpoint**: `CohortUtilisation` complete and independently testable.

---

## Phase 4: User Story 2 - Standalone Medical Costs & Tariff Tracking (`CohortCosts`) (Priority: P1) 🎯 MVP

**Goal**: Implement and test `CohortCosts` as a dedicated package for OMOP `COST` linkage, expenditure summarisation, and cost tariff modeling.

**Independent Test**: Run `devtools::test("packages/CohortCosts")`; verify cost linkage, domain stratification, and tariff data work in isolation.

### Tests for User Story 2 (TDD)

- [X] T008 [P] [US2] Set up test fixtures and migrate cost unit tests in `packages/CohortCosts/tests/testthat/`

### Implementation for User Story 2

- [X] T009 [US2] Migrate and implement cost functions and tariff data in `packages/CohortCosts/R/` and `packages/CohortCosts/data/`
- [X] T010 [US2] Generate documentation and verify isolated package check via `devtools::document("packages/CohortCosts")` and `devtools::test("packages/CohortCosts")`

**Checkpoint**: `CohortCosts` complete and independently testable.

---

## Phase 5: User Story 3 - Standalone Health Economics, Trajectories & Decision Analysis (`CohortEconomics`) (Priority: P1) 🎯 MVP

**Goal**: Implement and test `CohortEconomics` for causal PS, trajectory compilation, Markov simulation, and Cost-Effectiveness Analysis.

**Independent Test**: Run `devtools::test("packages/CohortEconomics")`; verify end-to-end HEOR simulation and CEA plotting execute smoothly.

### Tests for User Story 3 (TDD)

- [X] T011 [P] [US3] Set up test fixtures and migrate simulation/CEA unit tests in `packages/CohortEconomics/tests/testthat/`

### Implementation for User Story 3

- [X] T012 [US3] Migrate and implement economic modeling functions in `packages/CohortEconomics/R/`
- [X] T013 [US3] Generate documentation and verify isolated package check via `devtools::document("packages/CohortEconomics")` and `devtools::test("packages/CohortEconomics")`

**Checkpoint**: `CohortEconomics` complete and independently testable.

---

## Phase 6: User Story 4 - Seamless Metapackage Experience (`hermes`) (Priority: P2)

**Goal**: Configure the root umbrella metapackage to install and attach all three sub-packages seamlessly.

**Independent Test**: Load `library(hermes)`; verify startup banner displays attached packages and all domain functions are available.

### Implementation for User Story 4

- [X] T014 [US4] Implement metapackage startup banner and namespace attach hook in `R/zzz.R`
- [X] T015 [US4] Configure root `DESCRIPTION` and `NAMESPACE` for `hermes` metapackage and generate documentation via `devtools::document()`

---

## Phase 7: User Story 5 - Unified Shared Documentation Website (`pkgdown`) (Priority: P2)

**Goal**: Configure unified documentation site cataloging all three packages.

**Independent Test**: Verify `_pkgdown.yml` cleanly references functions across HCRU, Costs, and Health Economics.

### Implementation for User Story 5

- [X] T016 [US5] Update root `_pkgdown.yml` and vignettes to index all three domain packages

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Execute full test verification and style compliance checks across the entire monorepo.

- [X] T017 [P] Execute test suites across all 3 sub-packages and root metapackage
- [X] T018 [P] Run `styler` and `lintr` compliance checks across all package directories

---

## Dependencies & Execution Order

```text
Phase 1: Setup (T001) & Phase 2: Foundational (T002, T003, T004)
   │
   ├──> Phase 3: User Story 1 (CohortUtilisation: T005, T006, T007)
   ├──> Phase 4: User Story 2 (CohortCosts: T008, T009, T010)
   │     │
   │     ▼
   └──> Phase 5: User Story 3 (CohortEconomics: T011, T012, T013)
         │
         ▼
Phase 6: User Story 4 (Metapackage hermes: T014, T015)
         │
         ▼
Phase 7: User Story 5 (Unified Docs: T016)
         │
         ▼
Phase 8: Polish & Final Verification (T017, T018)
```

---

## Parallel Execution Opportunities

- **Phase 2 (Foundational)**: T002, T003, and T004 can be created in parallel.
- **Phases 3 & 4**: `CohortUtilisation` (T005-T007) and `CohortCosts` (T008-T010) can be built independently in parallel.
- **Phase 8**: Testing (T017) and styling/linting (T018) can run concurrently.

---

## Implementation Strategy

1. **MVP (Phases 1-5)**: Establish the 3 domain packages (`CohortUtilisation`, `CohortCosts`, `CohortEconomics`) with 100% test coverage in isolation.
2. **Metapackage & Docs (Phases 6-7)**: Deliver `hermes` umbrella loading mechanism and unified `pkgdown` website.
3. **Verification (Phase 8)**: Full monorepo CI testing and style compliance.
