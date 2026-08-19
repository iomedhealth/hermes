test_that("summariseUtilization returns a valid summarised_result object", {
  cdm <- hermes_test_cdm()

  cohort_enriched <- cdm$target_cohort |>
    addHospitalizations(window = list(followup = c(0, 365))) |>
    addOutpatientVisits(window = list(followup = c(0, 365))) |>
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

  # Table formatting
  tbl <- tableCosts(cost_res, type = "tibble")
  expect_true(is.data.frame(tbl))
})
