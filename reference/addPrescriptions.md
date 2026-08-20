# Add Prescription and Medication Metrics to a Cohort

Add Prescription and Medication Metrics to a Cohort

## Usage

``` r
addPrescriptions(
  x,
  indexDate = "cohort_start_date",
  censorDate = NULL,
  window = list(c(-365, -1), c(0, 365)),
  conceptSet = NULL,
  infusionRouteConceptIds = c(4171047L, 4171048L),
  daysSupply = TRUE,
  pdc = FALSE,
  nameStyle = "{metric}_{window_name}",
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

- conceptSet:

  Optional concept set / codelist of specific drugs.

- infusionRouteConceptIds:

  OMOP route concept IDs for parenteral/IV infusions. Default:
  `c(4171047L, 4171048L)`.

- daysSupply:

  Logical; whether to compute cumulative days supply. Default: `TRUE`.

- pdc:

  Logical; whether to compute Proportion of Days Covered. Default:
  `FALSE`.

- nameStyle:

  Column naming pattern. Default: `"{metric}_{window_name}"`.

- name:

  Name of the new table in the write schema. If NULL, a temporary table
  is returned.

## Value

The cohort table `x` with added prescription metric columns.
