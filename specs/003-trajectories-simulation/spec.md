# Feature Specification: Implement True Logic for Stage 4 (Trajectories) and Stage 5 (Economic Simulation)

**Feature Branch**: `003-trajectories-simulation`

**Created**: 2026-08-13

**Status**: Draft

**Input**: Implement the true logic for Stage 4 (Trajectories) and Stage 5 (Economic Simulation) in the HERMES pipeline, removing existing "ponytail" placeholder mocks.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Stage 4: Trajectory Compilation & State Cost Analysis (Priority: P1)

As an RWE researcher using HERMES, I need Stage 4 (`compile_trajectories()`) to compute actual state-to-state transition probability matrices across 30-day cycles using trajectory analysis packages (`Cohort2Trajectory` and/or `TrajectoryMarkovAnalysis`) for Target, Comparator, and Outcome cohorts, and group patient-level costs extracted from `ps_obj$hcru_obj$costs` by health state to compute mean and standard error metrics.

**Why this priority**: Real transition probabilities and health-state cost distributions are required as parameters for the Stage 5 economic simulation.

**Independent Test**: Testable using a valid `hermes_ps` object containing patient matched cohorts and patient-level cost data from the OMOP `COST` table. Verify that `compile_trajectories()` outputs actual transition matrices and summary cost statistics (mean and standard error) per health state.

**Acceptance Scenarios**:

1. **Given** a valid `hermes_ps` object with matched target, comparator, and outcome cohorts, **When** `compile_trajectories()` is executed, **Then** transition probability matrices are generated dynamically via `Cohort2Trajectory` / `TrajectoryMarkovAnalysis` over 30-day cycle lengths.
2. **Given** patient-level costs in `ps_obj$hcru_obj$costs`, **When** `compile_trajectories()` aggregates costs by health state, **Then** state-grouped costs are computed with `mean` and `standard error` (`sd / sqrt(n)`) per health state.
3. **Given** an empty or single-state patient population, **When** `compile_trajectories()` runs, **Then** valid fallback transition probability matrices and state cost summaries are constructed without throwing errors.

---

### User Story 2 - Stage 5: PSA Economic Markov Simulation (Priority: P1)

As an HEOR analyst using HERMES, I need Stage 5 (`simulate_economics()`) to execute a Probabilistic Sensitivity Analysis (PSA) Markov model using transition probability matrices and health-state cost/utility distributions provided by `traj_obj`, returning a standard simulation output compatible with `run_cea()` (Stage 6).

**Why this priority**: Removing `rnorm()` mocks and running true PSA Markov models delivers valid cost-effectiveness estimates (incremental costs, incremental QALYs) required for decision analysis.

**Independent Test**: Testable using a `hermes_trajectories` object. Verify that `simulate_economics()` runs a PSA simulation via `hesim` (or `heemod`) over the specified time horizon and discount rate, returning a `hermes_sim` object containing a `hesim_ce` structure with `costs` and `qalys` data frames formatted for `run_cea()`.

**Acceptance Scenarios**:

1. **Given** a valid `hermes_trajectories` object, **When** `simulate_economics()` is called, **Then** a `hesim` (or `heemod`) PSA Markov model is evaluated over `time_horizon` (default 10 years) and `discount_rate` (default 0.03).
2. **Given** the PSA execution output, **When** formatted into `sim_res$hesim_ce`, **Then** data frames for `costs` and `qalys` contain `sample`, `strategy_id`, and metric columns without using `stats::rnorm()` hardcoded placeholder mocks.
3. **Given** the output `hermes_sim` object, **When** passed into `run_cea()`, **Then** Stage 6 extracts cost (`c`) and effect (`e`) matrices for BCEA decision analysis without error.

---

### User Story 3 - Test Lifecycle & Synthetic Cost Injection Integration (Priority: P1)

As a developer maintaining the HERMES package, I need a standard cost-injection helper script (`setup-mock_costs.R` / `helper-eunomia.R`) integrated into unit and end-to-end (E2E) tests so that DuckDB Eunomia test environments provide realistic financial data for Target, Comparator, and Outcome cohorts natively without mocking data inside package functions.

