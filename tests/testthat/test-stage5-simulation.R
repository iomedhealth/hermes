test_that("T009 [US2] simulate_economics performs PSA Markov simulation without mock rnorm", {
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

  expect_true(all(c("sample", "strategy_id", "costs") %in% colnames(sim_res$hesim_ce$costs)))
  expect_true(all(c("sample", "strategy_id", "qalys") %in% colnames(sim_res$hesim_ce$qalys)))

  # Ensure deterministic mock values are replaced
  expect_equal(nrow(sim_res$hesim_ce$costs), 20) # 10 samples * 2 strategies

  # Check that costs are realistically positive and differ between strategies
  avg_target_cost <- mean(sim_res$hesim_ce$costs$costs[sim_res$hesim_ce$costs$strategy_id == 1])
  avg_comp_cost <- mean(sim_res$hesim_ce$costs$costs[sim_res$hesim_ce$costs$strategy_id == 2])
  
  avg_target_qaly <- mean(sim_res$hesim_ce$qalys$qalys[sim_res$hesim_ce$qalys$strategy_id == 1])
  avg_comp_qaly <- mean(sim_res$hesim_ce$qalys$qalys[sim_res$hesim_ce$qalys$strategy_id == 2])
  
  # Target stays in baseline longer (0.1 transition vs 0.2), and baseline is now MORE expensive
  expect_true(avg_target_cost > avg_comp_cost)
  # Target also accumulates more QALYs because baseline utility is higher
  expect_true(avg_target_qaly > avg_comp_qaly)
})
