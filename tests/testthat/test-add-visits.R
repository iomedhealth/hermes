test_that("addVisits validates input arguments correctly", {
  cdm <- hermesTestCdm()
  cohort <- cdm$target_cohort

  expect_error(addVisits(list()), "Argument 'x' must be a cdm_table or cohort_table")
  expect_error(addVisits(cohort, indexDate = "not_a_col"), "indexDate 'not_a_col' must be a column in x")
  expect_error(addVisits(cohort, window = list(c(10, 0))), "Window interval \\[10, 0\\] is invalid")
  expect_error(addVisits(cohort, settings = "invalid_setting"), "must be a subset of")
  expect_error(addVisits(cohort, specialties = "not_a_list"), "must be a named list")
})

test_that("addVisits executes multi-setting visit enrichment (inpatient, outpatient, emergency)", {
  cdm <- hermesTestCdm()

  cohortEnriched <- cdm$target_cohort |>
    addVisits(
      window = list(baseline = c(-365, -1), followup = c(0, 365)),
      settings = c("inpatient", "outpatient", "emergency"),
      readmissions = TRUE
    ) |>
    dplyr::collect()

  expect_true(is.data.frame(cohortEnriched))
  expect_equal(nrow(cohortEnriched), nrow(cdm$target_cohort |> dplyr::collect()))

  cols <- colnames(cohortEnriched)
  expectedCols <- c(
    # Inpatient
    "inpatient_admissions_baseline", "inpatient_los_days_baseline",
    "inpatient_admissions_followup", "inpatient_los_days_followup",
    "icu_admissions_followup", "icu_los_days_followup",
    "readmissions_30d_followup",
    # Outpatient
    "gp_visits_baseline", "gp_visits_followup",
    "specialist_visits_baseline", "specialist_visits_followup",
    "other_outpatient_visits_baseline", "other_outpatient_visits_followup",
    # Emergency
    "emergency_visits_baseline", "emergency_visits_followup"
  )
  expect_true(all(expectedCols %in% cols))

  # Patient 1 checks
  p1 <- cohortEnriched |> dplyr::filter(.data$subject_id == 1L)
  expect_equal(p1$inpatient_admissions_followup, 2)
  expect_equal(p1$inpatient_los_days_followup, 7)
  expect_equal(p1$icu_admissions_followup, 1)
  expect_equal(p1$emergency_visits_baseline, 1)
  expect_equal(p1$gp_visits_followup, 1)
  expect_equal(p1$specialist_visits_followup, 1)

  # Patient 2 checks
  p2 <- cohortEnriched |> dplyr::filter(.data$subject_id == 2L)
  expect_equal(p2$inpatient_admissions_followup, 1)
  expect_equal(p2$emergency_visits_followup, 1) # Attended by Emergency Medicine specialist provider 3
})

test_that("addVisits filters by specific settings", {
  cdm <- hermesTestCdm()

  # Only outpatient and emergency
  cohortEnriched <- cdm$target_cohort |>
    addVisits(
      window = list(baseline = c(-365, -1), followup = c(0, 365)),
      settings = c("outpatient", "emergency")
    ) |>
    dplyr::collect()

  cols <- colnames(cohortEnriched)
  expect_true("gp_visits_followup" %in% cols)
  expect_true("emergency_visits_followup" %in% cols)
  expect_false("inpatient_admissions_followup" %in% cols)
  expect_false("icu_admissions_followup" %in% cols)
})

test_that("addVisits unifies granular specialty stratification across settings", {
  cdm <- hermesTestCdm()

  cohortEnriched <- cdm$target_cohort |>
    addVisits(
      window = list(baseline = c(-365, -1), followup = c(0, 365)),
      settings = c("inpatient", "outpatient", "emergency"),
      stratifySpecialty = TRUE,
      specialties = list(
        general_practice = 38004446L,
        specialist_x = 38004477L,
        emergency_medicine = 38004510L
      )
    ) |>
    dplyr::collect()

  cols <- colnames(cohortEnriched)
  expect_true(all(c(
    "general_practice_inpatient_admissions_followup",
    "general_practice_visits_followup",
    "specialist_x_visits_followup",
    "emergency_medicine_emergency_visits_followup"
  ) %in% cols))

  p1 <- cohortEnriched |> dplyr::filter(.data$subject_id == 1L)
  expect_equal(p1$general_practice_inpatient_admissions_followup, 2)
  expect_equal(p1$specialist_x_visits_followup, 1)

  p2 <- cohortEnriched |> dplyr::filter(.data$subject_id == 2L)
  expect_equal(p2$emergency_medicine_emergency_visits_followup, 1)
})

test_that("addVisits supports infinite and NA window bounds with censorDate", {
  cdm <- hermesTestCdm()

  # 1. Whole follow-up window
  cohortEnriched <- cdm$target_cohort |>
    addVisits(
      window = c(0, Inf),
      settings = c("inpatient", "outpatient", "emergency")
    ) |>
    dplyr::collect()

  cols <- colnames(cohortEnriched)
  expect_true("inpatient_admissions_0_to_inf" %in% cols)
  expect_true("emergency_visits_0_to_inf" %in% cols)
  expect_true("gp_visits_0_to_inf" %in% cols)

  p1 <- cohortEnriched |> dplyr::filter(.data$subject_id == 1L)
  expect_equal(p1$inpatient_admissions_0_to_inf, 2)
  expect_equal(p1$emergency_visits_0_to_inf, 0)
  expect_equal(p1$gp_visits_0_to_inf, 1)

  # 2. Named window list with NA and censorDate
  cohortCensored <- cdm$target_cohort |>
    addVisits(
      window = list(baseline = c(-365, -1), all_followup = c(0, NA)),
      censorDate = "cohort_end_date"
    ) |>
    dplyr::collect()

  expect_true("inpatient_admissions_all_followup" %in% colnames(cohortCensored))
  expect_true("emergency_visits_all_followup" %in% colnames(cohortCensored))
})
