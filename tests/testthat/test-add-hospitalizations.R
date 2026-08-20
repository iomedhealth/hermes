test_that("addHospitalizations validates input arguments correctly", {
  cdm <- hermes_test_cdm()
  cohort <- cdm$target_cohort

  expect_error(addHospitalizations(list()), "Argument 'x' must be a cdm_table or cohort_table")
  expect_error(addHospitalizations(cohort, indexDate = "not_a_col"), "indexDate 'not_a_col' must be a column in x")
  expect_error(addHospitalizations(cohort, window = list(c(10, 0))), "Window interval \\[10, 0\\] is invalid")
})

test_that("addHospitalizations computes admissions, LOS, ICU stays, and readmissions", {
  cdm <- hermes_test_cdm()

  cohort_enriched <- cdm$target_cohort |>
    addHospitalizations(
      window = list(baseline = c(-365, -1), followup = c(0, 365)),
      readmissions = TRUE
    ) |>
    dplyr::collect()

  expect_true(is.data.frame(cohort_enriched))
  expect_equal(nrow(cohort_enriched), nrow(cdm$target_cohort |> dplyr::collect()))

  cols <- colnames(cohort_enriched)
  expect_true(all(c(
    "inpatient_admissions_baseline", "inpatient_los_days_baseline",
    "inpatient_admissions_followup", "inpatient_los_days_followup",
    "icu_admissions_followup", "icu_los_days_followup",
    "readmissions_30d_followup"
  ) %in% cols))

  # Patient 1 has 2 inpatient admissions (4 + 3 = 7 days LOS), 1 ICU (2 days), 1 30d readmission in followup
  p1 <- cohort_enriched |> dplyr::filter(.data$subject_id == 1L)
  expect_equal(p1$inpatient_admissions_followup, 2)
  expect_equal(p1$inpatient_los_days_followup, 7)
  expect_equal(p1$icu_admissions_followup, 1)
  expect_equal(p1$icu_los_days_followup, 2)
  expect_equal(p1$readmissions_30d_followup, 1)
})

test_that("addHospitalizations detects ICU stays via provider icuSpecialtyConceptIds", {
  cdm <- hermes_test_cdm()

  # Update provider table so provider 1 has specialty 38004500 (Critical care intensivist)
  prov_df <- cdm$provider |> dplyr::collect()
  prov_df$specialty_concept_id[prov_df$provider_id == 1L] <- 38004500L
  cdm <- omopgenerics::insertTable(cdm, name = "provider", table = prov_df, overwrite = TRUE)

  # With icuSpecialtyConceptIds = 38004500L, inpatient visits with provider 1 are classified as ICU stays
  cohort_enriched <- cdm$target_cohort |>
    addHospitalizations(
      window = list(baseline = c(-365, -1), followup = c(0, 365)),
      icuSpecialtyConceptIds = c(38004500L),
      readmissions = FALSE
    ) |>
    dplyr::collect()

  p1 <- cohort_enriched |> dplyr::filter(.data$subject_id == 1L)
  # Person 1 has 2 visits (concept 9201) + 1 visit (concept 32037) all linked to provider 1
  # When provider 1 is ICU specialty, all 3 are classified as ICU stays (total 3 admissions, 4+3+2 = 9 days LOS)
  expect_equal(p1$inpatient_admissions_followup, 0)
  expect_equal(p1$inpatient_los_days_followup, 0)
  expect_equal(p1$icu_admissions_followup, 3)
  expect_equal(p1$icu_los_days_followup, 9)
})
