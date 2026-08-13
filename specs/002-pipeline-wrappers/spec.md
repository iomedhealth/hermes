# Feature Specification: Implement Pipeline Wrappers

**Feature Branch**: `002-pipeline-wrappers`

**Created**: 2026-08-13

**Status**: Draft

**Input**: User description: "HERMES: Implementation Handoff & Context. Replace pipeline stubs with actual OHDSI/OMOP clinical logic. Stage 1: Cohort Generation (CDMConnector, omopgenerics). Stage 2: Baseline & HCRU Characterization (PatientProfiles, CohortCharacteristics, OMOP COST table). Stage 3: Causal Propensity Score Adjustment (CohortMethod, Cyclops). Stage 4: Trajectories & State Costs (Cohort2Trajectory, TrajectoryMarkovAnalysis). Stage 5: Economic Simulation (hesim/heemod). Stage 6: CEA Decision Analysis (BCEA)."

## Clarifications
### Session 2026-08-13
- Q: Clarify Eunomia testing dataset → A: Use Eunomia GiBleed dataset for testing

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Stage 1: Cohort Generation (Priority: P1)

As a researcher using the HERMES pipeline, I need to validate that my provided target, comparator, and outcome cohorts exist in the provided OMOP CDM reference, and I need their cohort counts attached to the resulting study object.

**Why this priority**: Cohort generation is the foundational entry point of the pipeline. If cohorts are invalid or cannot be counted, no subsequent stage can execute.

**Independent Test**: Can be tested independently by providing a test `cdm` reference (via the Eunomia DuckDB fixture) and verifying that the `hermes_study` object correctly validates existing cohorts and includes their counts.

**Acceptance Scenarios**:

1. **Given** a valid `cdm` reference with target, comparator, and outcome cohorts, **When** the Stage 1 initialization wrapper is called, **Then** a `hermes_study` object is returned with valid cohort counts attached.
2. **Given** a `cdm` reference missing required cohorts, **When** the Stage 1 initialization wrapper is called, **Then** an appropriate error is thrown indicating missing cohorts.

---

### User Story 2 - Stage 2: Baseline & HCRU Characterization (Priority: P1)

As a researcher, I need to generate baseline demographics and comorbidity tables (Table 1) and extract unadjusted care utilization and direct medical costs directly from the OMOP `COST` table, mapped to my cohorts.

**Why this priority**: Baseline characteristics and unadjusted costs are required for propensity score matching and subsequent economic analysis.

**Independent Test**: Can be tested independently using the `hermes_study` object. Verify that the output `hermes_hcru` object contains the expected demographics, comorbidities, and raw cost queries against the Eunomia fixture.

**Acceptance Scenarios**:

1. **Given** a valid `hermes_study` object, **When** the baseline summarization wrapper is called, **Then** Table 1 data (demographics, comorbidities) is generated.
2. **Given** a valid `hermes_study` object and an underlying CDM with a `COST` table, **When** the HCRU extraction wrapper is called, **Then** unadjusted care utilization and direct medical costs are extracted correctly.

---

### User Story 3 - Stage 3: Causal Propensity Score Adjustment (Priority: P2)

As a researcher, I need to adjust for confounding between my target and comparator cohorts by fitting regularized logistic regression models using baseline features, outputting a matched/weighted population and standardized mean difference (SMD) summaries.

**Why this priority**: Causal inference is central to observational RWE, requiring PS adjustment before trajectories or simulations are performed.

**Independent Test**: Can be tested using a `hermes_hcru` object to verify that the propensity score model fits successfully and outputs valid SMD balance summaries.

**Acceptance Scenarios**:

1. **Given** a valid `hermes_hcru` object, **When** the PS adjustment wrappers are called, **Then** a `hermes_ps` object is returned containing the matched/weighted population and SMD balance diagnostics.

---

### User Story 4 - Stage 4: Trajectories & State Costs (Priority: P2)

