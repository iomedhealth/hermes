# Create Infusion Administration Episode Cohorts

Create Infusion Administration Episode Cohorts

## Usage

``` r
computeInfusionCohorts(
  cdm,
  name,
  conceptSet = NULL,
  routeConceptIds = c(4171047L, 4171048L),
  collapseGap = 0L
)
```

## Arguments

- cdm:

  A `cdm_reference` object.

- name:

  String specifying the cohort table name in the write schema.

- conceptSet:

  Optional concept set / codelist of specific infused drugs.

- routeConceptIds:

  Integer vector of OMOP route concept IDs. Default:
  `c(4171047L, 4171048L)`.

- collapseGap:

  Maximum gap in days between contiguous administration records to
  collapse. Default: `0L`.

## Value

An `omopgenerics::cohort_table` object.
