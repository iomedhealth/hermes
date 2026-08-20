# Generate Hospitalization and Readmission Cohorts (Stage 1 & 2)

Extracts inpatient visits from `visit_occurrence`, collapses contiguous
or overlapping stays into discrete hospitalization episodes, and derives
readmission cohorts within a specified washout window.

## Usage

``` r
compute_hospitalization_cohorts(
  cdm,
  name,
  visit_concept_ids = c(9201L, 262L, 32037L, 581379L),
  readmission_window = 30L
)

computeHospitalizationCohorts(
  cdm,
  name,
  visitConceptIds = c(9201L, 262L, 581379L),
  icuConceptIds = 32037L,
  readmissionWindow = 30L,
  readmission_window = NULL
)
```

## Arguments

- cdm:

  A `cdm_reference` object.

- name:

  String specifying the cohort table name in the write schema.

- visit_concept_ids:

  Integer vector of OMOP visit concept IDs. Default:
  `c(9201L, 262L, 32037L, 581379L)`.

- readmission_window:

  Maximum days between previous discharge and next admission. Default:
  30.

- icuConceptIds:

  Integer vector of OMOP ICU visit concept IDs. Default: `32037L`.

- readmissionWindow:

  Maximum days between previous discharge and next admission. Default:
  30.

## Value

An `omopgenerics` cohort table with cohort definitions:

- `1`: `hospitalization` (collapsed inpatient episodes)

- `2`: `readmission` (episodes occurring within `readmission_window`
  days of prior discharge)
