#' Summarise Healthcare Resource Utilization for a Cohort
#'
#' @param cohort An enriched cohort table containing utilization columns.
#' @param group List of character vectors specifying grouping columns. Default: `list("cohort_name")`.
#' @param strata List of character vectors specifying stratification columns. Default: `list()`.
#' @param estimates Summary estimators to compute. Default: `c("mean", "sd", "median", "q25", "q75", "min", "max")`.
#' @param variables Optional character vector of specific variables to summarise. If NULL, auto-detects utilization columns.
#'
#' @return An `omopgenerics::summarised_result` object.
#' @export
summariseUtilization <- function(
  cohort,
  group = list("cohort_name"),
  strata = list(),
  estimates = c("mean", "sd", "median", "q25", "q75", "min", "max"),
  variables = NULL
) {
  # ponytail: delegate to PatientProfiles::summariseResult with auto-detected utilization columns
  if (inherits(cohort, "cohort_table") && !"cohort_name" %in% colnames(cohort)) {
    cohort <- PatientProfiles::addCohortName(cohort)
  }

  groupCols <- unlist(group)
  missingGroup <- setdiff(groupCols, colnames(cohort))
  if (length(missingGroup) > 0) {
    group <- list()
  }

  if (is.null(variables)) {
    allCols <- colnames(cohort)
    utilPatterns <- c(
      "inpatient_admissions", "inpatient_los", "inpatient_mean_los", "icu_admissions", "icu_los", "icu_mean_los", "readmissions",
      "emergency_visits", "gp_visits", "specialist_visits", "other_outpatient", "_visits",
      "rx_fills", "days_supply", "pdc", "infusions",
      "lab_tests", "imaging", "procedures_count"
    )
    variables <- allCols[sapply(allCols, function(col) any(sapply(utilPatterns, function(p) grepl(p, col))))]
  }

  if (length(variables) == 0) {
    cli::cli_inform("No utilization columns detected in cohort.")
    return(omopgenerics::emptySummarisedResult())
  }

  PatientProfiles::summariseResult(
    table = cohort,
    group = group,
    strata = strata,
    variables = variables,
    estimates = estimates,
    counts = TRUE
  )
}
