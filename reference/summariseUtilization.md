# Summarise Healthcare Resource Utilization for a Cohort

Summarise Healthcare Resource Utilization for a Cohort

## Usage

``` r
summariseUtilization(
  cohort,
  group = list("cohort_name"),
  strata = list(),
  estimates = c("mean", "sd", "median", "q25", "q75", "min", "max"),
  variables = NULL
)
```

## Arguments

- cohort:

  An enriched cohort table containing utilization columns.

- group:

  List of character vectors specifying grouping columns. Default:
  `list("cohort_name")`.

- strata:

  List of character vectors specifying stratification columns. Default:
  [`list()`](https://rdrr.io/r/base/list.html).

- estimates:

  Summary estimators to compute. Default:
  `c("mean", "sd", "median", "q25", "q75", "min", "max")`.

- variables:

  Optional character vector of specific variables to summarise. If NULL,
  auto-detects utilization columns.

## Value

An `omopgenerics::summarised_result` object.
