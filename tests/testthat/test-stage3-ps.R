# tests/testthat/test-stage3-ps.R

test_that("T014: fit_ps, adjust_ps, and assess_balance generate hermes_ps object with model and matched population", {
  # Use the dummy hcru_obj for testing since full cm_data takes long to generate
  dummy_hcru <- list(cm_data = NULL)
  class(dummy_hcru) <- "hermes_hcru"

  # T015: fit_ps
  ps_obj <- fit_ps(dummy_hcru)

  # T017: Ensure return is hermes_ps
  expect_s3_class(ps_obj, "hermes_ps")
  expect_true("model" %in% names(ps_obj))

  # T015: adjust_ps
  adjusted_ps <- adjust_ps(ps_obj)
  expect_s3_class(adjusted_ps, "hermes_ps")
  expect_true("matched_pop" %in% names(adjusted_ps))

  # T016: assess_balance
  balanced_ps <- assess_balance(adjusted_ps)
  expect_s3_class(balanced_ps, "hermes_ps")
  expect_true("smd_summary" %in% names(balanced_ps))
})
