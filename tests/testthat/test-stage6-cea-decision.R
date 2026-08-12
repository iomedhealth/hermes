test_that("Stage 6 cea works", {
  cdm <- hermes_test_cdm()
  study <- init(cdm)
  cea <- compute_cea(study)
  expect_true(inherits(cea, "hermes_cea"))
  
  # Also verify the other functions don't error out
  expect_error(plot_ceac(cea), NA)
  expect_error(plot_plane(cea), NA)
  expect_error(table_summary(cea), NA)
})
