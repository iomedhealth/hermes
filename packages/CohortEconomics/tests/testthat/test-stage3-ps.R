test_that("T003/T004/T005/T006: fit_ps and adjust_ps extract covariates and match", {
  Sys.setenv(EUNOMIA_DATA_FOLDER = file.path(tempdir(), "eunomia"))
  con <- DBI::dbConnect(duckdb::duckdb(), CDMConnector::eunomiaDir("GiBleed"))
  withr::defer(DBI::dbDisconnect(con, shutdown = TRUE))

  cdm <- CDMConnector::cdmFromCon(con, cdmSchema = "main", writeSchema = "main")

  # Create real cohorts from GiBleed
  cdm$target_cohort <- CohortConstructor::conceptCohort(
    cdm = cdm,
    conceptSet = list(target_cohort = 4285898L),
    name = "target_cohort"
  )

  cdm$comparator_cohort <- CohortConstructor::conceptCohort(
    cdm = cdm,
    conceptSet = list(comparator_cohort = 4266809L),
    name = "comparator_cohort"
  )

  cdm$outcome_cohort <- CohortConstructor::conceptCohort(
    cdm = cdm,
    conceptSet = list(outcome_cohort = 192671L),
    name = "outcome_cohort"
  )

  study <- init(cdm, "target_cohort", "comparator_cohort", "outcome_cohort")
  study <- summarise_baseline(study)
  study <- extract_hcru(study)

  # fit_ps should populate cm_data and model
  ps_obj <- fit_ps(study)

  expect_s3_class(ps_obj, "hermes_ps")
  expect_true(!is.null(ps_obj$cm_data))
  expect_true(!is.null(ps_obj$model))

  expect_true(all(c("subject_id", "treatment", "age", "sex", "sex_num", "cohort_start_date") %in% colnames(ps_obj$cm_data)))
  expect_true("propensity_score" %in% colnames(ps_obj$cm_data))

  # adjust_ps should populate matched_pop
  ps_obj <- adjust_ps(ps_obj)
  expect_true(is.data.frame(ps_obj$matched_pop))
  expect_gt(nrow(ps_obj$matched_pop), 0)
  expect_true(all(c("subject_id", "treatment", "propensity_score", "cohort_start_date") %in% colnames(ps_obj$matched_pop)))
})
