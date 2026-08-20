#' Plot Summarised Healthcare Resource Utilization
#'
#' @param result A `summarised_result` object from `summariseUtilization()`.
#' @param metric Column or metric name pattern to plot. Default: `"inpatient_admissions"`.
#' @param plotType Visualization type: `"barplot"` or `"boxplot"`. Default: `"barplot"`.
#'
#' @return A `ggplot2` visualization object.
#' @export
plotUtilization <- function(
  result,
  metric = "inpatient_admissions",
  plotType = "barplot"
) {
  # ponytail: delegate to visOmopResults or ggplot2 barplot
  omopgenerics::validateResultArgument(result)

  res_df <- result |>
    dplyr::filter(grepl(.env$metric, .data$variable_name))

  if (nrow(res_df) == 0) {
    warning("No matching metric found in summarised result.")
    return(ggplot2::ggplot())
  }

  mean_df <- res_df |>
    dplyr::filter(.data$estimate_name == "mean") |>
    dplyr::mutate(estimate_value = as.numeric(.data$estimate_value))

  p <- ggplot2::ggplot(mean_df, ggplot2::aes(x = .data$variable_name, y = .data$estimate_value, fill = .data$group_level)) +
    ggplot2::theme_minimal() +
    ggplot2::labs(
      title = paste("Utilization:", metric),
      x = "Metric",
      y = "Mean Utilization"
    )

  if (plotType == "barplot") {
    p <- p + ggplot2::geom_col(position = "dodge")
  } else {
    p <- p + ggplot2::geom_point(size = 3)
  }

  p
}
