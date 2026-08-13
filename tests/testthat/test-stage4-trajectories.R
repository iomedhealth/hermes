test_that("T005 [US1] compile_trajectories generates dynamic matrices and cost summary", {
  matched_pop <- data.frame(
    subject_id = c(1, 2, 3),
    cohort_start_date = as.Date(c("2020-01-01", "2020-01-01", "2020-01-01")),
    treatment = c(1, 1, 0), # 1 for target, 0 for comparator
    outcome_date = as.Date(c(NA, "2020-01-15", "2020-02-15"))
  )

  costs_df <- data.frame(
    health_state = c("State_Baseline", "State_Outcome", "State_Baseline"),
    total_paid = c(100, 500, 150)
  )

  ps_obj <- structure(
    list(
      matched_pop = matched_pop,
      hcru_obj = list(costs = costs_df)
    ),
    class = "hermes_ps"
  )

  traj_obj <- compile_trajectories(ps_obj)

  expect_s3_class(traj_obj, "hermes_trajectories")
  expect_true(!is.null(traj_obj$matrices))
  expect_true("target_transition" %in% names(traj_obj$matrices))
  expect_true("comparator_transition" %in% names(traj_obj$matrices))

  expect_true(is.data.frame(traj_obj$costs))
  expect_true(all(c("health_state", "n_patients", "mean_cost", "se_cost") %in% colnames(traj_obj$costs)))

  # Check stats
  baseline_costs <- traj_obj$costs[traj_obj$costs$health_state == "State_Baseline", ]
  expect_equal(baseline_costs$mean_cost, mean(c(100, 150)))

  outcome_costs <- traj_obj$costs[traj_obj$costs$health_state == "State_Outcome", ]
  expect_equal(outcome_costs$mean_cost, 500)
  expect_equal(outcome_costs$se_cost, 0) # Fallback to 0 if n <= 1
})
