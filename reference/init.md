# Initialize a HERMES study (Stage 1: Cohort Generation)

`init()` is the entry point for the HERMES 6-stage pipeline. It takes an
existing OMOP Common Data Model (CDM) reference and the names of
pre-generated cohort tables, validating their existence and calculating
baseline cohort counts.

In the context of Health Economics and Outcomes Research (HEOR), this
step maps directly to defining the **Treatment Arm** (`target_cohort`),
the **Standard of Care Arm** (`comparator_cohort`), and the clinical
event or **Health State** of interest (`outcome_cohort`).

## Usage

``` r
init(cdm, target_cohort, comparator_cohort, outcome_cohort)
```

## Arguments

- cdm:

  A `cdm_reference` object created by
  [`CDMConnector::cdmFromCon()`](https://darwin-eu.github.io/CDMConnector/reference/cdmFromCon.html).

- target_cohort:

  A string specifying the name of the target cohort table in the CDM.

- comparator_cohort:

  A string specifying the name of the comparator cohort table in the
  CDM.

- outcome_cohort:

  A string specifying the name of the outcome cohort table in the CDM.

## Value

A `hermes_study` S3 object containing the CDM reference and cohort
metadata, ready to be piped into
[`summarise_baseline()`](summarise_baseline.md).

## See also

[`vignette("intro-to-heor")`](../articles/intro-to-heor.md) for a
mapping between OMOP cohorts and HEOR concepts.
