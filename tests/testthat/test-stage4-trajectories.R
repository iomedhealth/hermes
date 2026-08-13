test_that("compile_trajectories generates matrices and groups costs", {
  # Mock ps_obj
  ps_obj <- structure(
    list(
      matched_pop = data.frame(subject_id = 1, cohort_start_date = as.Date("2020-01-01")),
      hcru_obj = list(costs = data.frame(health_state = "A", cost = 100))
    ),
    class = "hermes_ps"
  )

  traj_obj <- compile_trajectories(ps_obj)

  expect_s3_class(traj_obj, "hermes_trajectories")
  expect_true(!is.null(traj_obj$matrices))
  expect_true(!is.null(traj_obj$costs))
})
