# Extract Healthcare Resource Utilization (HCRU) from OMOP CDM (Stage 2: HCRU)

`extract_hcru()` queries the OMOP CDM to extract direct medical costs
and resource utilization across five core clinical domains (inpatient,
outpatient, pharmacotherapy, diagnostics/procedures, post-acute care)
for patients in the study cohorts across baseline and follow-up temporal
windows.

In Cost-Effectiveness Analysis (CEA), Healthcare Resource Utilization
(HCRU) forms the numerator of the Incremental Cost-Effectiveness Ratio
(ICER). This function links OMOP `cost` records to clinical events and
tags costs with the patient's health state (e.g., before or after the
outcome event).

## Usage

``` r
extract_hcru(
  study,
  baseline_window = c(-365, -1),
  followup_window = c(0, 365),
  cost_field = "total_paid",
  visit_domains = c("inpatient", "outpatient", "emergency", "specialist"),
  pharmacotherapy = TRUE,
  diagnostics = TRUE,
  post_acute = TRUE,
  calculate_readmissions = FALSE,
  persistence = FALSE
)

extractHcru(
  study,
  baselineWindow = c(-365, -1),
  followupWindow = c(0, 365),
  costField = "total_paid",
  visitDomains = c("inpatient", "outpatient", "emergency", "specialist"),
  pharmacotherapy = TRUE,
  diagnostics = TRUE,
  postAcute = TRUE,
  calculateReadmissions = FALSE,
  persistence = FALSE
)
```

## Arguments

- study:

  A `hermes_study` or `hermes_hcru` object.

- baseline_window:

  Relative days from cohort start date defining baseline (default
  `c(-365, -1)`).

- followup_window:

  Relative days from cohort start date defining follow-up (default
  `c(0, 365)`).

- cost_field:

  Column name in `cost` table to aggregate (default `"total_paid"`).

- visit_domains:

  Visit categories to extract from `visit_occurrence`.

- pharmacotherapy:

  Logical, whether to extract drug exposures (default `TRUE`).

- diagnostics:

  Logical, whether to extract procedures and measurements (default
  `TRUE`).

- post_acute:

  Logical, whether to extract post-acute/SNF/hospice care (default
  `TRUE`).

- calculate_readmissions:

  Logical, whether to compute 30-day and 90-day readmissions (default
  `FALSE`).

- persistence:

  Logical, whether to calculate Proportion of Days Covered (PDC)
  (default `FALSE`).

## Value

A `hermes_hcru` object enriched with `study$costs` and `study$hcru`.
