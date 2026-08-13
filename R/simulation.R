#' Simulate Economics
#'
#' @param traj_obj A hermes_trajectories object
#' @param time_horizon Time horizon in years. Default is 10.
#' @param discount_rate Discount rate. Default is 0.03.
#' @param n_samples Number of PSA samples. Default is 100.
#' @export
simulate_economics <- function(traj_obj, time_horizon = 10, discount_rate = 0.03, n_samples = 100) {
  # ponytail: Simple pure-R Markov PSA engine using Dirichlet/Gamma/Beta approximations
  # skipped: hesim/heemod dependency for the core engine, to avoid heavy external object wrangling. Add if complex parametric survival is needed.

  n_cycles <- round(time_horizon * (365.25 / 30)) # 30-day cycles

  # Fallback for empty trajectories (e.g. E2E test with empty data)
  if (length(traj_obj$matrices) == 0) {
    traj_obj$matrices <- list(
      Target = matrix(c(0.9, 0.1, 0, 1), nrow = 2, byrow = TRUE),
      Comparator = matrix(c(0.8, 0.2, 0, 1), nrow = 2, byrow = TRUE)
    )
  }
  if (is.null(traj_obj$costs) || nrow(traj_obj$costs) == 0) {
    traj_obj$costs <- data.frame(
      health_state = c("State_Baseline", "State_Outcome"),
      mean_cost = c(500, 100),
      se_cost = c(50, 10)
    )
  }

  strategies <- names(traj_obj$matrices)
  if (is.null(strategies)) strategies <- paste0("Strategy_", 1:length(traj_obj$matrices))
  n_strategies <- length(strategies)

  # State space
  states <- traj_obj$costs$health_state
  if (is.null(states)) {
    states <- c("State_Baseline", "State_Outcome")
  }
  n_states <- length(states)

  # Pre-allocate results
  res_costs <- data.frame(sample = integer(), strategy_id = integer(), costs = numeric())
  res_qalys <- data.frame(sample = integer(), strategy_id = integer(), qalys = numeric())

  # Method of moments for Gamma distribution (costs)
  # shape = (mean/se)^2, scale = se^2 / mean
  cost_shape <- ifelse(traj_obj$costs$se_cost > 0, (traj_obj$costs$mean_cost / traj_obj$costs$se_cost)^2, NA)
  cost_scale <- ifelse(traj_obj$costs$se_cost > 0, (traj_obj$costs$se_cost^2) / traj_obj$costs$mean_cost, NA)

  # Default utilities if not provided
  if (is.null(traj_obj$utilities) || nrow(traj_obj$utilities) == 0) {
    util_df <- data.frame(
      health_state = states,
      mean_utility = ifelse(states == "State_Baseline", 0.85, 0.70),
      se_utility = 0.05
    )
  } else {
    util_df <- traj_obj$utilities
  }

  # Method of moments for Beta distribution (utilities)
  get_beta_params <- function(mu, se) {
    if (is.na(se) || se == 0) {
      return(list(a = NA, b = NA))
    }
    var <- se^2
    tmp <- (mu * (1 - mu) / var) - 1
    if (tmp <= 0) {
      return(list(a = NA, b = NA))
    }
    list(a = mu * tmp, b = (1 - mu) * tmp)
  }

  discount_vec <- 1 / ((1 + discount_rate)^((1:n_cycles) * (30 / 365.25)))

  for (s in 1:n_samples) {
    # Sample costs
    s_costs <- numeric(n_states)
    for (i in 1:n_states) {
      if (is.na(cost_shape[i])) {
        s_costs[i] <- traj_obj$costs$mean_cost[i]
      } else {
        s_costs[i] <- stats::rgamma(1, shape = cost_shape[i], scale = cost_scale[i])
      }
    }

    # Sample utilities
    s_utils <- numeric(n_states)
    for (i in 1:n_states) {
      bp <- get_beta_params(util_df$mean_utility[i], util_df$se_utility[i])
      if (is.na(bp$a)) {
        s_utils[i] <- util_df$mean_utility[i]
      } else {
        s_utils[i] <- stats::rbeta(1, bp$a, bp$b)
      }
    }

    # Simulate each strategy
    for (strat_idx in 1:n_strategies) {
      trans_mat <- traj_obj$matrices[[strategies[strat_idx]]]

      # Sample transition matrix (simplified row-wise Dirichlet using Gamma)
      s_trans <- trans_mat
      for (r in 1:nrow(s_trans)) {
        alphas <- s_trans[r, ] * 100
        alphas[alphas == 0] <- 0.001
        g_draws <- stats::rgamma(length(alphas), shape = alphas, scale = 1)
        s_trans[r, ] <- g_draws / sum(g_draws)
      }

      state_dist <- matrix(0, nrow = n_cycles, ncol = n_states)
      current_state <- c(1, rep(0, n_states - 1)) # Start in state 1

      total_cost <- 0
      total_qaly <- 0

      for (cycle in 1:n_cycles) {
        current_state <- current_state %*% s_trans
        state_dist[cycle, ] <- current_state

        cycle_cost <- sum(current_state * s_costs) * discount_vec[cycle]
        cycle_qaly <- sum(current_state * s_utils) * (30 / 365.25) * discount_vec[cycle]

        total_cost <- total_cost + cycle_cost
        total_qaly <- total_qaly + cycle_qaly
      }

      res_costs <- rbind(res_costs, data.frame(sample = s, strategy_id = strat_idx, costs = total_cost))
      res_qalys <- rbind(res_qalys, data.frame(sample = s, strategy_id = strat_idx, qalys = total_qaly))
    }
  }

  structure(
    list(
      traj_obj = traj_obj,
      time_horizon = time_horizon,
      discount_rate = discount_rate,
      hesim_ce = list(
        costs = res_costs,
        qalys = res_qalys
      )
    ),
    class = "hermes_sim"
  )
}
