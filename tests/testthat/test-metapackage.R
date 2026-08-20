test_that("hermes metapackage re-exports functions from all 3 sub-packages", {
  # CohortUtilisation
  expect_true(exists("addInpatients", mode = "function"))
  expect_true(exists("addEmergencyCare", mode = "function"))
  expect_true(exists("addOutpatientVisits", mode = "function"))
  expect_true(exists("addVisits", mode = "function"))
  expect_true(exists("addPrescriptions", mode = "function"))
  expect_true(exists("addProcedures", mode = "function"))
  expect_true(exists("summariseUtilization", mode = "function"))

  # CohortCosts
  expect_true(exists("addCosts", mode = "function"))
  expect_true(exists("summariseCosts", mode = "function"))
  expect_true(exists("tableCosts", mode = "function"))

  # CohortEconomics
  expect_true(exists("init", mode = "function"))
  expect_true(exists("fit_ps", mode = "function"))
  expect_true(exists("compile_trajectories", mode = "function"))
  expect_true(exists("simulate_economics", mode = "function"))
  expect_true(exists("run_cea", mode = "function"))
})

test_that("hermes end-to-end multi-domain workflow executes cleanly", {
  cdm <- hermesTestCdm()

  # Full pipeline using re-exported functions
  cohortEnriched <- cdm$target_cohort |>
    addVisits(window = list(baseline = c(-365, -1), followup = c(0, 365))) |>
    addCosts(window = list(followup = c(0, 365)))

  expect_true(inherits(cohortEnriched, "cohort_table"))
  cols <- colnames(cohortEnriched |> dplyr::collect())
  expect_true("inpatient_admissions_followup" %in% cols)
  expect_true("cost_total_followup" %in% cols)
})