As a researcher, I need to aggregate longitudinal patient timelines into discrete health states, calculate transition probability matrices, and group the extracted costs by these health states.

**Why this priority**: Defining transition probabilities and state costs is a prerequisite for running economic simulations.

**Independent Test**: Can be tested using a `hermes_ps` object. Verify that patient timelines are aggregated, transition matrices are generated, and costs are properly grouped by state.

**Acceptance Scenarios**:

1. **Given** a valid `hermes_ps` object, **When** the trajectories wrapper is called, **Then** a `hermes_trajectories` object is returned containing valid transition probability matrices and state-grouped costs.

---

### User Story 5 - Stage 5: Economic Simulation (Priority: P2)

As a researcher, I need to run a probabilistic sensitivity analysis (PSA) or deterministic Markov model using my transition matrices and state costs, which must output large matrices of simulated Costs and Effects across thousands of iterations.

**Why this priority**: The simulation engine produces the core estimates required for cost-effectiveness decision analysis.

**Independent Test**: Can be tested using a `hermes_trajectories` object. Verify that the simulation runs and outputs valid cost and effect matrices.

**Acceptance Scenarios**:

1. **Given** a valid `hermes_trajectories` object, **When** the economic simulation wrapper is called, **Then** a `hermes_sim` object is returned containing simulated cost (`c`) and effect (`e`) matrices.

---

### User Story 6 - Stage 6: CEA Decision Analysis (Priority: P1)

As a researcher, I need to extract the actual simulated cost and effect matrices to run my final Cost-Effectiveness Analysis (CEA), outputting summaries and plots (ICER, NMB, CEAC).

**Why this priority**: This is the final output of the pipeline, providing the actual economic evaluation results replacing the current mocked data.

**Independent Test**: Can be tested using a `hermes_sim` object. Verify that real matrices are extracted and passed to the CEA analysis without relying on mocked data.

**Acceptance Scenarios**:

1. **Given** a valid `hermes_sim` object with real cost and effect matrices, **When** the CEA wrapper is called, **Then** final CEA summaries and plots are generated successfully without the use of mocked data.

### Edge Cases

- **Missing or Empty COST table**: If the OMOP CDM provided lacks a `COST` table or it contains entirely NULL values, the pipeline MUST log a warning and default all cost metrics to 0, allowing the simulation to proceed with 0 cost.
- **Zero Patients in Cohort**: If a target or comparator cohort has zero patients during validation or baseline summarization, the system MUST throw an informative error (e.g., "Cohort [ID] contains 0 patients") and halt execution.
- **Absorbing States & Lost to Follow-up**: Patients who drop out of observation prior to the end of the trajectory timeline or reach an absorbing state early MUST be transitioned into a designated "Censored/Dead" absorbing state for the remainder of the timeline.
- **Missing Concepts in Eunomia**: If specific concepts required for a test cohort are missing in the GiBleed dataset, tests MUST fallback to using the primary GI Bleed concept (e.g., Concept ID 192671) to ensure pipeline execution.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The Stage 1 Cohort Generation wrapper MUST validate the existence of target, comparator, and outcome cohorts in the CDM (throwing an explicit error if any of the cohorts are missing or have 0 patients) and extract their counts using `CDMConnector` and `omopgenerics`.
- **FR-002**: The Stage 2 Baseline wrapper MUST generate baseline demographics (specifically: age, sex, and prior observation time) and comorbidities (specifically: Charlson Comorbidity Index components) using `PatientProfiles` and `CohortCharacteristics`.
- **FR-003**: The Stage 2 HCRU extraction wrapper MUST query raw, unadjusted care utilization (quantified via `visit_occurrence`, `drug_exposure`, and `procedure_occurrence` domain counts) and direct medical costs (specifically extracting `total_charge` and `total_paid` metrics) directly from the OMOP `COST` table utilizing `dplyr`/`dbplyr`.
- **FR-004**: The Stage 3 PS Adjustment wrapper MUST fit regularized logistic regression models using baseline features (defined as conditions and drugs in a 365-day lookback window prior to index date) via `CohortMethod` and `Cyclops` (using default Laplace priors and 10-fold cross-validation for variance selection), and MUST output matched/weighted populations with SMD balance summaries.
- **FR-005**: The Stage 4 Trajectories wrapper MUST aggregate patient timelines into discrete health states (e.g., Initial, State A, State B, Dead) evaluated at 30-day cycle lengths using `Cohort2Trajectory` and `TrajectoryMarkovAnalysis`. The input cohort MUST be filtered to only include the matched cohort IDs from `hermes_ps`. It MUST calculate state-to-state transition probability matrices and group extracted costs by health state.
- **FR-006**: The Stage 5 Economic Simulation wrapper MUST take transition matrices and state costs to run economic simulations (e.g., PSA or deterministic Markov model) using `hesim` or `heemod`, over a default 10-year time horizon with a 3% discount rate, outputting a standard CE object.
- **FR-007**: The Stage 6 CEA Decision Analysis wrapper MUST extract the actual simulated cost and effect arrays from the `hesim` CE object, reshape them into Costs (`c`) and Effects (`e`) matrices of dimensions (iterations × interventions), and pass them into `BCEA::bcea()`, strictly prohibiting the injection of mock data.
- **FR-008**: All implementations MUST strictly use Base R pipes (`|>`) and assignment operators (`<-`).

