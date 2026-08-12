# Feature Specification: Basic Implementation Using Eunomia for Testing

**Feature Branch**: `001-eunomia-test-implementation`

**Created**: 2026-08-12

**Status**: Draft

**Input**: User description: "Can you perform a basic implementation using eunomia for testing ?"

## Clarifications

### Session 2026-08-12

- Q: Is User Story 3 (Offline Test Suite Reliability) required as a separate user story? → A: No, User Story 3 is not needed and has been removed; offline test execution is captured as a non-functional constraint.
- Q: What architecture and wrapper strategy must be implemented? → A: Implementation must conform to `docs/API_SPECIFICATION.md` implementing the 6-stage pipeline using zero wheel-reinvention (wrapping CDMConnector, omopgenerics, PatientProfiles, CohortCharacteristics, CohortMethod, Cyclops, Cohort2Trajectory, TrajectoryMarkovAnalysis, hesim/heemod, and BCEA) with direct OMOP `COST` table interaction (`cost_domain_id`, `cost_type_concept_id`, `total_paid`, `total_charge`, `amount_allowed`).
- Q: Does "S3 object flow" refer to AWS S3 storage? → A: No, "S3" refers strictly to the standard R programming language S3 Object-Oriented class system (e.g., `structure(..., class = "hermes_study")`), NOT Amazon Web Services (AWS S3). No cloud or AWS dependencies exist.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Eunomia Test Database Fixture Setup (Priority: P1)

As a HERMES package developer, I want a standardized test helper function that provisions a Eunomia-backed OMOP CDM database fixture with synthetic `COST` data so that test cases can run against a compliant dataset without external database infrastructure.

**Why this priority**: Core foundation required for repeatable, offline testing across all 6 HERMES pipeline stages.

**Independent Test**: Can be independently verified by calling `hermes_test_cdm()` (or test helper) and verifying that a valid `cdm_reference` connected to a Eunomia dataset containing required OMOP tables (including `COST`) is returned.

**Acceptance Scenarios**:

1. **Given** an R testing environment with Eunomia / CDMConnector installed, **When** the test setup helper is invoked, **Then** an active OMOP CDM reference object connected to a sample dataset (with mock or generated `COST` table entries) is created.
2. **Given** an active Eunomia CDM reference, **When** metadata and table queries are executed against standard OMOP CDM tables (person, observation_period, condition_occurrence, visit_occurrence, cost), **Then** valid `dbplyr` table references are returned without error.

---

### User Story 2 - End-to-End HERMES 6-Stage Pipeline Integration Tests (Priority: P2)

As a package developer, I want comprehensive integration test cases in `tests/testthat/` using the Eunomia CDM reference to execute and validate the complete 6-stage HERMES pipeline functions as specified in `docs/API_SPECIFICATION.md`.

**Why this priority**: Validates that all 6 stages of HERMES function seamlessly together wrapping underlying OHDSI/DARWIN EU/HEOR packages and directly querying the OMOP `COST` table.

**Independent Test**: Run `devtools::test()` and verify all 6 pipeline stage tests execute deterministically against the Eunomia CDM fixture.

**Acceptance Scenarios**:

1. **Given** a Eunomia CDM reference, **When** `hermes::init()` is called (Stage 1), **Then** a `hermes_study` R S3 class object linking target and comparator cohorts is created using `CDMConnector` and `omopgenerics`.
2. **Given** a `hermes_study` object, **When** `hermes::summarise_baseline()` and `hermes::extract_hcru()` are called (Stage 2), **Then** baseline demographic summaries and direct `COST` table extractions (`total_paid`, `total_charge`, `amount_allowed`, `cost_domain_id`, `cost_type_concept_id`) return valid `omopgenerics::summarised_result` and `hermes_hcru` R S3 class objects using `PatientProfiles` and `CohortCharacteristics`.
3. **Given** a `hermes_study` or `hermes_hcru` object, **When** `hermes::fit_ps()`, `hermes::adjust_ps()`, and `hermes::assess_balance()` are called (Stage 3), **Then** propensity scores and SMD balance diagnostics are computed into a `hermes_ps` R S3 class object using `CohortMethod` and `Cyclops`.
4. **Given** adjusted comparative cohorts, **When** `hermes::compile_trajectories()` and `hermes::extract_state_costs()` are called (Stage 4), **Then** health state timelines and state-specific cost distributions are compiled into a `hermes_trajectories` R S3 class object using `Cohort2Trajectory`, `TrajectoryMarkovAnalysis`, and `COST` table queries.
5. **Given** compiled health state trajectories, **When** `hermes::run_simulation()` is called (Stage 5), **Then** a decision-analytic state-transition simulation returns a `hermes_sim` R S3 class object using `hesim` / `heemod`.
6. **Given** simulation results, **When** `hermes::compute_cea()`, `hermes::plot_ceac()`, `hermes::plot_plane()`, and `hermes::table_summary()` are called (Stage 6), **Then** cost-effectiveness metrics (ICER, NMB) and decision analytic visual outputs are generated into a `hermes_cea` R S3 class object using `BCEA`.

