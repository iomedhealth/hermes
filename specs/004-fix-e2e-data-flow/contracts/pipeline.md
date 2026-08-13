# Pipeline API Contract: End-to-End Data Flow

## Stage 3 Functions (`R/ps.R`)

### `fit_ps(hcru_obj, ...)`
- **Input**: A `hermes_hcru` object containing `cdm`, `target_cohort`, `comparator_cohort`.
- **Output**: A `hermes_ps` S3 object containing:
  - `cm_data`: Populated covariate data frame with columns `subject_id`, `treatment`, `age`, `sex`, `sex_num`, `cohort_start_date`.
  - `model`: A fitted `Cyclops` logistic regression model (`CyclopsFit`).
  - `hcru_obj`: The input `hermes_hcru` object.

### `adjust_ps(ps_obj, caliper = 0.2, ...)`
- **Input**: A `hermes_ps` object containing `model` and `cm_data`.
- **Output**: An updated `hermes_ps` S3 object with:
  - `matched_pop`: A data frame of caliper-matched patients with columns `subject_id`, `treatment`, `propensity_score`, `cohort_start_date`.

---

## Stage 4 Functions (`R/trajectories.R`)

### `compile_trajectories(ps_obj)`
- **Input**: A `hermes_ps` object containing `matched_pop` and `hcru_obj$costs`.
- **Output**: A `hermes_trajectories` S3 object containing:
  - `matrices`: Named list of 2x2 transition probability matrices (`target_transition`, `comparator_transition`).
  - `costs`: Data frame of state cost summaries (`health_state`, `n_patients`, `mean_cost`, `se_cost`).

---

## Stage 5 Functions (`R/simulation.R`)

### `simulate_economics(traj_obj, time_horizon = 10, discount_rate = 0.03, n_samples = 100)`
- **Input**: A `hermes_trajectories` object containing non-empty `matrices` and `costs`.
- **Behavior**: Checks that `matrices` and `costs` are non-empty. If empty, throws an error: `stop("Cannot run economic simulation: empty transition matrices or cost summaries in traj_obj. Ensure Stage 3 (PS) and Stage 4 (Trajectories) completed successfully.")`.
- **Output**: A `hermes_sim` S3 object containing `hesim_ce` with `costs` and `qalys` data frames formatted for `run_cea()`.
