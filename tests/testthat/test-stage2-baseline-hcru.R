test_that("Stage 2 baseline and hcru work", {
  cdm <- hermes_test_cdm()
  study <- init(cdm)
  hcru1 <- summarise_baseline(study)
  expect_true(inherits(hcru1, "hermes_hcru"))
  
  hcru2 <- extract_hcru(study)
  expect_true(inherits(hcru2, "hermes_hcru"))
  expect_true(!is.null(hcru2$cost_summary))
})
