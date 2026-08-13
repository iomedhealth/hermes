# Data Model: End-to-End Pipeline Objects & Transitions

## Pipeline S3 Object Flow

```
hermes_study (Stage 1: init)
    │
    ▼
hermes_hcru (Stage 2: summarise_baseline, extract_hcru)
    ├── costs: data.frame (total_paid, total_charge, record_count)
    └── baseline_summary: summarised_result
    │
    ▼
hermes_ps (Stage 3: fit_ps, adjust_ps, assess_balance)
    ├── cm_data: data.frame (subject_id, treatment, age, sex, cohort_start_date)
    ├── model: CyclopsFit object (propensity score model)
    ├── matched_pop: data.frame (subject_id, treatment, propensity_score, cohort_start_date)
    └── smd_summary: data.frame (covariate balance summary)
    │
    ▼
hermes_trajectories (Stage 4: compile_trajectories)
    ├── matrices: list(target_transition = matrix(2x2), comparator_transition = matrix(2x2))
    ├── costs: data.frame (health_state, n_patients, mean_cost, se_cost)
    └── utilities: data.frame (health_state, mean_utility, se_utility)
    │
    ▼
hermes_sim (Stage 5: simulate_economics)
    ├── time_horizon: numeric (e.g. 10 years)
    ├── discount_rate: numeric (e.g. 0.03)
    └── hesim_ce: list(costs = data.frame, qalys = data.frame)
    │
    ▼
hermes_cea (Stage 6: run_cea)
    ├── bcea_obj: bcea object
    ├── summary_table: data.frame (strategy, cost, qaly, icer, nmb)
    ├── ceac_plot: ggplot object
    └── plane_plot: ggplot object
```

## Entity Details

### 1. `cm_data` (Covariate Data in `hermes_ps`)
- **`subject_id`**: integer - OMOP `person_id`
- **`treatment`**: integer - `1` for Target cohort, `0` for Comparator cohort
- **`age`**: numeric - Age at cohort index date
- **`sex`**: character - `"Male"` / `"Female"`
- **`sex_num`**: numeric - Binary encoded sex (`1` for Female, `0` for Male)
- **`cohort_start_date`**: Date - Entry date into target/comparator cohort

### 2. `matched_pop` (Matched Population in `hermes_ps`)
- **`subject_id`**: integer - OMOP `person_id`
- **`treatment`**: integer - `1` for Target, `0` for Comparator
- **`propensity_score`**: numeric - Predicted probability from regularized logistic regression
- **`cohort_start_date`**: Date - Entry date
- **`outcome_date`**: Date (optional) - Index date of outcome occurrence if observed within window

### 3. `matrices` (Transition Probability Matrices in `hermes_trajectories`)
- **`target_transition`**: 2x2 matrix - Row 1: `[p_baseline->baseline, p_baseline->outcome]`, Row 2: `[0, 1]`
- **`comparator_transition`**: 2x2 matrix - Row 1: `[p_baseline->baseline, p_baseline->outcome]`, Row 2: `[0, 1]`

### 4. `costs` (State Costs Summary in `hermes_trajectories`)
- **`health_state`**: character - e.g. `"State_Baseline"`, `"State_Outcome"`
- **`n_patients`**: integer - Count of patients in state
- **`mean_cost`**: numeric - Mean direct medical cost from OMOP `COST` table
- **`se_cost`**: numeric - Standard error of mean cost (`sd / sqrt(n)`)
