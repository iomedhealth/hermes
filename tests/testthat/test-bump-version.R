test_that("calculateNewVersion computes correct semantic versions", {
  rootPath <- testthat::test_path("../..")
  bumpScript <- file.path(rootPath, "extras", "bumpVersion.R")
  skip_if_not(file.exists(bumpScript), "bumpVersion.R script not found")
  source(bumpScript, local = TRUE)

  # Patch increment
  expect_equal(calculateNewVersion("0.6.1", "patch"), "0.6.2")
  expect_equal(calculateNewVersion("1.0.9", "patch"), "1.0.10")

  # Minor increment
  expect_equal(calculateNewVersion("0.6.1", "minor"), "0.7.0")
  expect_equal(calculateNewVersion("1.9.3", "minor"), "1.10.0")

  # Major increment
  expect_equal(calculateNewVersion("0.6.1", "major"), "1.0.0")
  expect_equal(calculateNewVersion("1.2.3", "major"), "2.0.0")

  # Explicit version
  expect_equal(calculateNewVersion("0.6.1", "0.7.0"), "0.7.0")
  expect_equal(calculateNewVersion("0.6.1", "1.0.0-rc1"), "1.0.0-rc1")

  # Error handling
  expect_error(calculateNewVersion("0.6.1", "invalid_type"))
  expect_error(calculateNewVersion("invalid_ver", "patch"))
})

test_that("updateDescriptionFile updates Version & internal bounds", {
  rootPath <- testthat::test_path("../..")
  bumpScript <- file.path(rootPath, "extras", "bumpVersion.R")
  skip_if_not(file.exists(bumpScript), "bumpVersion.R script not found")
  source(bumpScript, local = TRUE)

  tmpFile <- tempfile(fileext = ".dcf")
  sampleContent <- c(
    "Package: omopHeor",
    "Version: 0.6.1",
    "Imports:",
    "    CohortUtilisation (>= 0.6.1),",
    "    CohortCosts (>= 0.6.1),",
    "    CohortEconomics (>= 0.6.1),",
    "    CDMConnector (>= 1.4.0)"
  )
  writeLines(sampleContent, tmpFile)

  updateDescriptionFile(
    tmpFile,
    "0.7.0",
    internalPkgs = c("CohortUtilisation", "CohortCosts", "CohortEconomics")
  )

  updatedLines <- readLines(tmpFile)
  expect_true(any(grepl("^Version: 0\\.7\\.0$", updatedLines)))
  expect_true(any(grepl("CohortUtilisation \\(>= 0\\.7\\.0\\)", updatedLines)))
  expect_true(any(grepl("CohortCosts \\(>= 0\\.7\\.0\\)", updatedLines)))
  expect_true(any(grepl("CohortEconomics \\(>= 0\\.7\\.0\\)", updatedLines)))
  expect_true(any(grepl("CDMConnector \\(>= 1\\.4\\.0\\)", updatedLines)))
})
