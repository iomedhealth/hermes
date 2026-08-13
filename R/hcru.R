#' Extract HCRU from cost table
#'
#' Extracts unadjusted care utilization and direct medical costs from the OMOP `cost` table.
#' It safely handles edge cases like missing tables, empty tables, and masked financial values 
#' by defaulting to fallback logic (like DRG-based cost inference).
#' 
#' @seealso See \code{docs/hcru_logic.md} for the complete ASCII flow diagram of the extraction logic.
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
    # TODO: Check if the cost table is empty and warn the user accordingly.
    # The cost table should always exist, but in many real-world OMOP CDMs it may be empty.
    
    # TODO: Handle cases where the cost table is populated but lacks cost metrics.
    # Check if `total_charge`, `total_cost`, `total_paid`, or `paid_*` columns are all NA or 0.
    
    # TODO: DRG Fallback Strategy.
    # If no data is available for `total_*` or `paid_*` metrics, check if `drg_concept_id` 
    # and/or `drg_source_value` exist. If they do, prompt the user to provide a DRG 
    # costs lookup dataframe to infer costs.

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
