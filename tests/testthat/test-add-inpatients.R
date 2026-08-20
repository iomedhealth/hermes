test_that("addInpatients validates input arguments correctly", {
  cdm <- hermesTestCdm()
  cohort <- cdm$target_cohort

  expect_error(addInpatients(list()), "Argument 'x' must be a cdm_table or cohort_table")
  expect_error(addInpatients(cohort, indexDate = "not_a_col"), "indexDate 'not_a_col' must be a column in x")
  expect_error(addInpatients(cohort, window = list(c(10, 0))), "Window interval \\[10, 0\\] is invalid")
  expect_error(addInpatients(cohort, specialties = "not_a_list"), "must be a named list")
  expect_error(addInpatients(cohort, specialties = list(123)), "must be a named list")
})

test_that("addInpatients computes admissions, LOS, ICU stays, and readmissions", {
  cdm <- hermesTestCdm()

  cohortEnriched <- cdm$target_cohort |>
    addInpatients(
      window = list(baseline = c(-365, -1), followup = c(0, 365)),
      readmissions = TRUE
    ) |>
    dplyr::collect()

  expect_true(is.data.frame(cohortEnriched))
  expect_equal(nrow(cohortEnriched), nrow(cdm$target_cohort |> dplyr::collect()))

  cols <- colnames(cohortEnriched)
  expect_true(all(c(
    "inpatient_admissions_baseline", "inpatient_los_days_baseline",
    "inpatient_admissions_followup", "inpatient_los_days_followup",
    "icu_admissions_followup", "icu_los_days_followup",
    "readmissions_30d_followup"
  ) %in% cols))

  # Patient 1 has 2 inpatient admissions (4 + 3 = 7 days LOS), 1 ICU (2 days), 1 30d readmission in followup
  p1 <- cohortEnriched |> dplyr::filter(.data$subject_id == 1L)
  expect_equal(p1$inpatient_admissions_followup, 2)
  expect_equal(p1$inpatient_los_days_followup, 7)
  expect_equal(p1$icu_admissions_followup, 1)
  expect_equal(p1$icu_los_days_followup, 2)
  expect_equal(p1$readmissions_30d_followup, 1)
})

test_that("addInpatients detects ICU stays via provider icuSpecialtyConceptIds", {
  cdm <- hermesTestCdm()

  # Update provider table so provider 1 has specialty 38004500 (Critical care intensivist)
  provDf <- cdm$provider |> dplyr::collect()
  provDf$specialty_concept_id[provDf$provider_id == 1L] <- 38004500L
  cdm <- omopgenerics::insertTable(cdm, name = "provider", table = provDf, overwrite = TRUE)

  cohortEnriched <- cdm$target_cohort |>
    addInpatients(
      window = list(baseline = c(-365, -1), followup = c(0, 365)),
      icuSpecialtyConceptIds = c(38004500L),
      readmissions = FALSE
    ) |>
    dplyr::collect()

  p1 <- cohortEnriched |> dplyr::filter(.data$subject_id == 1L)
  expect_equal(p1$inpatient_admissions_followup, 0)
  expect_equal(p1$inpatient_los_days_followup, 0)
  expect_equal(p1$icu_admissions_followup, 3)
  expect_equal(p1$icu_los_days_followup, 9)
})

test_that("addInpatients computes granular specialty breakdowns", {
  cdm <- hermesTestCdm()

  # Provider 1 has specialty 38004446L (General Practice)
  cohortEnriched <- cdm$target_cohort |>
    addInpatients(
      window = list(baseline = c(-365, -1), followup = c(0, 365)),
      stratifySpecialty = TRUE,
      specialties = list(
        general_practice = 38004446L,
        cardiology = 38004453L
      )
    ) |>
    dplyr::collect()

  cols <- colnames(cohortEnriched)
  expect_true(all(c(
    "general_practice_inpatient_admissions_baseline",
    "general_practice_inpatient_admissions_followup",
    "cardiology_inpatient_admissions_baseline",
    "cardiology_inpatient_admissions_followup"
  ) %in% cols))

  # Patient 1 has 2 general inpatient admissions with provider 1 (specialty 38004446L) in followup
  p1 <- cohortEnriched |> dplyr::filter(.data$subject_id == 1L)
  expect_equal(p1$general_practice_inpatient_admissions_followup, 2)
  expect_equal(p1$cardiology_inpatient_admissions_followup, 0)

  # Patient 2 has 1 inpatient admission with provider 1 in followup
  p2 <- cohortEnriched |> dplyr::filter(.data$subject_id == 2L)
  expect_equal(p2$general_practice_inpatient_admissions_followup, 1)
  expect_equal(p2$cardiology_inpatient_admissions_followup, 0)
})

test_that("addHospitalizations and addInpatient backward-compatibility aliases work identically", {
  cdm <- hermesTestCdm()

  res1 <- cdm$target_cohort |>
    addInpatients(window = list(followup = c(0, 365))) |>
    dplyr::collect()

  res2 <- cdm$target_cohort |>
    addHospitalizations(window = list(followup = c(0, 365))) |>
    dplyr::collect()

  res3 <- cdm$target_cohort |>
    addInpatient(window = list(followup = c(0, 365))) |>
    dplyr::collect()

  expect_equal(res1, res2)
  expect_equal(res1, res3)
})
