# Add Diagnostic Measurements and Procedure Occurrences to a Cohort

Add Diagnostic Measurements and Procedure Occurrences to a Cohort

## Usage

``` r
addProcedures(
  x,
  indexDate = "cohort_start_date",
  censorDate = NULL,
  window = list(c(-365, -1), c(0, 365)),
  labConceptSet = NULL,
  imagingConceptSet = NULL,
  procedureConceptSet = NULL,
  nameStyle = "{metric}_count_{window_name}",
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

- labConceptSet:

  Optional concept set / codelist for laboratory tests in `measurement`.

- imagingConceptSet:

  Optional concept set / codelist for imaging scans in
  `procedure_occurrence`.

- procedureConceptSet:

  Optional concept set / codelist for procedures in
  `procedure_occurrence`.

- nameStyle:

  Column naming pattern. Default: `"{metric}_count_{window_name}"`.

- name:

  Name of the new table in the write schema. If NULL, a temporary table
  is returned.

## Value

The cohort table `x` with added procedure and diagnostic metric columns.
