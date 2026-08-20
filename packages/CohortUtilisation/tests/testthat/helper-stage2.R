# Helper for stage 2
library(omopgenerics)

hermes_test_study <- function(env = parent.frame()) {
  cdm <- hermes_test_cdm(env)

  # create mock cohort tables with multiple patients
  target <- tibble::tibble(
    cohort_definition_id = 1L,
    subject_id = c(1L, 2L),
    cohort_start_date = as.Date(c("2010-01-01", "2010-01-01")),
    cohort_end_date = as.Date(c("2010-12-31", "2010-12-31"))
  )

  comparator <- tibble::tibble(
    cohort_definition_id = 1L,
    subject_id = 3L,
    cohort_start_date = as.Date("2010-01-01"),
    cohort_end_date = as.Date("2010-12-31")
  )

  outcome <- tibble::tibble(
    cohort_definition_id = 1L,
    subject_id = 1L,
    cohort_start_date = as.Date("2010-06-01"),
    cohort_end_date = as.Date("2010-06-01")
  )

  cdm <- omopgenerics::insertTable(cdm, name = "target_cohort", table = target)
  cdm$target_cohort <- omopgenerics::newCohortTable(cdm$target_cohort)

  cdm <- omopgenerics::insertTable(cdm, name = "comparator_cohort", table = comparator)
  cdm$comparator_cohort <- omopgenerics::newCohortTable(cdm$comparator_cohort)

  cdm <- omopgenerics::insertTable(cdm, name = "outcome_cohort", table = outcome)
  cdm$outcome_cohort <- omopgenerics::newCohortTable(cdm$outcome_cohort)

  study <- init(cdm, "target_cohort", "comparator_cohort", "outcome_cohort")
  return(study)
}

hermesTestStudy <- hermes_test_study
