# Interface Contract: `extract_hcru()` API Specification

## Function Signature

```r
extract_hcru <- function(
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
```

## Parameter Definitions

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `study` | `hermes_study` or `hermes_hcru` | *Required* | A valid HERMES study object initialized with `init()`. |
| `baseline_window` | `integer(2)` | `c(-365, -1)` | Relative days from `cohort_start_date` defining the baseline pre-index window. |
| `followup_window` | `integer(2)` | `c(0, 365)` | Relative days from `cohort_start_date` defining the post-index follow-up window. |
| `cost_field` | `character(1)` | `"total_paid"` | Column name in the OMOP `cost` table to aggregate (e.g. `"total_paid"`, `"total_charge"`, `"paid_by_payer"`, `"paid_by_patient"`). |
| `visit_domains` | `character` | `c("inpatient", "outpatient", "emergency", "specialist")` | Visit categories to extract from `visit_occurrence`. Standard OMOP concept mappings are used internally (e.g., Inpatient/ICU: 9201, 32037, 8717, 581379; Outpatient/ED: 9202, 9203, 581477; GP specialty: 38004446). |
| `pharmacotherapy` | `logical(1)` | `TRUE` | Whether to extract drug exposures and days supply from `drug_exposure`. |
| `diagnostics` | `logical(1)` | `TRUE` | Whether to extract procedure and measurement counts from `procedure_occurrence` and `measurement`. |
| `post_acute` | `logical(1)` | `TRUE` | Whether to extract skilled nursing (42898160, 32036) and hospice (8546) encounters from `visit_occurrence`. |
| `calculate_readmissions` | `logical(1)` | `FALSE` | Whether to compute 30-day and 90-day hospital readmissions. |
| `persistence` | `logical(1)` | `FALSE` | Whether to calculate Proportion of Days Covered (PDC) persistence metrics. |

## Return Value Schema

Returns an updated object inheriting from `c("hermes_hcru", "hermes_study", "list")` containing the original `study` elements plus:

- `study$costs`: `tibble` containing patient-level financial metrics (`subject_id`, `total_paid`, `total_charge`, `health_state`, `cost_domain`).
- `study$hcru`: `list` containing domain-specific summaries:
  - `inpatient`: `tibble` (`subject_id`, `window`, `inpatient_admissions`, `inpatient_los_days`, `icu_admissions`, `icu_los_days`, `readmissions_30d`, `readmissions_90d`)
  - `outpatient`: `tibble` (`subject_id`, `window`, `emergency_visits`, `gp_visits`, `specialist_visits`, `other_outpatient_visits`)
  - `pharmacotherapy`: `tibble` (`subject_id`, `window`, `prescription_fills`, `total_days_supply`, `pdc`)
  - `procedures_diagnostics`: `tibble` (`subject_id`, `window`, `procedure_count`, `measurement_count`)
  - `post_acute`: `tibble` (`subject_id`, `window`, `post_acute_stays`, `post_acute_los_days`)
  - `patient_summary`: Combined wide `tibble` aggregating all domain counts and total costs per patient across baseline and follow-up windows.

## Error & Warning Contracts

- If `study` is not of class `hermes_study` or `hermes_hcru`, raise `stop("Argument 'study' must be a hermes_study or hermes_hcru object")`.
- If `cost` table is missing in `study$cdm`, emit warning and set `study$costs` to an empty structured data frame with required columns.
- If individual domain tables (`procedure_occurrence`, `measurement`, `provider`) are missing in `study$cdm`, gracefully handle with 0 counts for those metrics rather than crashing.
