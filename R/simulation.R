#' Simulate Economics
#'
#' @param traj_obj A hermes_trajectories object
#' @param time_horizon Time horizon in years. Default is 10.
#' @param discount_rate Discount rate. Default is 0.03.
#' @export
simulate_economics <- function(traj_obj, time_horizon = 10, discount_rate = 0.03) {
  # ponytail: mocked hesim/heemod simulation wrapper
  # skipped: actual hesim/heemod PSA logic. Add when transition matrices are fully dynamic.

  samples <- 100

  costs_df <- data.frame(
    sample = rep(1:samples, 2),
    strategy_id = rep(1:2, each = samples),
    costs = c(stats::rnorm(samples, 10000, 1000), stats::rnorm(samples, 12000, 1000))
  )

  qalys_df <- data.frame(
    sample = rep(1:samples, 2),
    strategy_id = rep(1:2, each = samples),
    qalys = c(stats::rnorm(samples, 5, 0.5), stats::rnorm(samples, 5.5, 0.5))
  )

  structure(
    list(
      traj_obj = traj_obj,
      time_horizon = time_horizon,
      discount_rate = discount_rate,
      hesim_ce = list(
        costs = costs_df,
        qalys = qalys_df
      )
    ),
    class = "hermes_sim"
  )
}
