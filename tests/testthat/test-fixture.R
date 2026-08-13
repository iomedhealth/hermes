test_that("T003 [US3] hermes_test_cdm initializes and populates cost and condition", {
  cdm <- hermes_test_cdm()
  expect_true(inherits(cdm, "cdm_reference"))
  expect_true("cost" %in% names(cdm))
  expect_true("condition_occurrence" %in% names(cdm))

  cost_df <- cdm$cost |> collect()
  expect_equal(nrow(cost_df), 3)
  expect_true(all(c("total_paid", "cost_domain_id", "cost_event_id") %in% colnames(cost_df)))

  cond_df <- cdm$condition_occurrence |> collect()
  expect_equal(nrow(cond_df), 3)
  expect_true(all(c(4285898L, 4266809L, 192671L) %in% cond_df$condition_concept_id))
})
