#' Summarise baseline demographics and comorbidities
#'
#' @param study A hermes_study object
#' @return A hermes_hcru object with baseline_summary
#' @export
summarise_baseline <- function(study) {
  # ponytail: use CohortCharacteristics directly, demographics=TRUE handles age/sex.
  # We summarize both target and comparator if they exist.

  target_cohort_name <- study$target_cohort
  target_cohort <- study$cdm[[target_cohort_name]]

  # Add demographics using PatientProfiles
  target_profiled <- target_cohort |>
    PatientProfiles::addDemographics() |>
    dplyr::compute(name = "target_profiled_temp", temporary = FALSE, overwrite = TRUE)

  target_profiled_cohort <- omopgenerics::newCohortTable(table = target_profiled)

  baseline_summary <- CohortCharacteristics::summariseCharacteristics(
    cohort = target_profiled_cohort,
    demographics = TRUE
  )

  res <- c(study, list(baseline_summary = baseline_summary))
  new_hermes_hcru(res)
}
