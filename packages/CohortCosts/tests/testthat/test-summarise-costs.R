test_that("summariseCosts returns valid summarised_result and tableCosts formats it", {
  cdm <- hermesTestCdm()

  cohortEnriched <- cdm$target_cohort |>
    addCosts(window = list(followup = c(0, 365)))

  costRes <- summariseCosts(
    cohort = cohortEnriched,
    strata = list("cohort_definition_id")
  )

  expect_true(inherits(costRes, "summarised_result"))
  omopgenerics::validateResultArgument(costRes)

  # Table formatting - tibble
  tblDf <- tableCosts(costRes, type = "tibble")
  expect_true(is.data.frame(tblDf))

  # Table formatting - gt
  tblGt <- tableCosts(
    costRes,
    type = "gt",
    estimateName = c("Mean (SD)" = "<mean> (<sd>)")
  )
  expect_true(inherits(tblGt, "gt_tbl"))

  # Plot formatting
  pCostBar <- plotCosts(costRes, plotType = "barplot")
  expect_true(inherits(pCostBar, "ggplot"))
})
