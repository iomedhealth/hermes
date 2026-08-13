# Interface Contract: Trajectories and Simulation Pipeline Wrappers

## Stage 4 Contract: `compile_trajectories`

### Signature
```R
compile_trajectories <- function(ps_obj)
```

### Input
- `ps_obj`: S3 object of class `hermes_ps`. MUST contain:
  - `ps_obj$matched_pop`: Data frame or tbl containing matched cohort patient records.
  - `ps_obj$hcru_obj$costs`: Data frame or tbl containing patient-level cost records extracted from OMOP `COST` table.

### Output
- S3 object of class `hermes_trajectories`:
  - `ps_obj`: Input `hermes_ps` object.
  - `matrices`: Named list containing `target_transition` and `comparator_transition` transition probability matrices.
  - `costs`: Data frame containing `health_state`, `mean_cost`, and `se_cost`.
  - `utilities`: Data frame containing `health_state`, `mean_utility`, and `se_utility`.

---

## Stage 5 Contract: `simulate_economics`

### Signature
```R
simulate_economics <- function(traj_obj, time_horizon = 10, discount_rate = 0.03, n_samples = 100)
```

### Input
- `traj_obj`: S3 object of class `hermes_trajectories`.
- `time_horizon`: Numeric years (default: `10`).
- `discount_rate`: Numeric annual discount rate (default: `0.03`).
- `n_samples`: Integer number of PSA simulation draws (default: `100`).

### Output
- S3 object of class `hermes_sim`:
  - `traj_obj`: Input `hermes_trajectories` object.
  - `time_horizon`: Numeric time horizon.
  - `discount_rate`: Numeric discount rate.
  - `hesim_ce`: List with `costs` and `qalys` data frames compatible with `run_cea()`:
    - `costs`: `sample` (integer), `strategy_id` (integer or character), `costs` (numeric).
    - `qalys`: `sample` (integer), `strategy_id` (integer or character), `qalys` (numeric).
