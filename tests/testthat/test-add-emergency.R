test_that("addEmergencyCare validates input arguments correctly", {
  cdm <- hermesTestCdm()
  cohort <- cdm$target_cohort

  expect_error(addEmergencyCare(list()), "Argument 'x' must be a cdm_table or cohort_table")
  expect_error(addEmergencyCare(cohort, indexDate = "not_a_col"), "indexDate 'not_a_col' must be a column in x")
  expect_error(addEmergencyCare(cohort, window = list(c(10, 0))), "Window interval \\[10, 0\\] is invalid")
  expect_error(addEmergencyCare(cohort, specialties = "not_a_list"), "must be a named list")
})

test_that("addEmergencyCare detects emergency encounters via visit concept IDs and provider specialties", {
  cdm <- hermesTestCdm()

  # Person 1 has:
  # - Visit 4 (concept 9203L, provider 1) in baseline (2009-10-01)
  # Person 2 has:
  # - Visit 9 (concept 9202L, provider 3 with specialty 38004510L Emergency Medicine) in followup (2010-06-01)

  cohortEnriched <- cdm$target_cohort |>
    addEmergencyCare(
      window = list(baseline = c(-365, -1), followup = c(0, 365))
    ) |>
    dplyr::collect()

  expect_true(is.data.frame(cohortEnriched))
  expect_equal(nrow(cohortEnriched), nrow(cdm$target_cohort |> dplyr::collect()))

  cols <- colnames(cohortEnriched)
  expect_true(all(c("emergency_visits_baseline", "emergency_visits_followup") %in% cols))

  # Patient 1 has 1 ER visit in baseline, 0 in followup
  p1 <- cohortEnriched |> dplyr::filter(.data$subject_id == 1L)
  expect_equal(p1$emergency_visits_baseline, 1)
  expect_equal(p1$emergency_visits_followup, 0)

  # Patient 2 has 0 in baseline, 1 in followup (detected via provider specialty 38004510L!)
  p2 <- cohortEnriched |> dplyr::filter(.data$subject_id == 2L)
  expect_equal(p2$emergency_visits_baseline, 0)
  expect_equal(p2$emergency_visits_followup, 1)
})

test_that("addEmergencyCare stratifies by granular specialty", {
  cdm <- hermesTestCdm()

  cohortEnriched <- cdm$target_cohort |>
    addEmergencyCare(
      window = list(baseline = c(-365, -1), followup = c(0, 365)),
      stratifySpecialty = TRUE,
      specialties = list(
        general_practice = 38004446L,
        emergency_medicine = 38004510L
      )
    ) |>
    dplyr::collect()

  cols <- colnames(cohortEnriched)
  expect_true(all(c(
    "emergency_visits_baseline", "emergency_visits_followup",
    "general_practice_emergency_visits_baseline", "general_practice_emergency_visits_followup",
    "emergency_medicine_emergency_visits_baseline", "emergency_medicine_emergency_visits_followup"
  ) %in% cols))

  p1 <- cohortEnriched |> dplyr::filter(.data$subject_id == 1L)
  expect_equal(p1$general_practice_emergency_visits_baseline, 1)
  expect_equal(p1$emergency_medicine_emergency_visits_baseline, 0)

  p2 <- cohortEnriched |> dplyr::filter(.data$subject_id == 2L)
  expect_equal(p2$general_practice_emergency_visits_followup, 0)
  expect_equal(p2$emergency_medicine_emergency_visits_followup, 1)
})

test_that("addEmergency and addEmergencyVisits aliases work identically", {
  cdm <- hermesTestCdm()

  res1 <- cdm$target_cohort |>
    addEmergencyCare(window = list(followup = c(0, 365))) |>
    dplyr::collect()

  res2 <- cdm$target_cohort |>
    addEmergency(window = list(followup = c(0, 365))) |>
    dplyr::collect()

  res3 <- cdm$target_cohort |>
    addEmergencyVisits(window = list(followup = c(0, 365))) |>
    dplyr::collect()

  expect_equal(res1, res2)
  expect_equal(res1, res3)
})
