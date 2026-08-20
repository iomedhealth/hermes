# Add Direct Medical Costs to a Cohort

Add Direct Medical Costs to a Cohort

## Usage

``` r
addCosts(
  x,
  indexDate = "cohort_start_date",
  censorDate = NULL,
  window = list(c(-365, -1), c(0, 365)),
  costField = "total_paid",
  domains = c("Inpatient", "Outpatient", "Drug", "Procedure"),
  nameStyle = "cost_{domain}_{window_name}",
  name = NULL
)
```

## Arguments

- x:

  A cohort table or cdm_table.

- indexDate:

  Date variable in `x` anchoring the observation window. Default:
  `"cohort_start_date"`.

- censorDate:

  Optional date variable in `x` to censor observation.

- window:

  A named or unnamed list of 2-element numeric vectors. Default:
  `list(c(-365, -1), c(0, 365))`.

- costField:

  Column name in `cost` table to aggregate. Default: `"total_paid"`.

- domains:

  Clinical domains to extract. Default:
  `c("Inpatient", "Outpatient", "Drug", "Procedure")`.

- nameStyle:

  Column naming pattern. Default: `"cost_{domain}_{window_name}"`.

- name:

  Name of the new table in the write schema. If NULL, a temporary table
  is returned.

## Value

The cohort table `x` with added direct medical cost columns.
