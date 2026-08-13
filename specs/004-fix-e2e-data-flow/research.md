# Research & Architectural Decisions: Fix End-to-End Pipeline Data Flow

## 1. Stage 3 Baseline Covariate Extraction & Propensity Score Fitting

### Context
`fit_ps()` in `R/ps.R` expected `hcru_obj$cm_data` to be pre-populated, but no function in HERMES called `CohortMethod::getDbCohortMethodData()` or extracted covariates from the CDM. As a result, `cm_data` remained `NULL`, skipping model fitting and producing `matched_pop = NA`.

### Decision
- **Extraction Mechanism**: In `fit_ps()`, if `hcru_obj$cm_data` is not explicitly provided, HERMES automatically extracts patient baseline demographics (`age`, `sex`) from the CDM reference using `PatientProfiles::addAge()` and `PatientProfiles::addSex()` for both the target (`treatment = 1`) and comparator (`treatment = 0`) cohorts.
- **Model Fitting**: HERMES builds a `Cyclops` logistic regression model via `Cyclops::createCyclopsData(treatment ~ age + sex_num, modelType = "lr", data = covariate_df)` and fits it using `Cyclops::fitCyclopsModel()`. Predicted propensity scores are attached as `propensity_score`.
- **CohortMethod Compatibility**: If `CohortMethod` is installed and a `CohortMethodData` object is passed in `cm_data`, `CohortMethod::createPs()` is used as a fallback path.
- **Matching (`adjust_ps`)**: Matches patients on propensity score within a specified caliper (default 0.2), returning a non-empty `matched_pop` data frame containing `subject_id`, `treatment`, `cohort_start_date`, and `propensity_score`.

## 2. Stage 4 Trajectory & State-Cost Compilation

### Context
When `matched_pop` was `NA`, `compile_trajectories()` silently generated empty `matrices` and `costs` structures without signaling upstream failures.

### Decision
- **Population Validation**: `compile_trajectories()` checks if `ps_obj$matched_pop` is a valid data frame with at least one row.
- **Transition Probability Calculation**: For target and comparator sub-populations in `matched_pop`, `compile_trajectories()` calculates 30-day transition probabilities into `State_Baseline` and `State_Outcome` based on `cohort_start_date` and outcome dates.
- **State Cost Aggregation**: Groups patient costs from `ps_obj$hcru_obj$costs` by health state and calculates `mean_cost`, `sd_cost`, and `se_cost` (`sd / sqrt(n)`).

## 3. Removal of Silent Fallbacks in Stage 5

### Context
`simulate_economics()` in `R/simulation.R` had hardcoded fallback logic that injected mock transition matrices (`c(0.9, 0.1, 0, 1)`) and dummy costs (`500` / `100`) whenever `traj_obj$matrices` or `traj_obj$costs` were empty. This masked pipeline breakage in tests.

### Decision
- **Fail-Fast Enforcement**: Remove hardcoded default fallbacks from `simulate_economics()`.
- **Validation Error**: If `traj_obj$matrices` is empty or `traj_obj$costs` has zero rows, `simulate_economics()` raises an explicit error: `stop("Cannot run economic simulation: empty transition matrices or cost summaries in traj_obj. Ensure Stage 3 (PS) and Stage 4 (Trajectories) completed successfully.")`.

## 4. End-to-End Pipeline Verification (`test-e2e.R`)

### Context
`test-e2e.R` previously passed because `simulate_economics()` substituted dummy fallbacks when Stage 3 failed silently.

### Decision
- **Strict Pipeline Assertions**:
  - `expect_false(is.null(study$cm_data))`
  - `expect_false(is.null(study$model))`
  - `expect_true(is.data.frame(study$matched_pop))`
  - `expect_gt(nrow(study$matched_pop), 0)`
  - `expect_gt(length(study$matrices), 0)`
  - `expect_false(is.null(p_ceac))`
  - `expect_false(is.null(p_plane))`
- **Verification**: Run `test-e2e.R` against DuckDB Eunomia to confirm end-to-end execution on real database records without fallback intervention.
