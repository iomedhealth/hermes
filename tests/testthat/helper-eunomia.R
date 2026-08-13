library(CDMConnector)
library(omopgenerics)
library(dplyr)
library(dbplyr)

hermes_test_cdm <- function(env = parent.frame()) {
  # Initialize an empty duckdb
  con <- DBI::dbConnect(duckdb::duckdb(), ":memory:")

  # Auto-teardown
  withr::defer(DBI::dbDisconnect(con, shutdown = TRUE), envir = env)

  # Create synthetic OMOP tables
  person <- tibble::tibble(
    person_id = 1L, gender_concept_id = 0L, year_of_birth = 1980L,
    race_concept_id = 0L, ethnicity_concept_id = 0L
  )
  observation_period <- tibble::tibble(
    observation_period_id = 1L, person_id = 1L,
    observation_period_start_date = as.Date("2000-01-01"),
    observation_period_end_date = as.Date("2020-12-31"),
    period_type_concept_id = 0L
  )
  condition_occurrence <- tibble::tibble(
    condition_occurrence_id = c(1L, 2L, 3L),
    person_id = c(1L, 1L, 1L),
    condition_concept_id = c(4285898L, 4266809L, 192671L),
    condition_start_date = as.Date(c("2010-01-01", "2010-06-01", "2010-12-01")),
    condition_end_date = as.Date(c("2010-01-10", "2010-06-10", "2010-12-10")),
    condition_type_concept_id = 0L
  )
  cost <- tibble::tibble(
    cost_id = c(1L, 2L, 3L),
    cost_event_id = c(1L, 2L, 3L),
    cost_domain_id = rep("Condition", 3),
    cost_type_concept_id = rep(32814L, 3),
    total_paid = c(500.0, 550.0, 100.0),
    total_charge = c(600.0, 650.0, 150.0),
    amount_allowed = c(500.0, 550.0, 100.0),
    paid_by_payer = c(400.0, 450.0, 80.0),
    paid_by_patient = c(100.0, 100.0, 20.0)
  )

  DBI::dbWriteTable(con, "person", person)
  DBI::dbWriteTable(con, "observation_period", observation_period)
  DBI::dbWriteTable(con, "condition_occurrence", condition_occurrence)
  DBI::dbWriteTable(con, "cost", cost)

  cdm <- CDMConnector::cdmFromCon(con, cdmSchema = "main", writeSchema = "main")

  return(cdm)
}
