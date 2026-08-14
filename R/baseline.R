#' Summarise baseline demographics and comorbidities (Stage 2: Baseline)
#'
#' @description
#' `summarise_baseline()` computes unadjusted baseline characteristics for the
#' cohorts defined in the `hermes_study` object.
#'
#' In HEOR, understanding the baseline characteristics of the Treatment and
#' Standard of Care arms is crucial. If the populations are systematically different
#' (e.g., the target cohort is much older or sicker), direct cost or outcome comparisons
#' will be biased. This function leverages `PatientProfiles` and `CohortCharacteristics`
#' to generate these standardized summaries.
#' 
#' **Example Output Structure:**
#' ```
#' # A tibble: 5 × 4
#'   variable_name variable_level estimate_name estimate_value
#'   <chr>         <chr>          <chr>         <chr>         
#' 1 Number records NA             count         1000          
#' 2 Age           NA             mean          65.2          
#' 3 Age           NA             sd            10.1          
#' 4 Sex           Female         count         450           
#' 5 Sex           Female         percentage    45.0          
#' ```
#'
#' @param study A `hermes_study` object, typically the output of `init()`.
#'
#' @return A `hermes_hcru` S3 object containing the original study data plus a new
#' `baseline_summary` attribute.
#'
#' @export
summarise_baseline <- function(study) {
  # ponytail: use CohortCharacteristics directly, demographics=TRUE handles age/sex.
  # We summarize both target and comparator if they exist.

  target_cohort_name <- study$target_cohort
  target_cohort <- study$cdm[[target_cohort_name]]

  # Add demographics using PatientProfiles
  target_profiled <- target_cohort |>
    PatientProfiles::addDemographics() |>
    dplyr::compute(name = "target_profiled_temp", temporary = FALSE, overwrite = TRUE)

  target_profiled_cohort <- omopgenerics::newCohortTable(table = target_profiled)

  baseline_summary <- CohortCharacteristics::summariseCharacteristics(
    cohort = target_profiled_cohort,
    demographics = TRUE
  )

  res <- c(study, list(baseline_summary = baseline_summary))
  new_hermes_hcru(res)
}
