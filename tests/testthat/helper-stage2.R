# Helper for stage 2
library(omopgenerics)

hermes_test_study <- function(env = parent.frame()) {
  cdm <- hermes_test_cdm(env)

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

  cdm$target_cohort <- newCohortTable(cdm$target_cohort)
  cdm$comparator_cohort <- newCohortTable(cdm$comparator_cohort)
  cdm$outcome_cohort <- newCohortTable(cdm$outcome_cohort)

  study <- init(cdm, "target_cohort", "comparator_cohort", "outcome_cohort")
  return(study)
}
