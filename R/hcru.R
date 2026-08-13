#' Extract HCRU from cost table
#'
#' @param study A hermes_study (or hermes_hcru) object
#' @return A hermes_hcru object with costs data
#' @export
extract_hcru <- function(study) {
  # ponytail: pull unadjusted care utilization and direct medical costs from COST table
  # directly via dbplyr inside the database, collect() at the end to get summary.

  if (!"cost" %in% names(study$cdm)) {
    warning("No 'cost' table found in CDM. Skipping cost extraction.")
    costs <- data.frame()
  } else {
    costs <- study$cdm$cost |>
      dplyr::group_by(.data$cost_domain_id) |>
      dplyr::summarise(
        total_paid = sum(.data$total_paid, na.rm = TRUE),
        total_charge = sum(.data$total_charge, na.rm = TRUE),
        record_count = dplyr::n()
      ) |>
      dplyr::collect()
  }

  res <- c(study, list(costs = costs))
  new_hermes_hcru(res)
}
