# Add Emergency Care Utilization Metrics to a Cohort

Identifies emergency encounters by querying `visit_occurrence` and
`provider` tables, capturing encounters with emergency visit concept IDs
(e.g. 9203, 262, 581478) as well as visits delivered by emergency
medicine specialist providers (e.g. 38004510), with optional granular
specialty stratification.

## Usage

``` r
addEmergencyCare(
  x,
  indexDate = "cohort_start_date",
  censorDate = NULL,
  window = list(c(-365, -1), c(0, 365)),
  emergencyVisitConceptIds = c(9203L, 262L, 581478L),
  emergencySpecialtyConceptIds = c(38004510L),
  stratifySpecialty = FALSE,
  specialties = NULL,
  nameStyle = "emergency_visits_{window_name}",
  name = NULL
)

addEmergency(
  x,
  indexDate = "cohort_start_date",
  censorDate = NULL,
  window = list(c(-365, -1), c(0, 365)),
  emergencyVisitConceptIds = c(9203L, 262L, 581478L),
  emergencySpecialtyConceptIds = c(38004510L),
  stratifySpecialty = FALSE,
  specialties = NULL,
  nameStyle = "emergency_visits_{window_name}",
  name = NULL
)

addEmergencyVisits(
  x,
  indexDate = "cohort_start_date",
  censorDate = NULL,
  window = list(c(-365, -1), c(0, 365)),
  emergencyVisitConceptIds = c(9203L, 262L, 581478L),
  emergencySpecialtyConceptIds = c(38004510L),
  stratifySpecialty = FALSE,
  specialties = NULL,
  nameStyle = "emergency_visits_{window_name}",
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

- emergencyVisitConceptIds:

  OMOP visit concept IDs for emergency care. Default:
  `c(9203L, 262L, 581478L)`.

- emergencySpecialtyConceptIds:

  OMOP provider specialty concept IDs for emergency medicine. Default:
  `c(38004510L)`.

- stratifySpecialty:

  Logical; whether to compute specialty breakdown. Default: `FALSE`.

- specialties:

  Optional named list of integer vectors of OMOP specialty concept IDs
  for granular specialty breakdown. Default: `NULL`.

- nameStyle:

  Column naming pattern. Default: `"emergency_visits_{window_name}"`.

- name:

  Name of the new table in the write schema. If NULL, a temporary table
  is returned.

## Value

The cohort table `x` with added emergency visit metric columns.
