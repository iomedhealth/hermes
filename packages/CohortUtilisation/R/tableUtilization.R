#' Format Summarised Utilization as a Table
#'
#' @param result A `summarised_result` object from `summariseUtilization()`.
#' @param type Output table format: `"gt"`, `"flextable"`, or `"tibble"`. Default: `"gt"`.
#' @param header Character vector of columns to include in the header. Default: `c("cdm_name", "cohort_name")`.
#'
#' @return A formatted table object (gt_tbl, flextable, or tibble).
#' @export
tableUtilization <- function(
  result,
  type = "gt",
  header = c("cdm_name", "cohort_name")
) {
  # ponytail: delegate to visOmopResults::visOmopTable
  omopgenerics::validateResultArgument(result)

  visOmopResults::visOmopTable(
    result = result,
    type = type,
    header = header
  )
}
