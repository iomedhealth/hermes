test_that("Stage 3 ps works", {
  cdm <- hermes_test_cdm()
  study <- init(cdm)
  ps1 <- fit_ps(study)
  expect_true(inherits(ps1, "hermes_ps"))
  
  ps2 <- adjust_ps(study)
  expect_true(inherits(ps2, "hermes_ps"))
  
  ps3 <- assess_balance(study)
  expect_true(inherits(ps3, "hermes_ps"))
})
