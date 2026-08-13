library(CDMConnector)
library(dplyr)
library(omopgenerics)

Sys.setenv(EUNOMIA_DATA_FOLDER = file.path(tempdir(), "eunomia"))
con <- DBI::dbConnect(duckdb::duckdb(), CDMConnector::eunomiaDir("GiBleed"))
cdm <- CDMConnector::cdmFromCon(con, cdmSchema = "main", writeSchema = "main")

cohort <- cdm$condition_occurrence |>
  inner_join(cdm$observation_period, by = "person_id") |>
  filter(condition_start_date >= observation_period_start_date, condition_start_date <= observation_period_end_date) |>
  select(subject_id = person_id, cohort_start_date = condition_start_date, cohort_end_date = condition_start_date) |>
  mutate(cohort_definition_id = 1L) |>
  distinct(subject_id, cohort_definition_id, .keep_all = TRUE)

target_cohort <- cohort |>
  filter(subject_id %% 2 == 0) |>
  compute(name = "target_cohort", temporary = FALSE)
comparator_cohort <- cohort |>
  filter(subject_id %% 2 == 1) |>
  compute(name = "comparator_cohort", temporary = FALSE)
outcome_cohort <- cohort |>
  filter(subject_id %% 5 == 0) |>
  compute(name = "outcome_cohort", temporary = FALSE)

cdm$target_cohort <- omopgenerics::newCohortTable(target_cohort)
cdm$comparator_cohort <- omopgenerics::newCohortTable(comparator_cohort)
cdm$outcome_cohort <- omopgenerics::newCohortTable(outcome_cohort)

print(cohortCount(cdm$target_cohort))
print(cohortCount(cdm$comparator_cohort))

cat("Costs:", cdm$cost |> tally() |> pull(), "\n")
DBI::dbDisconnect(con, shutdown = TRUE)
