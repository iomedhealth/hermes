# Format Utilization Results as Visual Tables

Format Utilization Results as Visual Tables

## Usage

``` r
tableUtilization(
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
)
```

## Arguments

- result:

  A `summarised_result` object.

- estimateName:

  Formatted estimates pattern, e.g. `c("Mean (SD)" = "<mean> (<sd>)")`.

- header:

  Columns to place in table header. Default: `c("strata", "estimate")`.

- settingsColumn:

  Settings columns to include. Default:
  [`character()`](https://rdrr.io/r/base/character.html).

- groupColumn:

  Group columns. Default:
  [`character()`](https://rdrr.io/r/base/character.html).

- rename:

  Named vector of column renamings. Default:
  [`character()`](https://rdrr.io/r/base/character.html).

- type:

  Output format: `"gt"`, `"flextable"`, `"reactable"`, `"datatable"`, or
  `"tibble"`. Default: `"gt"`.

- hide:

  Columns to hide. Default:
  [`character()`](https://rdrr.io/r/base/character.html).

- columnOrder:

  Order of columns in table. Default:
  [`character()`](https://rdrr.io/r/base/character.html).

- factor:

  List of factor orderings. Default:
  [`list()`](https://rdrr.io/r/base/list.html).

- style:

  Table styling name or object. Default: `NULL`.

- showMinCellCount:

  Whether to suppress counts below threshold. Default: `TRUE`.

- .options:

  Additional formatting options. Default:
  [`list()`](https://rdrr.io/r/base/list.html).

## Value

A formatted table object or tibble.
