# Data Model: Stage 4 (Trajectories) and Stage 5 (Economic Simulation)

## Entity Definitions

### 1. `hermes_trajectories`
An S3 object produced by `compile_trajectories(ps_obj)` representing trajectory analysis and state-cost grouping.

#### Fields
- `ps_obj`: The input `hermes_ps` object containing `matched_pop` and `hcru_obj`.
- `matrices`: A list of transition probability matrices across 30-day cycles:
  - `target_transition`: Matrix ($3 \times 3$ or $2 \times 2$) for target cohort.
  - `comparator_transition`: Matrix ($3 \times 3$ or $2 \times 2$) for comparator cohort.
- `costs`: A data frame of cost statistics grouped by health state:
  - `health_state`: Character/Factor identifier (`"State_Baseline"`, `"State_Outcome"`, `"State_Post"`).
  - `n_patients`: Integer count of patients in health state.
  - `mean_cost`: Numeric mean cost per cycle/state.
  - `se_cost`: Numeric standard error of cost.
- `utilities`: A data frame of utility parameters per health state:
  - `health_state`: Character identifier.
  - `mean_utility`: Numeric QALY weight ($0.0 - 1.0$).
  - `se_utility`: Numeric standard error of utility weight.

---

### 2. `hermes_sim`
An S3 object produced by `simulate_economics(traj_obj, time_horizon, discount_rate)` representing the output of the Markov PSA simulation.

#### Fields
- `traj_obj`: The input `hermes_trajectories` object.
- `time_horizon`: Numeric time horizon in years (default: `10`).
- `discount_rate`: Numeric annual discount rate (default: `0.03`).
- `hesim_ce`: A list containing:
  - `costs`: Data frame with columns:
    - `sample`: Integer PSA iteration number ($1 \dots N$, e.g., 100).
    - `strategy_id`: Integer or Character strategy identifier (`1` / `"Target"`, `2` / `"Comparator"`).
    - `costs`: Numeric total discounted cost for the sample/strategy.
  - `qalys`: Data frame with columns:
    - `sample`: Integer PSA iteration number ($1 \dots N$, e.g., 100).
    - `strategy_id`: Integer or Character strategy identifier (`1` / `"Target"`, `2` / `"Comparator"`).
    - `qalys`: Numeric total discounted QALYs for the sample/strategy.

---

### 3. OMOP `cost` Table Test Schema Extension
Synthetic test records injected into the Eunomia DuckDB fixture.

#### Fields
- `cost_id`: Integer primary key.
- `cost_event_id`: Integer foreign key matching `condition_occurrence_id` or `visit_occurrence_id`.
- `cost_domain_id`: Character domain (`"Condition"`, `"Visit"`, `"Drug"`).
- `cost_type_concept_id`: Integer concept identifier (`32814L`).
- `total_charge`: Numeric total charge amount.
- `total_paid`: Numeric total paid amount.
- `paid_by_payer`: Numeric amount paid by health plan/payer.
- `paid_by_patient`: Numeric copay/out-of-pocket amount.
