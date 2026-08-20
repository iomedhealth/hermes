test_that("summariseUtilization returns a valid summarised_result object", {
  cdm <- hermes_test_cdm()

  cohort_enriched <- cdm$target_cohort |>
    addHospitalizations(window = list(followup = c(0, 365))) |>
    addOutpatientVisits(
      window = list(followup = c(0, 365)),
      specialties = list(oncology = 38004507L, cardiology = 38004451L)
    ) |>
    addPrescriptions(window = list(followup = c(0, 365)))

  res <- summariseUtilization(
    cohort = cohort_enriched,
    strata = list("cohort_definition_id")
  )

  expect_true(inherits(res, "summarised_result"))
  omopgenerics::validateResultArgument(res)

  # Check that expected metrics are present in variable_name
  vars <- unique(res$variable_name)
  expect_true(any(grepl("inpatient_admissions", vars)))
  expect_true(any(grepl("emergency_visits", vars)))
  expect_true(any(grepl("oncology_visits", vars)))
  expect_true(any(grepl("cardiology_visits", vars)))
  expect_true(any(grepl("rx_fills", vars)))
})

test_that("summariseCosts returns valid summarised_result and tableUtilization formats it", {
  cdm <- hermes_test_cdm()

  cohort_enriched <- cdm$target_cohort |>
    addCosts(window = list(followup = c(0, 365)))

  cost_res <- summariseCosts(
    cohort = cohort_enriched,
    strata = list("cohort_definition_id")
  )

  expect_true(inherits(cost_res, "summarised_result"))
  omopgenerics::validateResultArgument(cost_res)

  # Table formatting - tibble
  tbl_df <- tableCosts(cost_res, type = "tibble")
  expect_true(is.data.frame(tbl_df))

  # Table formatting - gt
  tbl_gt <- tableCosts(
    cost_res,
    type = "gt",
    estimateName = c("Mean (SD)" = "<mean> (<sd>)")
  )
  expect_true(inherits(tbl_gt, "gt_tbl"))
})

test_that("plotUtilization and plotCosts produce valid ggplot visualizations", {
  cdm <- hermes_test_cdm()

  cohort_enriched <- cdm$target_cohort |>
    addHospitalizations(window = list(followup = c(0, 365))) |>
    addCosts(window = list(followup = c(0, 365)))

  res_util <- summariseUtilization(cohort = cohort_enriched)
  res_cost <- summariseCosts(cohort = cohort_enriched)

  # Bar plots
  p_util_bar <- plotUtilization(res_util, plotType = "barplot")
  expect_true(inherits(p_util_bar, "ggplot"))

  p_cost_bar <- plotCosts(res_cost, plotType = "barplot")
  expect_true(inherits(p_cost_bar, "ggplot"))

  # Box plots
  p_util_box <- plotUtilization(res_util, plotType = "boxplot")
  expect_true(inherits(p_util_box, "ggplot"))

  p_cost_box <- plotCosts(res_cost, plotType = "boxplot")
  expect_true(inherits(p_cost_box, "ggplot"))

  # Empty result warning
  empty_res <- omopgenerics::emptySummarisedResult()
  expect_warning(p_empty <- plotUtilization(empty_res))
  expect_true(inherits(p_empty, "ggplot"))
})
