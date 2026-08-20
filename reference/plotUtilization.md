# Plot Healthcare Resource Utilization

Plot Healthcare Resource Utilization

## Usage

``` r
plotUtilization(
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
)
```

## Arguments

- result:

  A `<summarised_result>` object from
  [`summariseUtilization()`](summariseUtilization.md).

- plotType:

  Type of plot to generate: `"barplot"` (or `"bar"`) or `"boxplot"` (or
  `"box"`). Default: `"barplot"`.

- x:

  Column to use for x-axis. Default: `"cohort_name"`.

- y:

  Metric to use for y-axis when `plotType = "barplot"`. Default:
  `"mean"`.

- lower:

  Metric for box plot lower hinge when `plotType = "boxplot"`. Default:
  `"q25"`.

- middle:

  Metric for box plot middle hinge when `plotType = "boxplot"`. Default:
  `"median"`.

- upper:

  Metric for box plot upper hinge when `plotType = "boxplot"`. Default:
  `"q75"`.

- ymin:

  Metric for box plot lower whisker when `plotType = "boxplot"`.
  Default: `"min"`.

- ymax:

  Metric for box plot upper whisker when `plotType = "boxplot"`.
  Default: `"max"`.

- facet:

  Formula or character vector for facetting. Default: `"variable_name"`.

- colour:

  Variable for color/fill aesthetics. Default: `"cohort_name"`.

- style:

  Plot style. Default: `NULL` (uses
  [`visOmopResults::themeVisOmop()`](https://darwin-eu.github.io/visOmopResults/reference/themeVisOmop.html)).

- type:

  Output type: `"ggplot"` or `"plotly"`. Default: `"ggplot"`.

- ...:

  Additional arguments passed to
  [`visOmopResults::barPlot()`](https://darwin-eu.github.io/visOmopResults/reference/barPlot.html)
  or
  [`visOmopResults::boxPlot()`](https://darwin-eu.github.io/visOmopResults/reference/boxPlot.html).

## Value

A `ggplot2` or `plotly` visualization object.
