test_that("Stage 5 sim works", {
  cdm <- hermes_test_cdm()
  study <- init(cdm)
  sim <- run_simulation(study)
  expect_true(inherits(sim, "hermes_sim"))
})
