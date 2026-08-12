test_that("Stage 1 init returns hermes_study", {
  cdm <- hermes_test_cdm()
  study <- init(cdm)
  expect_true(inherits(study, "hermes_study"))
})
