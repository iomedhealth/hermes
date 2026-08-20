test_that("addPrescriptions extracts fills, days supply, PDC, and infusions", {
  cdm <- hermes_test_cdm()

  cohort_enriched <- cdm$target_cohort |>
    addPrescriptions(
      window = list(baseline = c(-365, -1), followup = c(0, 365)),
      daysSupply = TRUE,
      pdc = TRUE
    ) |>
    dplyr::collect()

  expect_true(is.data.frame(cohort_enriched))
  expect_equal(nrow(cohort_enriched), nrow(cdm$target_cohort |> dplyr::collect()))

  cols <- colnames(cohort_enriched)
  expect_true(all(c(
    "rx_fills_baseline", "days_supply_baseline",
    "rx_fills_followup", "days_supply_followup", "pdc_followup",
    "infusions_followup"
  ) %in% cols))

  p1 <- cohort_enriched |> dplyr::filter(.data$subject_id == 1L)
  expect_equal(p1$rx_fills_baseline, 1)
  expect_equal(p1$days_supply_baseline, 30)
  expect_equal(p1$rx_fills_followup, 2)
  expect_equal(p1$infusions_followup, 1)
  expect_true(!is.na(p1$pdc_followup))
})

test_that("addPrescriptions supports infinite and NA window bounds", {
  cdm <- hermesTestCdm()

  resInf <- cdm$target_cohort |>
    addPrescriptions(window = c(0, Inf), daysSupply = TRUE, pdc = TRUE) |>
    dplyr::collect()

  expect_true("rx_fills_0_to_inf" %in% colnames(resInf))
  expect_true("days_supply_0_to_inf" %in% colnames(resInf))
  expect_true("pdc_0_to_inf" %in% colnames(resInf))

  p1 <- resInf |> dplyr::filter(.data$subject_id == 1L)
  expect_equal(p1$rx_fills_0_to_inf, 2)
})
