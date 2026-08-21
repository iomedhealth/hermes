#' Initialize an omopHeor study (Stage 1: Cohort Generation)
#'
#' @description
#' `init()` is the entry point for the omopHeor 6-stage pipeline. It takes an existing
#' OMOP Common Data Model (CDM) reference and the names of pre-generated cohort tables,
#' validating their existence and calculating baseline cohort counts.
#'
#' In the context of Health Economics and Outcomes Research (HEOR), this step maps
#' directly to defining the **Treatment Arm** (`target_cohort`), the **Standard of Care Arm**
#' (`comparator_cohort`), and the clinical event or **Health State** of interest (`outcome_cohort`).
#'
#' @param cdm A `cdm_reference` object created by `CDMConnector::cdmFromCon()`.
#' @param target_cohort A string specifying the name of the target cohort table in the CDM.
#' @param comparator_cohort A string specifying the name of the comparator cohort table in the CDM.
#' @param outcome_cohort A string specifying the name of the outcome cohort table in the CDM.
#'
#' @return An `omopheor_study` (`hermes_study`) S3 object containing the CDM reference and cohort metadata,
#' ready to be piped into `summarise_baseline()`.
#'
#' @seealso
#' `vignette("intro-to-heor")` for a mapping between OMOP cohorts and HEOR concepts.
#'
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
