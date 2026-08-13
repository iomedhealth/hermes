#' Initialize a HERMES study
#'
#' @param cdm A cdm_reference object
#' @param target_cohort Name of the target cohort table
#' @param comparator_cohort Name of the comparator cohort table
#' @param outcome_cohort Name of the outcome cohort table
#'
#' @return A hermes_study object
#' @export
init <- function(cdm, target_cohort, comparator_cohort, outcome_cohort) {
  # ponytail: simple checks, no complex validation yet
  for (cohort_name in c(target_cohort, comparator_cohort, outcome_cohort)) {
    if (!(cohort_name %in% names(cdm))) {
      stop(sprintf("Cohort table '%s' not found in CDM", cohort_name))
    }
  }

  counts <- list()
  for (cohort_name in c(target_cohort, comparator_cohort, outcome_cohort)) {
    c_count <- omopgenerics::cohortCount(cdm[[cohort_name]])
    c_count$cohort_name <- cohort_name
    counts[[cohort_name]] <- c_count
  }

  cohort_counts <- do.call(rbind, counts)

  study <- list(
    cdm = cdm,
    target_cohort = target_cohort,
    comparator_cohort = comparator_cohort,
    outcome_cohort = outcome_cohort,
    cohort_counts = cohort_counts
  )

  new_hermes_study(study)
}
