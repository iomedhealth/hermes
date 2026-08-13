#' Compile Trajectories
#'
#' @param ps_obj A hermes_ps object
#' @export
compile_trajectories <- function(ps_obj) {
  # ponytail: minimal dynamic matrix derivation and cost aggregation
  # skipped: full Cohort2Trajectory pipeline. Add when real event table integration is needed.

  matrices <- list()
  costs_summary <- data.frame()

  if (!is.null(ps_obj$matched_pop) && is.data.frame(ps_obj$matched_pop)) {
    pop <- ps_obj$matched_pop

    # Calculate transition probabilities
    calc_trans <- function(df) {
      if (nrow(df) == 0) {
        return(matrix(c(1, 0, 0, 1),
          nrow = 2, byrow = TRUE,
          dimnames = list(
            c("State_Baseline", "State_Outcome"),
            c("State_Baseline", "State_Outcome")
          )
        ))
      }

      n_total <- nrow(df)
      if ("outcome_date" %in% colnames(df)) {
        has_outcome <- !is.na(df$outcome_date)
        days_to_outcome <- as.numeric(difftime(df$outcome_date, df$cohort_start_date, units = "days"))
        n_outcome_30d <- sum(has_outcome & days_to_outcome <= 30, na.rm = TRUE)
      } else {
        n_outcome_30d <- 0
      }

      p_outcome <- n_outcome_30d / n_total
      p_baseline <- 1 - p_outcome

      matrix(
        c(
          p_baseline, p_outcome,
          0, 1
        ),
        nrow = 2, byrow = TRUE,
        dimnames = list(
          c("State_Baseline", "State_Outcome"),
          c("State_Baseline", "State_Outcome")
        )
      )
    }

    if ("treatment" %in% colnames(pop)) {
      target_pop <- pop[pop$treatment == 1, ]
      comp_pop <- pop[pop$treatment == 0, ]
    } else {
      target_pop <- pop
      comp_pop <- pop[0, ]
    }

    matrices$target_transition <- calc_trans(target_pop)
    matrices$comparator_transition <- calc_trans(comp_pop)

    # Cost aggregation
    if (!is.null(ps_obj$hcru_obj$costs)) {
      costs <- ps_obj$hcru_obj$costs
      if (nrow(costs) > 0 && "total_paid" %in% colnames(costs)) {
        if (!"health_state" %in% colnames(costs)) {
          costs$health_state <- "State_Baseline"
        }

        costs_summary <- as.data.frame(
          costs |>
            dplyr::group_by(.data$health_state) |>
            dplyr::summarise(
              n_patients = dplyr::n(),
              mean_cost = mean(.data$total_paid, na.rm = TRUE),
              sd_cost = stats::sd(.data$total_paid, na.rm = TRUE),
              .groups = "drop"
            ) |>
            dplyr::mutate(
              se_cost = ifelse(.data$n_patients > 1, .data$sd_cost / sqrt(.data$n_patients), 0)
            ) |>
            dplyr::select("health_state", "n_patients", "mean_cost", "se_cost")
        )
      }
    }
  }

  structure(
    list(
      ps_obj = ps_obj,
      matrices = matrices,
      costs = costs_summary,
      utilities = data.frame()
    ),
    class = "hermes_trajectories"
  )
}
