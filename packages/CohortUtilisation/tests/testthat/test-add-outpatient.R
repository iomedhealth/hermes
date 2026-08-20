test_that("addOutpatientVisits validates input arguments", {
  cdm <- hermes_test_cdm()
  cohort <- cdm$target_cohort

  expect_error(addOutpatientVisits(list()), "Argument 'x' must be a cdm_table or cohort_table")
  expect_error(addOutpatientVisits(cohort, indexDate = "bad_col"), "indexDate 'bad_col' must be a column in x")
  expect_error(addOutpatientVisits(cohort, specialties = "not_a_list"), "must be a named list")
  expect_error(addOutpatientVisits(cohort, specialties = list(123)), "must be a named list")
})

test_that("addOutpatientVisits stratifies GP, Specialist, and Emergency visits", {
  cdm <- hermes_test_cdm()

  cohort_enriched <- cdm$target_cohort |>
    addOutpatientVisits(
      window = list(baseline = c(-365, -1), followup = c(0, 365)),
      stratifySpecialty = TRUE
    ) |>
    dplyr::collect()

  expect_true(is.data.frame(cohort_enriched))
  expect_equal(nrow(cohort_enriched), nrow(cdm$target_cohort |> dplyr::collect()))

  cols <- colnames(cohort_enriched)
  expect_true(all(c(
    "emergency_visits_baseline", "gp_visits_baseline", "specialist_visits_baseline",
    "emergency_visits_followup", "gp_visits_followup", "specialist_visits_followup"
  ) %in% cols))

  # Patient 1 has 1 ED visit in baseline, 1 GP and 1 Specialist in followup
  p1 <- cohort_enriched |> dplyr::filter(.data$subject_id == 1L)
  expect_equal(p1$emergency_visits_baseline, 1)
  expect_equal(p1$gp_visits_baseline, 0)
  expect_equal(p1$gp_visits_followup, 1)
  expect_equal(p1$specialist_visits_followup, 1)
})

test_that("addOutpatientVisits computes granular specialty breakdowns", {
  cdm <- hermes_test_cdm()

  # Provider 2 in helper-eunomia has specialty 38004477L
  cohort_enriched <- cdm$target_cohort |>
    addOutpatientVisits(
      window = list(baseline = c(-365, -1), followup = c(0, 365)),
      stratifySpecialty = TRUE,
      specialties = list(
        oncology = c(38004507L, 38004006L),
        hematology = 38004501L,
        specialty_x = 38004477L
      )
    ) |>
    dplyr::collect()

  cols <- colnames(cohort_enriched)
  expect_true(all(c(
    "oncology_visits_baseline", "oncology_visits_followup",
    "hematology_visits_baseline", "hematology_visits_followup",
    "specialty_x_visits_baseline", "specialty_x_visits_followup"
  ) %in% cols))

  p1 <- cohort_enriched |> dplyr::filter(.data$subject_id == 1L)
  expect_equal(p1$oncology_visits_followup, 0)
  expect_equal(p1$hematology_visits_followup, 0)
  expect_equal(p1$specialty_x_visits_followup, 1) # Visit 6 with provider 2 (specialty 38004477L)

  p2 <- cohort_enriched |> dplyr::filter(.data$subject_id == 2L)
  expect_equal(p2$oncology_visits_followup, 0)
  expect_equal(p2$specialty_x_visits_followup, 0)
})

test_that("addOutpatientVisits supports infinite and NA window bounds", {
  cdm <- hermesTestCdm()

  resInf <- cdm$target_cohort |>
    addOutpatientVisits(window = c(0, Inf)) |>
    dplyr::collect()

  expect_true("gp_visits_0_to_inf" %in% colnames(resInf))
  expect_true("specialist_visits_0_to_inf" %in% colnames(resInf))
  p1 <- resInf |> dplyr::filter(.data$subject_id == 1L)
  expect_equal(p1$gp_visits_0_to_inf, 1)
  expect_equal(p1$specialist_visits_0_to_inf, 1)

  resNa <- cdm$target_cohort |>
    addOutpatientVisits(window = list(c(0, NA))) |>
    dplyr::collect()

  expect_equal(resInf, resNa)
})
