# ponytail: minimal cea wrappers

#' @export
run_cea <- function(hermes_sim) {
  if (is.null(hermes_sim$hesim_ce)) {
    stop("hermes_sim must contain a hesim_ce object")
  }

  # ponytail: xtabs for one-liner reshape without tidyr dependency
  c_mat <- unclass(stats::xtabs(costs ~ sample + strategy_id, data = hermes_sim$hesim_ce$costs))
  e_mat <- unclass(stats::xtabs(qalys ~ sample + strategy_id, data = hermes_sim$hesim_ce$qalys))

  # Clean up xtabs attributes to prevent BCEA warnings
  attr(c_mat, "call") <- NULL
  attr(e_mat, "call") <- NULL

  bcea_res <- BCEA::bcea(e = e_mat, c = c_mat)

  out <- hermes_sim
  out$cea_results <- bcea_res
  class(out) <- c("hermes_cea", class(out))

  return(out)
}

#' @export
plot_ceac <- function(study) BCEA::ceac.plot(study$cea_results)

#' @export
plot_plane <- function(study) BCEA::ceplane.plot(study$cea_results)

#' @export
table_summary <- function(study) summary(study$cea_results)
