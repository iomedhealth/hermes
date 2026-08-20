test_that("summariseUtilization returns a valid summarised_result object", {
  cdm <- hermesTestCdm()

  cohortEnriched <- cdm$target_cohort |>
    addInpatients(window = list(followup = c(0, 365))) |>
    addOutpatientVisits(
      window = list(followup = c(0, 365)),
      specialties = list(oncology = 38004507L, cardiology = 38004451L)
    ) |>
    addPrescriptions(window = list(followup = c(0, 365)))

  res <- summariseUtilization(
    cohort = cohortEnriched,
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

test_that("tableUtilization and plotUtilization format and plot results", {
  cdm <- hermesTestCdm()

  cohortEnriched <- cdm$target_cohort |>
    addInpatients(window = list(followup = c(0, 365)))

  resUtil <- summariseUtilization(cohort = cohortEnriched)

  # Bar plots
  pUtilBar <- plotUtilization(resUtil, plotType = "barplot")
  expect_true(inherits(pUtilBar, "ggplot"))

  # Box/point plots
  pUtilBox <- plotUtilization(resUtil, plotType = "boxplot")
  expect_true(inherits(pUtilBox, "ggplot"))

  # Empty result warning
  emptyRes <- omopgenerics::emptySummarisedResult()
  expect_warning(pEmpty <- plotUtilization(emptyRes))
  expect_true(inherits(pEmpty, "ggplot"))
})
