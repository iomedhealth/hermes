#' Format Summarised Direct Costs as a Table
#'
#' @param result A `summarised_result` object from `summariseCosts()`.
#' @param type Output table format: `"gt"`, `"flextable"`, or `"tibble"`. Default: `"gt"`.
#' @param header Character vector of columns to include in the header. Default: `c("cdm_name", "cohort_name")`.
#' @param estimateName Named character vector mapping estimate names.
#'
#' @return A formatted table object (gt_tbl, flextable, or tibble).
#' @export
tableCosts <- function(
  result,
  type = "gt",
  header = c("cdm_name", "cohort_name"),
  estimateName = c(
    "N" = "<count>",
    "Mean (SD)" = "<mean> (<sd>)",
    "Median (IQR)" = "<median> (<q25> - <q75>)",
    "Min - Max" = "<min> - <max>"
  )
) {
  # ponytail: delegate to visOmopResults::visOmopTable
  omopgenerics::validateResultArgument(result)

  visOmopResults::visOmopTable(
    result = result,
    estimateName = estimateName,
    type = type,
    header = header
  )
}
