#' Summarise Direct Medical Costs for a Cohort
#'
#' @param cohort An enriched cohort table containing cost columns.
#' @param group List of character vectors specifying grouping columns. Default: `list("cohort_name")`.
#' @param strata List of character vectors specifying stratification columns. Default: `list()`.
#' @param costColumns Character vector of cost columns to summarise. If NULL, selects all columns starting with `cost_`.
#' @param estimates Summary estimators to compute. Default: `c("mean", "sd", "median", "q25", "q75", "min", "max")`.
#'
#' @return An `omopgenerics::summarised_result` object.
#' @export
summariseCosts <- function(
  cohort,
  group = list("cohort_name"),
  strata = list(),
  costColumns = NULL,
  estimates = c("mean", "sd", "median", "q25", "q75", "min", "max")
) {
  # ponytail: delegate to PatientProfiles::summariseResult with auto-detected cost columns
  if (inherits(cohort, "cohort_table") && !"cohort_name" %in% colnames(cohort)) {
    cohort <- PatientProfiles::addCohortName(cohort)
  }

  groupCols <- unlist(group)
  missingGroup <- setdiff(groupCols, colnames(cohort))
  if (length(missingGroup) > 0) {
    group <- list()
  }

  if (is.null(costColumns)) {
    allCols <- colnames(cohort)
    costColumns <- allCols[grepl("^cost_", allCols)]
  }

  if (length(costColumns) == 0) {
    cli::cli_inform("No cost columns detected in cohort.")
    return(omopgenerics::emptySummarisedResult())
  }

  PatientProfiles::summariseResult(
    table = cohort,
    group = group,
    strata = strata,
    variables = costColumns,
    estimates = estimates,
    counts = TRUE
  )
}
