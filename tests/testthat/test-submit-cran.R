test_that("resolveTargets correctly maps targets to relative paths", {
  scriptPath <- file.path(testthat::test_path("../.."), "extras", "submitCran.R")
  skip_if_not(file.exists(scriptPath), "submitCran.R script not found")
  source(scriptPath, local = TRUE)

  # Wave 1
  expect_equal(resolveTargets("wave1"), c("packages/CohortUtilisation", "packages/CohortCosts"))
  expect_equal(resolveTargets("foundation"), c("packages/CohortUtilisation", "packages/CohortCosts"))

  # Wave 2
  expect_equal(resolveTargets("wave2"), c("packages/CohortEconomics"))
  expect_equal(resolveTargets("analytics"), c("packages/CohortEconomics"))

  # Wave 3
  expect_equal(resolveTargets("wave3"), c("."))
  expect_equal(resolveTargets("metapackage"), c("."))
  expect_equal(resolveTargets("omopHeor"), c("."))

  # Single packages
  expect_equal(resolveTargets("CohortUtilisation"), c("packages/CohortUtilisation"))
  expect_equal(resolveTargets("CohortCosts"), c("packages/CohortCosts"))

  # All
  expect_equal(resolveTargets("all"), c("packages/CohortUtilisation", "packages/CohortCosts", "packages/CohortEconomics", "."))

  # Error handling
  expect_error(resolveTargets("invalid_target"))
})

test_that("submitCran dryRun builds archives without submitting", {
  scriptPath <- file.path(testthat::test_path("../.."), "extras", "submitCran.R")
  skip_if_not(file.exists(scriptPath), "submitCran.R script not found")
  source(scriptPath, local = TRUE)

  res <- submitCran(target = "CohortCosts", dryRun = TRUE, document = FALSE)
  expect_type(res, "list")
  expect_true("packages/CohortCosts" %in% names(res))
  expect_true(file.exists(res[["packages/CohortCosts"]]))
  expect_true(grepl("CohortCosts_.*\\.tar\\.gz$", res[["packages/CohortCosts"]]))
})
