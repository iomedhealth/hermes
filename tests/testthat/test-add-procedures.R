test_that("addProcedures extracts labs, imaging, and procedure occurrences", {
  cdm <- hermes_test_cdm()

  cohort_enriched <- cdm$target_cohort |>
    addProcedures(
      window = list(baseline = c(-365, -1), followup = c(0, 365))
    ) |>
    dplyr::collect()

  expect_true(is.data.frame(cohort_enriched))
  expect_equal(nrow(cohort_enriched), nrow(cdm$target_cohort |> dplyr::collect()))

  cols <- colnames(cohort_enriched)
  expect_true(all(c(
    "lab_tests_count_baseline", "procedures_count_baseline",
    "lab_tests_count_followup", "procedures_count_followup"
  ) %in% cols))

  p1 <- cohort_enriched |> dplyr::filter(.data$subject_id == 1L)
  expect_equal(p1$lab_tests_count_baseline, 1)
  expect_equal(p1$procedures_count_baseline, 1)
  expect_equal(p1$lab_tests_count_followup, 1)
  expect_equal(p1$procedures_count_followup, 1)
})
