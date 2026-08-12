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
  cost <- tibble::tibble(
    cost_id = 1L, cost_event_id = 1L, cost_domain_id = "Visit",
    cost_type_concept_id = 32814L, total_paid = 100.0,
    total_charge = 150.0, amount_allowed = 120.0,
    paid_by_payer = 80.0, paid_by_patient = 20.0
  )

  DBI::dbWriteTable(con, "person", person)
  DBI::dbWriteTable(con, "observation_period", observation_period)
  DBI::dbWriteTable(con, "cost", cost)

  cdm <- CDMConnector::cdmFromCon(con, cdmSchema = "main", writeSchema = "main")

  return(cdm)
}
