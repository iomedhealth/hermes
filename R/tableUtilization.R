#' Format Utilization Results as Visual Tables
#'
#' @param result A `summarised_result` object.
#' @param type Output format: `"gt"`, `"flextable"`, or `"tibble"`. Default: `"gt"`.
#' @param header Columns to place in table header. Default: `c("strata", "estimate")`.
#' @param groupColumn Group columns. Default: `character()`.
#' @param hide Columns to hide. Default: `character()`.
#'
#' @return A formatted table object or tibble.
#' @export
tableUtilization <- function(
  result,
  type = "gt",
  header = c("strata", "estimate"),
  groupColumn = character(),
  hide = character()
) {
  # ponytail: delegate to visOmopResults::visOmopTable with safe fallback to tibble
  omopgenerics::validateResultArgument(result)

  if (type == "tibble") {
    return(as.data.frame(result))
  }

  if (requireNamespace("visOmopResults", quietly = TRUE)) {
    visOmopResults::visOmopTable(
      result = result,
      type = type,
      header = header,
      groupColumn = groupColumn,
      hide = hide
    )
  } else {
    cli::cli_warn("Package 'visOmopResults' is not installed. Returning tibble.")
    as.data.frame(result)
  }
}

#' Format Cost Results as Visual Tables
#'
#' @param result A `summarised_result` object from `summariseCosts()`.
#' @param type Output format: `"gt"`, `"flextable"`, or `"tibble"`. Default: `"gt"`.
#' @param header Columns to place in table header. Default: `c("strata", "estimate")`.
#' @param groupColumn Group columns. Default: `character()`.
#' @param hide Columns to hide. Default: `character()`.
#'
#' @return A formatted table object or tibble.
#' @export
tableCosts <- function(
  result,
  type = "gt",
  header = c("strata", "estimate"),
  groupColumn = character(),
  hide = character()
) {
  tableUtilization(
    result = result,
    type = type,
    header = header,
    groupColumn = groupColumn,
    hide = hide
  )
}
