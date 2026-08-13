test_that("simulate_economics works and returns hermes_sim", {
  # dummy hermes_trajectories
  traj <- structure(
    list(
      matrices = list(transition = matrix(c(0.8, 0.2, 0.1, 0.9), nrow = 2)),
      costs = data.frame(health_state = c(1, 2), cost = c(100, 200))
    ),
    class = "hermes_trajectories"
  )

  sim_res <- simulate_economics(traj, time_horizon = 10, discount_rate = 0.03)

  expect_s3_class(sim_res, "hermes_sim")
  expect_true(!is.null(sim_res$hesim_ce))
  expect_true(is.data.frame(sim_res$hesim_ce$costs))
  expect_true(is.data.frame(sim_res$hesim_ce$qalys))

  expect_true(all(c("sample", "strategy_id", "costs") %in% colnames(sim_res$hesim_ce$costs)))
  expect_true(all(c("sample", "strategy_id", "qalys") %in% colnames(sim_res$hesim_ce$qalys)))
})
