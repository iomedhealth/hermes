test_that("addCosts extracts and aggregates domain and total costs", {
  cdm <- hermes_test_cdm()

  cohort_enriched <- cdm$target_cohort |>
    addCosts(
      window = list(baseline = c(-365, -1), followup = c(0, 365)),
      costField = "total_paid"
    ) |>
    dplyr::collect()

  expect_true(is.data.frame(cohort_enriched))
  expect_equal(nrow(cohort_enriched), nrow(cdm$target_cohort |> dplyr::collect()))

  cols <- colnames(cohort_enriched)
  expect_true(all(c(
    "cost_inpatient_followup", "cost_drug_followup",
    "cost_procedure_followup", "cost_total_followup"
  ) %in% cols))

  p1 <- cohort_enriched |> dplyr::filter(.data$subject_id == 1L)
  expect_equal(p1$cost_inpatient_followup, 2000)
  expect_equal(p1$cost_drug_followup, 80)
  expect_equal(p1$cost_procedure_followup, 300)
  expect_gte(p1$cost_total_followup, 2000)
})

test_that("addCosts supports infinite and NA window bounds", {
  cdm <- hermesTestCdm()

  resInf <- cdm$target_cohort |>
    addCosts(window = c(0, Inf)) |>
    dplyr::collect()

  expect_true("cost_total_0_to_inf" %in% colnames(resInf))
  expect_true("cost_inpatient_0_to_inf" %in% colnames(resInf))

  p1 <- resInf |> dplyr::filter(.data$subject_id == 1L)
  expect_gte(p1$cost_total_0_to_inf, 2000)
})
