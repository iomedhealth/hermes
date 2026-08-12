# API Contract: HERMES Eunomia Test Implementation

## Stage 1: Cohort Generation
```r
#' Initialize HERMES Study
#' @param cdm A cdm_reference object (e.g. from Eunomia)
#' @param target_cohort String name of the target cohort
#' @param comparator_cohort String name of the comparator cohort
#' @param outcome_cohorts Character vector of outcome cohorts
#' @return A hermes_study S3 object
hermes::init(cdm, target_cohort, comparator_cohort, outcome_cohorts = NULL)
```

## Stage 2: Baseline & HCRU
```r
#' Summarise Baseline Characteristics
#' @param study A hermes_study object
#' @return A hermes_study object with populated `baseline_summary`
hermes::summarise_baseline(study)

#' Extract HCRU and Costs
#' @param study A hermes_study object
#' @return A hermes_hcru S3 object
hermes::extract_hcru(study)
```

## Stage 3: Propensity Score Modeling
```r
#' Fit Propensity Score Model
#' @param hcru A hermes_hcru or hermes_study object
#' @return A hermes_ps S3 object with `ps_model`
hermes::fit_ps(hcru)

#' Adjust Cohorts
#' @param ps A hermes_ps object
#' @return A hermes_ps object with `matched_pop`
hermes::adjust_ps(ps)

#' Assess Balance
#' @param ps A hermes_ps object
#' @return A hermes_ps object with `balance_summary`
hermes::assess_balance(ps)
```

## Stage 4: Trajectories & Costs
```r
#' Compile Health State Trajectories
#' @param ps A hermes_ps object
#' @return A hermes_trajectories S3 object
hermes::compile_trajectories(ps)

#' Extract State Costs
#' @param traj A hermes_trajectories object
#' @return A hermes_trajectories object with `state_cost_distributions`
hermes::extract_state_costs(traj)
```

## Stage 5: Economic Simulation
```r
#' Run Economic Simulation
#' @param traj A hermes_trajectories object
#' @return A hermes_sim S3 object
hermes::run_simulation(traj)
```

## Stage 6: Decision Analysis
```r
#' Compute Cost-Effectiveness Analysis
#' @param sim A hermes_sim object
#' @return A hermes_cea S3 object
hermes::compute_cea(sim)

#' Plot Cost-Effectiveness Acceptability Curve (CEAC)
#' @param cea A hermes_cea object
hermes::plot_ceac(cea)

#' Plot Cost-Effectiveness Plane
#' @param cea A hermes_cea object
hermes::plot_plane(cea)

#' Summary Table for CEA
#' @param cea A hermes_cea object
#' @return A dataframe/tibble summary
hermes::table_summary(cea)
```

## Test Fixture Helper
```r
#' Setup Eunomia Test CDM
#' @return A cdm_reference object connected to Eunomia DuckDB instance
hermes_test_cdm()
```