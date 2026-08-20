# Add Inpatient and ICU Hospitalization Metrics to a Cohort

Add Inpatient and ICU Hospitalization Metrics to a Cohort

## Usage

``` r
addHospitalizations(
  x,
  indexDate = "cohort_start_date",
  censorDate = NULL,
  window = list(c(-365, -1), c(0, 365)),
  visitConceptIds = c(9201L, 8717L, 581379L),
  icuConceptIds = 32037L,
  icuSpecialtyConceptIds = c(38004500L),
  readmissions = FALSE,
  nameStyle = "{domain}_{metric}_{window_name}",
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

- visitConceptIds:

  OMOP visit concept IDs for general inpatient stays. Default:
  `c(9201L, 8717L, 581379L)`.

- icuConceptIds:

  OMOP visit concept IDs for ICU stays. Default: `32037L`.

- icuSpecialtyConceptIds:

  OMOP provider specialty concept IDs for ICU stays. Default:
  `c(38004500L)`.

- readmissions:

  Logical; whether to compute 30-day and 90-day readmissions. Default:
  `FALSE`.

- nameStyle:

  Column naming pattern. Default: `"{domain}_{metric}_{window_name}"`.

- name:

  Name of the new table in the write schema. If NULL, a temporary table
  is returned.

## Value

The cohort table `x` with added hospitalization metric columns.