### Key Entities

- **hermes_study**: Initial cohort and study definition object tracking validated cohorts and counts.
- **hermes_hcru**: Object representing baseline patient profiles, demographics, comorbidities, and raw unadjusted care utilization/costs.
- **hermes_ps**: Object representing the causal adjusted population, containing matched/weighted cohorts and standardized mean difference (SMD) balance diagnostics.
- **hermes_trajectories**: Object representing aggregated longitudinal patient timelines, transition probability matrices, and health state-grouped costs.
- **hermes_sim**: Object holding the outputs of the economic simulation engine, specifically the large matrices of simulated Costs (`c`) and Effects (`e`).
- **hermes_cea**: Object containing final cost-effectiveness analysis summaries, outputs, and plots (ICER, NMB, CEAC).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Each pipeline stage's unit tests MUST execute and pass in under 60 seconds (performance target) when utilizing the Eunomia in-memory DuckDB test fixture. Tests MUST assert expected baseline characteristics for the GiBleed dataset (e.g., target cohort count > 0, non-empty Table 1).
- **SC-002**: The end-to-end (E2E) test suite MUST execute and pass using data flowing from Stage 1 through Stage 6 without the injection of mocked random normal distributions in Stage 6.
- **SC-003**: 100% of the analytical operations mapped in the pipeline stages MUST be executed by wrapping external ecosystem packages (e.g., `CDMConnector`, `PatientProfiles`, `CohortMethod`, `hesim`, `BCEA`). Custom analytical logic (e.g., manual mathematical calculations for propensity scores, transition probabilities, or CEA outputs using `dplyr::mutate`) is prohibited and can be measured via code review.

## Assumptions

- The existing Eunomia DuckDB fixture properly injects synthetic patients, observation periods, and sufficient `COST` table records to allow for the deterministic testing of all 6 stages. Note: specifically targeting the `GiBleed` Eunomia dataset as referenced by CDMConnector.
- The external dependencies (`CDMConnector`, `PatientProfiles`, `CohortCharacteristics`, `CohortMethod`, `Cyclops`, `Cohort2Trajectory`, `TrajectoryMarkovAnalysis`, `hesim`, `heemod`, `BCEA`) are properly installed and compatible with the project environment (R >= 4.1).
- Health states for trajectories (Stage 4) and parameters for economic simulations (Stage 5) can be defined and tested using the synthetic data present in the Eunomia fixture.
