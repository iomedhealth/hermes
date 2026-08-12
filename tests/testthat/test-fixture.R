test_that("hermes_test_cdm initializes and populates cost", {
  cdm <- hermes_test_cdm()
  expect_true(inherits(cdm, "cdm_reference"))
  expect_true("cost" %in% names(cdm))

  cost_df <- cdm$cost |> collect()
  expect_true(nrow(cost_df) > 0)
  expect_true("total_paid" %in% colnames(cost_df))
})
