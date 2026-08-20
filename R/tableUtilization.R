#' Format Utilization Results as Visual Tables
#'
#' @param result A `summarised_result` object.
#' @param estimateName Formatted estimates pattern, e.g. `c("Mean (SD)" = "<mean> (<sd>)")`.
#' @param header Columns to place in table header. Default: `c("strata", "estimate")`.
#' @param settingsColumn Settings columns to include. Default: `character()`.
#' @param groupColumn Group columns. Default: `character()`.
#' @param rename Named vector of column renamings. Default: `character()`.
#' @param type Output format: `"gt"`, `"flextable"`, `"reactable"`, `"datatable"`, or `"tibble"`. Default: `"gt"`.
#' @param hide Columns to hide. Default: `character()`.
#' @param columnOrder Order of columns in table. Default: `character()`.
#' @param factor List of factor orderings. Default: `list()`.
#' @param style Table styling name or object. Default: `NULL`.
#' @param showMinCellCount Whether to suppress counts below threshold. Default: `TRUE`.
#' @param .options Additional formatting options. Default: `list()`.
#'
#' @return A formatted table object or tibble.
#' @export
tableUtilization <- function(
  result,
  estimateName = character(),
  header = c("strata", "estimate"),
  settingsColumn = character(),
  groupColumn = character(),
  rename = character(),
  type = "gt",
  hide = character(),
  columnOrder = character(),
  factor = list(),
  style = NULL,
  showMinCellCount = TRUE,
  .options = list()
) {
  # ponytail: delegate to visOmopResults::visOmopTable with safe fallback to tibble
  omopgenerics::validateResultArgument(result)

  if (identical(type, "tibble")) {
    return(as.data.frame(result))
  }

  if (requireNamespace("visOmopResults", quietly = TRUE)) {
    visOmopResults::visOmopTable(
      result = result,
      estimateName = estimateName,
      header = header,
      settingsColumn = settingsColumn,
      groupColumn = groupColumn,
      rename = rename,
      type = type,
      hide = hide,
      columnOrder = columnOrder,
      factor = factor,
      style = style,
      showMinCellCount = showMinCellCount,
      .options = .options
    )
  } else {
    cli::cli_warn("Package 'visOmopResults' is not installed. Returning tibble.")
    as.data.frame(result)
  }
}

#' Format Cost Results as Visual Tables
#'
#' @inheritParams tableUtilization
#'
#' @return A formatted table object or tibble.
#' @export
tableCosts <- function(
  result,
  estimateName = character(),
  header = c("strata", "estimate"),
  settingsColumn = character(),
  groupColumn = character(),
  rename = character(),
  type = "gt",
  hide = character(),
  columnOrder = character(),
  factor = list(),
  style = NULL,
  showMinCellCount = TRUE,
  .options = list()
) {
  tableUtilization(
    result = result,
    estimateName = estimateName,
    header = header,
    settingsColumn = settingsColumn,
    groupColumn = groupColumn,
    rename = rename,
    type = type,
    hide = hide,
    columnOrder = columnOrder,
    factor = factor,
    style = style,
    showMinCellCount = showMinCellCount,
    .options = .options
  )
}
