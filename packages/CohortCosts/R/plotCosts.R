#' Plot Summarised Direct Medical Costs
#'
#' @param result A `summarised_result` object from `summariseCosts()`.
#' @param costColumn Cost column name pattern to plot. Default: `"cost_total"`.
#' @param plotType Visualization type: `"barplot"` or `"boxplot"`. Default: `"barplot"`.
#'
#' @return A `ggplot2` visualization object.
#' @export
plotCosts <- function(
  result,
  costColumn = "cost_total",
  plotType = "barplot"
) {
  # ponytail: delegate to visOmopResults or ggplot2 barplot
  omopgenerics::validateResultArgument(result)

  res_df <- result |>
    dplyr::filter(grepl(.env$costColumn, .data$variable_name))

  if (nrow(res_df) == 0) {
    warning("No matching cost column found in summarised result.")
    return(ggplot2::ggplot())
  }

  mean_df <- res_df |>
    dplyr::filter(.data$estimate_name == "mean") |>
    dplyr::mutate(estimate_value = as.numeric(.data$estimate_value))

  p <- ggplot2::ggplot(mean_df, ggplot2::aes(x = .data$variable_name, y = .data$estimate_value, fill = .data$group_level)) +
    ggplot2::theme_minimal() +
    ggplot2::labs(
      title = paste("Direct Medical Costs:", costColumn),
      x = "Cost Domain",
      y = "Mean Cost ($)"
    )

  if (plotType == "barplot") {
    p <- p + ggplot2::geom_col(position = "dodge")
  } else {
    p <- p + ggplot2::geom_point(size = 3)
  }

  p
}
