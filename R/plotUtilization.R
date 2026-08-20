#' Plot Healthcare Resource Utilization
#'
#' @param result A `<summarised_result>` object from `summariseUtilization()`.
#' @param plotType Type of plot to generate: `"barplot"` (or `"bar"`) or `"boxplot"` (or `"box"`). Default: `"barplot"`.
#' @param x Column to use for x-axis. Default: `"cohort_name"`.
#' @param y Metric to use for y-axis when `plotType = "barplot"`. Default: `"mean"`.
#' @param lower Metric for box plot lower hinge when `plotType = "boxplot"`. Default: `"q25"`.
#' @param middle Metric for box plot middle hinge when `plotType = "boxplot"`. Default: `"median"`.
#' @param upper Metric for box plot upper hinge when `plotType = "boxplot"`. Default: `"q75"`.
#' @param ymin Metric for box plot lower whisker when `plotType = "boxplot"`. Default: `"min"`.
#' @param ymax Metric for box plot upper whisker when `plotType = "boxplot"`. Default: `"max"`.
#' @param facet Formula or character vector for facetting. Default: `"variable_name"`.
#' @param colour Variable for color/fill aesthetics. Default: `"cohort_name"`.
#' @param style Plot style. Default: `NULL` (uses `visOmopResults::themeVisOmop()`).
#' @param type Output type: `"ggplot"` or `"plotly"`. Default: `"ggplot"`.
#' @param ... Additional arguments passed to `visOmopResults::barPlot()` or `visOmopResults::boxPlot()`.
#'
#' @return A `ggplot2` or `plotly` visualization object.
#' @export
plotUtilization <- function(
  result,
  plotType = "barplot",
  x = "cohort_name",
  y = "mean",
  lower = "q25",
  middle = "median",
  upper = "q75",
  ymin = "min",
  ymax = "max",
  facet = "variable_name",
  colour = "cohort_name",
  style = NULL,
  type = "ggplot",
  ...
) {
  # ponytail: delegate to visOmopResults barPlot or boxPlot
  rlang::check_installed("visOmopResults")
  omopgenerics::validateResultArgument(result)

  if (nrow(result) == 0) {
    cli::cli_warn("Result object is empty, returning empty plot.")
    return(visOmopResults::emptyPlot())
  }

  plotType <- tolower(plotType)

  if (plotType %in% c("barplot", "bar")) {
    visOmopResults::barPlot(
      result = result,
      x = x,
      y = y,
      facet = facet,
      colour = colour,
      style = style,
      type = type,
      ...
    )
  } else if (plotType %in% c("boxplot", "box")) {
    visOmopResults::boxPlot(
      result = result,
      x = x,
      lower = lower,
      middle = middle,
      upper = upper,
      ymin = ymin,
      ymax = ymax,
      facet = facet,
      colour = colour,
      style = style,
      type = type,
      ...
    )
  } else {
    cli::cli_abort("plotType must be either 'barplot' or 'boxplot', not '{plotType}'.")
  }
}

#' Plot Direct Medical Costs
#'
#' @inheritParams plotUtilization
#'
#' @return A `ggplot2` or `plotly` visualization object.
#' @export
plotCosts <- function(
  result,
  plotType = "barplot",
  x = "cohort_name",
  y = "mean",
  lower = "q25",
  middle = "median",
  upper = "q75",
  ymin = "min",
  ymax = "max",
  facet = "variable_name",
  colour = "cohort_name",
  style = NULL,
  type = "ggplot",
  ...
) {
  plotUtilization(
    result = result,
    plotType = plotType,
    x = x,
    y = y,
    lower = lower,
    middle = middle,
    upper = upper,
    ymin = ymin,
    ymax = ymax,
    facet = facet,
    colour = colour,
    style = style,
    type = type,
    ...
  )
}
