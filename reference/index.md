# Package index

## Stage 1: Cohort Generation

Functions for defining and building cohorts.

- [`init()`](init.md) : Initialize a HERMES study (Stage 1: Cohort
  Generation)

## Stage 2: Baseline & HCRU

Descriptive statistics and healthcare resource utilization.

- [`summarise_baseline()`](summarise_baseline.md) : Summarise baseline
  demographics and comorbidities (Stage 2: Baseline)
- [`extract_hcru()`](extract_hcru.md) : Extract Healthcare Resource
  Utilization (HCRU) from OMOP CDM (Stage 2: HCRU)

## Stage 3: Propensity Score

Causal adjustment and matching.

- [`fit_ps()`](fit_ps.md) : Fit Propensity Score Model (Stage 3: Causal
  Adjustment)
- [`adjust_ps()`](adjust_ps.md) : Adjust Propensity Scores (Stage 3:
  Causal Adjustment)
- [`assess_balance()`](assess_balance.md) : Assess Covariate Balance
  (Stage 3: Causal Adjustment)

## Stage 4: Trajectories

State-cost extraction and transitions.

- [`compile_trajectories()`](compile_trajectories.md) : Compile State
  Trajectories and Costs (Stage 4: Trajectory Compilation)

## Stage 5 & 6: Simulation & CEA

Economic simulation and decision analysis.

- [`simulate_economics()`](simulate_economics.md) : Simulate Economic
  Outcomes (Stage 5: Economic Simulation)
- [`run_cea()`](run_cea.md) : Run Cost-Effectiveness Analysis (Stage 6:
  Decision Analysis)
- [`plot_ceac()`](plot_ceac.md) : Plot Cost-Effectiveness Acceptability
  Curve (CEAC)
- [`plot_plane()`](plot_plane.md) : Plot Cost-Effectiveness Plane
- [`table_summary()`](table_summary.md) : Summary Table