---

### Edge Cases

- How does the test helper handle synthetic Eunomia datasets where the OMOP `COST` table is missing or unpopulated? (Helper MUST automatically populate/mock minimal `COST` records if missing).
- What happens if the Eunomia sample data lacks sufficient overlapping patient records for specific cohort definitions? (Tests MUST use low-threshold or fallback synthetic cohort definitions).
- How does the test cleanup handle temporary DuckDB/SQLite database connections and file locks? (Teardown helper MUST explicitly run `cdmDisconnect()` on exit).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST provide a reusable test fixture (`tests/testthat/helper-eunomia.R` or equivalent) that initializes a Eunomia OMOP CDM dataset with populated `COST` data.
- **FR-002**: Stage 1 Cohort Setup MUST wrap `CDMConnector` and `omopgenerics` via `hermes::init()`.
- **FR-003**: Stage 2 Baseline & HCRU MUST wrap `PatientProfiles` and `CohortCharacteristics` via `hermes::summarise_baseline()` and directly query OMOP `COST` fields (`cost_domain_id`, `cost_type_concept_id`, `total_paid`, `total_charge`, `amount_allowed`) via `hermes::extract_hcru()`.
- **FR-004**: Stage 3 Causal Propensity Score Adjustment MUST wrap `CohortMethod` and `Cyclops` via `hermes::fit_ps()`, `hermes::adjust_ps()`, and `hermes::assess_balance()`.
- **FR-005**: Stage 4 Trajectories & OMOP Costs MUST wrap `Cohort2Trajectory` and `TrajectoryMarkovAnalysis` via `hermes::compile_trajectories()` and query OMOP `COST` table via `hermes::extract_state_costs()`.
- **FR-006**: Stage 5 Economic Simulation MUST wrap `hesim` / `heemod` state-transition engines via `hermes::run_simulation()`.
- **FR-007**: Stage 6 Decision Analysis MUST wrap `BCEA` via `hermes::compute_cea()`, `hermes::plot_ceac()`, `hermes::plot_plane()`, and `hermes::table_summary()`.
- **FR-008**: System MUST include comprehensive unit/integration test files in `tests/testthat/` covering all 6 pipeline stages against the Eunomia CDM fixture.
- **FR-009**: Test fixture MUST handle connection teardown cleanly to prevent orphaned locks or temporary file leaks during test runs.

### Key Entities *(include if feature involves data)*

- **Eunomia CDM Reference (`cdm_reference`)**: The standardized `omopgenerics`/`CDMConnector` database connection wrapper representing the Eunomia OMOP dataset.
- **HERMES Pipeline Objects (R S3 Classes)**: The R S3 class hierarchy flowing across stages (`hermes_study` -> `hermes_hcru` -> `hermes_ps` -> `hermes_trajectories` -> `hermes_sim` -> `hermes_cea`).
- **OMOP `COST` Table**: CDM table containing direct medical expenditure records (`cost_event_id`, `cost_domain_id`, `cost_type_concept_id`, `total_paid`, `total_charge`, `amount_allowed`).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Developers can execute `devtools::test()` locally and complete all Eunomia-backed 6-stage pipeline unit/integration tests in under 60 seconds.
- **SC-002**: 100% of pipeline functions specified in `docs/API_SPECIFICATION.md` have passing integration tests using the Eunomia CDM fixture.
- **SC-003**: Test fixture provisions and tears down test CDM instances with 0 leaked temp files or orphaned database locks after test suite completion.
- **SC-004**: Code coverage for database interaction and cost extraction routines reaches at least 80% with the introduction of Eunomia test fixtures.

## Assumptions

- Eunomia / CDMConnector dataset generator is configured in `DESCRIPTION` under `Suggests`.
- DuckDB or SQLite is available in the local R environment as the underlying embedded database engine.
- Synthetic Eunomia datasets contain standard OMOP CDM v5.3 or v5.4 table schemas with populated or synthetically injected `COST` records.
