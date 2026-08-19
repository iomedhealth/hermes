test_that("addOutpatientVisits validates input arguments", {
  cdm <- hermes_test_cdm()
  cohort <- cdm$target_cohort

  expect_error(addOutpatientVisits(list()), "Argument 'x' must be a cdm_table or cohort_table")
  expect_error(addOutpatientVisits(cohort, indexDate = "bad_col"), "indexDate 'bad_col' must be a column in x")
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
