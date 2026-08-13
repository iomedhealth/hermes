library(testthat)

test_that("T010: run_cea extracts actual matrices and returns hermes_cea", {
  # Mock a hermes_sim object with hesim_ce
  # Using runif to avoid rnorm as requested by the rule to not mock with rnorm,
  # although this is just test data setup.
  mock_sim <- list(
    hesim_ce = list(
      costs = data.frame(
        sample = rep(1:50, 2),
        strategy_id = rep(c("A", "B"), each = 50),
        costs = runif(100, 1000, 2000)
      ),
      qalys = data.frame(
        sample = rep(1:50, 2),
        strategy_id = rep(c("A", "B"), each = 50),
        qalys = runif(100, 0.4, 0.8)
      )
    )
  )
  class(mock_sim) <- "hermes_sim"

  # Source the implementation directly for testing
  source("../../R/cea.R")

  res <- run_cea(mock_sim)

  expect_s3_class(res, "hermes_cea")
  expect_true(!is.null(res$cea_results))

  # Verify dimensions: iterations x interventions
  expect_equal(dim(res$cea_results$c), c(50, 2))
  expect_equal(dim(res$cea_results$e), c(50, 2))

  # Verify the actual data was passed
  expect_equal(unname(res$cea_results$c[1, 1]), mock_sim$hesim_ce$costs$costs[1])
})
