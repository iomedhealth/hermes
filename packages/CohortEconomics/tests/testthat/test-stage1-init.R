test_that("Stage 1 init returns hermes_study with valid cohorts and counts", {
  cdm <- hermes_test_cdm()

  # Create mock cohort table
  cohort <- tibble::tibble(
    cohort_definition_id = 1L,
    subject_id = 1L,
    cohort_start_date = as.Date("2010-01-01"),
    cohort_end_date = as.Date("2010-12-31")
  )

  cdm <- omopgenerics::insertTable(cdm, name = "target_cohort", table = cohort)
  cdm$target_cohort <- omopgenerics::newCohortTable(cdm$target_cohort)

  cdm <- omopgenerics::insertTable(cdm, name = "comparator_cohort", table = cohort)
  cdm$comparator_cohort <- omopgenerics::newCohortTable(cdm$comparator_cohort)

  cdm <- omopgenerics::insertTable(cdm, name = "outcome_cohort", table = cohort)
  cdm$outcome_cohort <- omopgenerics::newCohortTable(cdm$outcome_cohort)

  study <- init(
    cdm = cdm,
    target_cohort = "target_cohort",
    comparator_cohort = "comparator_cohort",
    outcome_cohort = "outcome_cohort"
  )

  expect_true(inherits(study, "hermes_study"))
  expect_equal(study$target_cohort, "target_cohort")
  expect_equal(study$comparator_cohort, "comparator_cohort")
  expect_equal(study$outcome_cohort, "outcome_cohort")

  expect_true(!is.null(study$cohort_counts))
  expect_true("target_cohort" %in% study$cohort_counts$cohort_name)
  expect_true("comparator_cohort" %in% study$cohort_counts$cohort_name)
  expect_true("outcome_cohort" %in% study$cohort_counts$cohort_name)
})

test_that("Stage 1 init fails when required cohorts are missing", {
  cdm <- hermes_test_cdm()

  expect_error(
    init(
      cdm = cdm,
      target_cohort = "missing_target",
      comparator_cohort = "missing_comparator",
      outcome_cohort = "missing_outcome"
    ),
    "Cohort table 'missing_target' not found in CDM"
  )
})
