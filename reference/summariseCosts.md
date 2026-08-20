# Summarise Direct Medical Costs for a Cohort

Summarise Direct Medical Costs for a Cohort

## Usage

``` r
summariseCosts(
  cohort,
  group = list("cohort_name"),
  strata = list(),
  costColumns = NULL,
  estimates = c("mean", "sd", "median", "q25", "q75", "min", "max")
)
```

## Arguments

- cohort:

  An enriched cohort table containing cost columns.

- group:

  List of character vectors specifying grouping columns. Default:
  `list("cohort_name")`.

- strata:

  List of character vectors specifying stratification columns. Default:
  [`list()`](https://rdrr.io/r/base/list.html).

- costColumns:

  Character vector of cost columns to summarise. If NULL, selects all
  columns starting with `cost_`.

- estimates:

  Summary estimators to compute. Default:
  `c("mean", "sd", "median", "q25", "q75", "min", "max")`.

## Value

An `omopgenerics::summarised_result` object.
