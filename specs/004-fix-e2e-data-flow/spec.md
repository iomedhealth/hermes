# Feature Specification: Fix End-to-End Pipeline Data Flow & Remove Silent Fallbacks

**Feature Branch**: `004-fix-e2e-data-flow`

**Created**: Thu Aug 13 2026

**Status**: Draft

**Input**: User description: "Fix the Silent Fallback Cascade in End-to-End Pipeline: Ensure CohortMethod::getDbCohortMethodData is called in Stage 3 to extract real CDM covariates, propagate real propensity scores and matched populations to Stage 4 trajectories and Stage 5 economic simulations, remove silent mock fallbacks, and verify that test-e2e.R passes on actual CDM data."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Stage 2-to-3 Causal Data Bridge (Propensity Score Model Fitting on Real CDM Covariates) (Priority: P1)

As an RWE researcher, I need Stage 3 (`fit_ps()` / `adjust_ps()`) to extract baseline covariates from the CDM database using `CohortMethod::getDbCohortMethodData()` and fit a propensity score model so that comparative cohorts are properly matched on real patient data.

**Why this priority**: Without real covariate extraction and propensity score fitting, downstream stages receive unpopulated or invalid patient data, breaking the core causal inference capabilities of HERMES.

**Independent Test**: Can be tested by passing a `hermes_hcru` object containing valid target and comparator cohort tables in DuckDB/Eunomia to `fit_ps()` and verifying that `ps_obj$cm_data` contains `CohortMethodData` and `ps_obj$model` contains a fitted Cyclops model.

**Acceptance Scenarios**:

1. **Given** an initialized HERMES study with target, comparator, and outcome cohorts in an OMOP CDM, **When** `fit_ps()` is called, **Then** `CohortMethod::getDbCohortMethodData()` is invoked to extract baseline covariates and fit a regularized logistic regression propensity score model.
2. **Given** a fitted propensity score model in `ps_obj$model`, **When** `adjust_ps()` is executed, **Then** patients are matched on propensity score caliper and a non-empty matched population data frame is returned in `ps_obj$matched_pop`.

---

### User Story 2 - Stage 3-to-4 Trajectory & State-Cost Data Propagation (Priority: P2)

As an HEOR analyst, I need Stage 4 (`compile_trajectories()`) to receive valid matched patient populations and cost data to compute dynamic transition probability matrices and state costs without relying on mock data fallbacks.

**Why this priority**: Trajectory compilation must accurately compute patient transition matrices and state costs from real matched cohorts rather than returning empty objects that trigger downstream mock fallbacks.

**Independent Test**: Can be tested by passing a `hermes_ps` object with a populated `matched_pop` data frame and `costs` data frame to `compile_trajectories()` and verifying that `matrices` and `costs` summaries reflect the matched population statistics.

**Acceptance Scenarios**:

1. **Given** a valid matched population from Stage 3 and extracted patient costs from Stage 2, **When** `compile_trajectories()` is executed, **Then** dynamic state transition matrices and state cost summaries are generated directly from the matched patient records.

---

### User Story 3 - Fail-Fast Pipeline Verification & Integration Testing (Priority: P3)

As a pipeline developer, I need Stage 5 (`simulate_economics()`) to fail fast when provided with empty or unpopulated trajectory data instead of silently substituting hardcoded fallbacks, ensuring that `test-e2e.R` accurately validates real pipeline execution.

**Why this priority**: Eliminating silent fallbacks ensures test failures accurately reflect broken data pipelines rather than disguising errors behind hardcoded mock defaults.

**Independent Test**: Can be tested by executing `test-e2e.R` against Eunomia DuckDB and verifying that all stages (1 through 6) execute on real database data and produce non-empty results without triggering fallback logic.

**Acceptance Scenarios**:

1. **Given** empty or unpopulated trajectory matrices or state cost inputs, **When** `simulate_economics()` is called, **Then** an explicit error or warning is raised rather than silently injecting hardcoded mock defaults.
2. **Given** a full pipeline run in `test-e2e.R`, **When** executed against Eunomia synthetic test database, **Then** all stages execute end-to-end on real database records and produce valid CEA plots without triggering fallback defaults.

---

### Edge Cases

- What happens when `CohortMethod::getDbCohortMethodData()` fails to extract covariates (e.g. zero covariates found for small cohorts)? System MUST raise an informative error explaining that propensity score fitting cannot proceed due to insufficient baseline covariates.
- What happens when matching produces zero matched pairs (caliper too restrictive)? `adjust_ps()` MUST return an empty data frame with expected column headers and downstream functions MUST report zero matched patients rather than silently generating mock fallbacks.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Stage 3 (`fit_ps()`) MUST extract baseline covariates from the CDM using `CohortMethod::getDbCohortMethodData()` based on the target, comparator, and outcome cohort definitions in `hermes_study`.
- **FR-002**: Stage 3 (`fit_ps()`) MUST fit a propensity score model using the extracted `CohortMethodData` and store it in `ps_obj$model`.
- **FR-003**: Stage 3 (`adjust_ps()`) MUST perform patient matching on propensity scores and output a valid matched patient population data frame in `ps_obj$matched_pop`.
- **FR-004**: Stage 4 (`compile_trajectories()`) MUST filter matched patient cohorts from `ps_obj$matched_pop` to compute dynamic transition probability matrices across defined cycle windows.
- **FR-005**: Stage 5 (`simulate_economics()`) MUST remove silent fallback defaults for empty matrices/costs and raise explicit errors when mandatory trajectory inputs are missing or unpopulated.
- **FR-006**: The end-to-end integration test (`test-e2e.R`) MUST pass asserting valid non-empty data objects across all pipeline stages (`cm_data`, `model`, `matched_pop`, `matrices`, `costs`, `hesim_ce`).

### Key Entities

- **CohortMethodData**: An OHDSI `CohortMethodData` object containing extracted baseline covariates, treatment assignments, and cohort timings.
- **hermes_ps**: An S3 object containing the fitted propensity score model (`model`), extracted covariate data (`cm_data`), and matched population table (`matched_pop`).
- **hermes_trajectories**: An S3 object containing dynamic state transition matrices (`matrices`) and state cost summaries (`costs`) computed from matched cohorts.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of pipeline stages in `test-e2e.R` process actual CDM records from Eunomia without invoking fallback mock default values.
- **SC-002**: Stage 3 propensity score adjustment outputs a non-empty matched population data frame with calculated propensity score values and treatment flags.
- **SC-003**: Upstream failures in Stage 3 or Stage 4 cause downstream pipeline stages to fail loudly with informative error messages instead of passing silently.

## Assumptions

- Eunomia synthetic CDM database (DuckDB) contains target and comparator patient records with sufficient demographic and clinical history to extract baseline covariates via `FeatureExtraction::createDefaultCovariateSettings()`.
- `CohortMethod` and `Cyclops` packages are installed and compatible with DuckDB / CDMConnector reference objects.
