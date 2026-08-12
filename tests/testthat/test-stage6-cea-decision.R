test_that("Stage 6 cea works", {
  cdm <- hermes_test_cdm()
  study <- init(cdm)
  cea <- compute_cea(study)
  expect_true(inherits(cea, "hermes_cea"))
})
