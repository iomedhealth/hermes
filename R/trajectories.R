#' Compile Trajectories
#'
#' @param ps_obj A hermes_ps object
#' @export
compile_trajectories <- function(ps_obj) {
  # ponytail: minimal Cohort2Trajectory and TrajectoryMarkovAnalysis wrapper
  # skipped: actual DB execution of Cohort2Trajectory. Add when fully integrated.

  matrices <- list()
  costs <- data.frame()

  if (!is.null(ps_obj$matched_pop)) {
    # 30-day cycle lengths and matched ID filtering
    # In a full implementation, Cohort2Trajectory::... and TrajectoryMarkovAnalysis::... are called here.
    matrices <- list(
      transition = matrix(c(0.8, 0.2, 0.1, 0.9), nrow = 2)
    )

    if (!is.null(ps_obj$hcru_obj$costs)) {
      # Group extracted costs by health state
      # ponytail: dummy assign health_state for grouping as full mapping isn't implemented
      costs <- ps_obj$hcru_obj$costs
      if (!"health_state" %in% colnames(costs)) {
        costs$health_state <- character(nrow(costs))
        if (nrow(costs) > 0) costs$health_state <- "A"
      }
      costs <- costs |> dplyr::group_by(health_state)
    }
  }

  structure(
    list(
      ps_obj = ps_obj,
      matrices = matrices,
      costs = costs
    ),
    class = "hermes_trajectories"
  )
}
