# Add Multi-Setting Visit Utilization Metrics to a Cohort

Enriches an OMOP cohort table with Healthcare Resource Utilization
(HCRU) metrics across Inpatient, Outpatient, and Emergency care settings
in a single unified execution, with full support for provider specialty
stratification across domains.

## Usage

``` r
addVisits(
  x,
  indexDate = "cohort_start_date",
  censorDate = NULL,
  window = list(c(-365, -1), c(0, 365)),
  settings = c("inpatient", "outpatient", "emergency"),
  stratifySpecialty = TRUE,
  gpSpecialtyConceptIds = c(38004446L),
  icuSpecialtyConceptIds = c(38004500L),
  emergencySpecialtyConceptIds = c(38004510L),
  specialties = NULL,
  inpatientVisitConceptIds = c(9201L, 8717L, 581379L),
  outpatientVisitConceptIds = c(9202L, 581477L),
  emergencyVisitConceptIds = c(9203L, 262L, 581478L),
  icuConceptIds = 32037L,
  readmissions = FALSE,
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

- settings:

  Character vector of care settings to extract. Allowed values:
  `"inpatient"`, `"outpatient"`, `"emergency"`. Default:
  `c("inpatient", "outpatient", "emergency")`.

- stratifySpecialty:

  Logical; whether to partition visits by specialty. Default: `TRUE`.

- gpSpecialtyConceptIds:

  OMOP provider specialty concept IDs for General Practice. Default:
  `c(38004446L)`.

- icuSpecialtyConceptIds:

  OMOP provider specialty concept IDs for ICU stays. Default:
  `c(38004500L)`.

- emergencySpecialtyConceptIds:

  OMOP provider specialty concept IDs for Emergency Medicine. Default:
  `c(38004510L)`.

- specialties:

  Optional named list of integer vectors of OMOP specialty concept IDs
  for granular specialty breakdown. Default: `NULL`.

- inpatientVisitConceptIds:

  OMOP visit concept IDs for inpatient stays. Default:
  `c(9201L, 8717L, 581379L)`.

- outpatientVisitConceptIds:

  OMOP visit concept IDs for outpatient care. Default:
  `c(9202L, 581477L)`.

- emergencyVisitConceptIds:

  OMOP visit concept IDs for emergency care. Default:
  `c(9203L, 262L, 581478L)`.

- icuConceptIds:

  OMOP visit concept IDs for ICU stays. Default: `32037L`.

- readmissions:

  Logical; whether to compute 30-day and 90-day readmissions for
  inpatient stays. Default: `FALSE`.

- name:

  Name of the new table in the write schema. If NULL, a temporary table
  is returned.

## Value

The cohort table `x` with added multi-setting visit metric columns.
