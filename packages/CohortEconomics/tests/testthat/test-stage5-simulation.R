test_that("T009 [US3] simulate_economics performs PSA Markov simulation without mock fallbacks", {
  # dummy hermes_trajectories
  matrices <- list(
    target_transition = matrix(c(0.9, 0.1, 0, 1),
      nrow = 2, byrow = TRUE,
      dimnames = list(
        c("State_Baseline", "State_Outcome"),
        c("State_Baseline", "State_Outcome")
      )
    ),
    comparator_transition = matrix(c(0.8, 0.2, 0, 1),
      nrow = 2, byrow = TRUE,
      dimnames = list(
        c("State_Baseline", "State_Outcome"),
        c("State_Baseline", "State_Outcome")
      )
    )
  )

  costs <- data.frame(
    health_state = c("State_Baseline", "State_Outcome"),
    n_patients = c(10, 10),
    mean_cost = c(500, 100),
    se_cost = c(50, 10)
  )

  utilities <- data.frame(
    health_state = c("State_Baseline", "State_Outcome"),
    mean_utility = c(0.85, 0.70),
    se_utility = c(0.05, 0.05)
  )

  traj <- structure(
    list(
      matrices = matrices,
      costs = costs,
      utilities = utilities
    ),
    class = "hermes_trajectories"
  )

  # Run simulation
  set.seed(42)
  sim_res <- simulate_economics(traj, time_horizon = 5, discount_rate = 0.03, n_samples = 10)

  expect_s3_class(sim_res, "hermes_sim")
  expect_true(!is.null(sim_res$hesim_ce))
  expect_true(is.data.frame(sim_res$hesim_ce$costs))
  expect_true(is.data.frame(sim_res$hesim_ce$qalys))
})

test_that("T010 [US3] simulate_economics fails fast on empty inputs", {
  traj <- structure(
    list(
      matrices = list(),
      costs = data.frame()
    ),
    class = "hermes_trajectories"
  )

  expect_error(
    simulate_economics(traj, time_horizon = 5, discount_rate = 0.03, n_samples = 10),
    "Cannot run economic simulation: empty transition matrices or cost summaries"
  )
})
