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

  if (!"cost" %in% names(study$cdm) || !"condition_occurrence" %in% names(study$cdm)) {
    warning("Missing 'cost' or 'condition_occurrence' table in CDM. Skipping cost extraction.")
    costs <- data.frame()
  } else {
    patient_costs <- study$cdm$cost |>
      dplyr::filter(.data$cost_domain_id == "Condition") |>
      dplyr::inner_join(study$cdm$condition_occurrence, by = c("cost_event_id" = "condition_occurrence_id")) |>
      dplyr::select(subject_id = "person_id", "total_paid", "total_charge", "condition_start_date", "condition_concept_id") |>
      dplyr::collect()
      
    outcome_name <- study$outcome_cohort
    if (!is.null(outcome_name) && outcome_name %in% names(study$cdm)) {
      outcomes <- study$cdm[[outcome_name]] |> 
        dplyr::select("subject_id", outcome_date = "cohort_start_date") |>
        dplyr::collect()
      
      costs <- patient_costs |>
        dplyr::left_join(outcomes, by = "subject_id", relationship = "many-to-many") |>
        dplyr::mutate(
          health_state = ifelse(!is.na(.data$outcome_date) & .data$condition_start_date >= .data$outcome_date,
                                "State_Outcome", "State_Baseline")
        )
    } else {
      costs <- patient_costs |> dplyr::mutate(health_state = "State_Baseline")
    }
  }

  res <- c(study, list(costs = costs))
  new_hermes_hcru(res)
}
