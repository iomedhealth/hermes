test_that("T005 [US2] baseline demographics and comorbidity generation", {
  cdm <- hermes_test_cdm()

  # create mock cohort tables
  target <- tibble::tibble(
    cohort_definition_id = 1L,
    subject_id = 1L,
    cohort_start_date = as.Date("2010-01-01"),
    cohort_end_date = as.Date("2010-12-31")
  )

  DBI::dbWriteTable(attr(cdm, "dbcon"), "target_cohort", target)
  DBI::dbWriteTable(attr(cdm, "dbcon"), "comparator_cohort", target)
  DBI::dbWriteTable(attr(cdm, "dbcon"), "outcome_cohort", target)

  cdm <- CDMConnector::cdmFromCon(attr(cdm, "dbcon"), cdmSchema = "main", writeSchema = "main")

  cdm$target_cohort <- dplyr::tbl(attr(cdm, "dbcon"), "target_cohort")
  cdm$comparator_cohort <- dplyr::tbl(attr(cdm, "dbcon"), "comparator_cohort")
  cdm$outcome_cohort <- dplyr::tbl(attr(cdm, "dbcon"), "outcome_cohort")

  cdm$target_cohort <- omopgenerics::newCohortTable(cdm$target_cohort)
  cdm$comparator_cohort <- omopgenerics::newCohortTable(cdm$comparator_cohort)
  cdm$outcome_cohort <- omopgenerics::newCohortTable(cdm$outcome_cohort)

  study <- init(cdm, "target_cohort", "comparator_cohort", "outcome_cohort")

  hcru <- summarise_baseline(study)

  expect_true(inherits(hcru, "hermes_hcru"))
  expect_true(!is.null(hcru$baseline_summary))
  expect_true(inherits(hcru$baseline_summary, "summarised_result"))
})

test_that("T006 [US2] HCRU unadjusted care utilization and medical cost extraction", {
  cdm <- hermes_test_cdm()

  # create mock cohort tables
  target <- tibble::tibble(
    cohort_definition_id = 1L,
    subject_id = 1L,
    cohort_start_date = as.Date("2010-01-01"),
    cohort_end_date = as.Date("2010-12-31")
  )

  DBI::dbWriteTable(attr(cdm, "dbcon"), "target_cohort", target)
  DBI::dbWriteTable(attr(cdm, "dbcon"), "comparator_cohort", target)
  DBI::dbWriteTable(attr(cdm, "dbcon"), "outcome_cohort", target)

  cdm <- CDMConnector::cdmFromCon(attr(cdm, "dbcon"), cdmSchema = "main", writeSchema = "main")

  cdm$target_cohort <- dplyr::tbl(attr(cdm, "dbcon"), "target_cohort")
  cdm$comparator_cohort <- dplyr::tbl(attr(cdm, "dbcon"), "comparator_cohort")
  cdm$outcome_cohort <- dplyr::tbl(attr(cdm, "dbcon"), "outcome_cohort")

  cdm$target_cohort <- omopgenerics::newCohortTable(cdm$target_cohort)
  cdm$comparator_cohort <- omopgenerics::newCohortTable(cdm$comparator_cohort)
  cdm$outcome_cohort <- omopgenerics::newCohortTable(cdm$outcome_cohort)

  study <- init(cdm, "target_cohort", "comparator_cohort", "outcome_cohort")

  # Create a dummy hcru object like it passed from summarise_baseline
  hcru_in <- structure(study, class = c("hermes_hcru", "hermes_study", "list"))

  hcru_out <- extract_hcru(hcru_in)

  expect_true(inherits(hcru_out, "hermes_hcru"))
  expect_true(!is.null(hcru_out$costs))
  expect_true(is.data.frame(hcru_out$costs))

  # Should have 1 row since we group by cost_domain_id ("Condition")
  expect_equal(nrow(hcru_out$costs), 1)
  expect_equal(hcru_out$costs$record_count, 3)
  expect_equal(sum(hcru_out$costs$total_paid), 450) # 100 + 150 + 200
})