**Why this priority**: Enables true test-driven development (TDD) where package logic runs natively against DuckDB database tables without hardcoded internal overrides.

**Independent Test**: Run `test-stage4-trajectories.R`, `test-stage5-simulation.R`, and `test-e2e.R` on DuckDB. All tests must pass natively without mocking internal return values.

**Acceptance Scenarios**:

1. **Given** a test execution environment, **When** test helpers initialize the Eunomia database, **Then** synthetic financial data linked to Target, Comparator, and Outcome condition occurrences is injected into the OMOP `COST` table.
2. **Given** updated tests, **When** `devtools::test()` is executed, **Then** all Stage 4, Stage 5, and E2E tests execute natively against DuckDB and pass.

---

### Edge Cases

- **Zero occurrences of outcome cohort**: If patients in the target or comparator cohort do not transition to the outcome state within the observation window, the transition probability matrix MUST set the transition probability to 0 and retain valid state structures.
- **Health state with single cost observation**: If a health state has `n = 1` cost record, standard error MUST be set to 0 (or `NA` handled gracefully) to prevent division by zero or `NaN`.
- **Missing utility parameters**: If QALY/utility data is not present in input CDM, Stage 5 MUST apply standard default health state utilities (e.g., 1.0 for healthy, 0.7 for event state) with appropriate beta/lognormal distribution variation for PSA.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Stage 4 (`compile_trajectories()`) MUST remove hardcoded static transition matrices and implement dynamic transition probability matrix computation using `Cohort2Trajectory` and/or `TrajectoryMarkovAnalysis` over 30-day discrete time steps.
- **FR-002**: Stage 4 (`compile_trajectories()`) MUST filter matched patient cohort IDs from `ps_obj$matched_pop` and group patient-level costs from `ps_obj$hcru_obj$costs` by trajectory health states.
- **FR-003**: Stage 4 (`compile_trajectories()`) MUST compute summary cost statistics per health state, including `mean_cost` and `se_cost` (standard error).
- **FR-004**: Stage 5 (`simulate_economics()`) MUST remove `stats::rnorm()` mock placeholders and construct a true Markov PSA simulation using `hesim` (or `heemod`).
- **FR-005**: Stage 5 (`simulate_economics()`) MUST draw parameter samples (transition probabilities, state costs, state utilities) according to uncertainty distributions (e.g., Dirichlet/Beta for probabilities, Gamma/Lognormal for costs) for PSA samples.
- **FR-006**: Stage 5 (`simulate_economics()`) MUST structure simulation outputs into `hesim_ce` format containing `costs` and `qalys` data frames with columns `sample`, `strategy_id`, and metrics (`costs`, `qalys`) compatible with `run_cea()`.
- **FR-007**: Test fixture helpers MUST inject synthetic financial records into the OMOP `COST` table linked to Target (Colon Polyp), Comparator (Diverticular Disease), and Outcome (GI Bleed) cohorts for test environments.
- **FR-008**: All R code MUST adhere to HERMES code standards: Base R pipes (`|>`), `<-` assignment, `snake_case`, and no inline mock overrides inside package functions.

### Key Entities

- **hermes_ps**: Input object containing matched patient cohorts (`matched_pop`) and extracted patient-level costs (`hcru_obj$costs`).
- **hermes_trajectories**: Output object containing computed transition probability matrices (`matrices`) and health-state grouped cost metrics (`costs`).
- **hermes_sim**: Output object containing economic simulation settings, PSA samples, and structured `hesim_ce` costs/effects matrices.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Stage 4, Stage 5, and E2E unit test suites execute natively on DuckDB without mocked internal package overrides and pass 100% of tests.
- **SC-002**: `compile_trajectories()` outputs transition probability matrices derived dynamically from cohort data and state-grouped costs containing mean and standard error.
- **SC-003**: `simulate_economics()` executes a PSA simulation producing structured `hesim_ce` output consumed by Stage 6 (`run_cea()`) without error.

## Assumptions

- `hesim` and `Cohort2Trajectory` / `TrajectoryMarkovAnalysis` packages (or compatible standard Markov simulation methods) are available in the test and runtime environments.
- The DuckDB Eunomia test fixture allows writing synthetic records to the `cost` table linked to condition occurrences.
