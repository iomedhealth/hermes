# Add Outpatient and Emergency Visits to a Cohort

Add Outpatient and Emergency Visits to a Cohort

## Usage

``` r
addOutpatientVisits(
  x,
  indexDate = "cohort_start_date",
  censorDate = NULL,
  window = list(c(-365, -1), c(0, 365)),
  stratifySpecialty = TRUE,
  gpSpecialtyConceptIds = c(38004446L),
  specialties = NULL,
  nameStyle = "{setting}_visits_{window_name}",
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

- stratifySpecialty:

  Logical; whether to partition visits by GP vs Specialist vs ED.
  Default: `TRUE`.

- gpSpecialtyConceptIds:

  OMOP provider specialty concept IDs for General Practice. Default:
  `c(38004446L)`.

- specialties:

  Optional named list of integer vectors of OMOP specialty concept IDs
  for granular specialty breakdown. Default: `NULL`.

- nameStyle:

  Column naming pattern. Default: `"{setting}_visits_{window_name}"`.

- name:

  Name of the new table in the write schema. If NULL, a temporary table
  is returned.

## Value

The cohort table `x` with added outpatient visit metric columns.
