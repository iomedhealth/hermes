library(CDMConnector)
library(omopgenerics)
library(dplyr)
library(dbplyr)

hermes_test_cdm <- function(env = parent.frame()) {
  # Initialize Eunomia via duckdb
  con <- DBI::dbConnect(duckdb::duckdb(), eunomiaDir())
  
  # Auto-teardown
  withr::defer(DBI::dbDisconnect(con, shutdown = TRUE), envir = env)
  
  cdm <- cdmFromCon(con, cdmSchema = "main", writeSchema = "main")
  
  # Inject synthetic COST records if absent
  if (!"cost" %in% names(cdm)) {
    cost_data <- tibble::tibble(
      cost_id = 1:100,
      cost_event_id = 1:100,
      cost_domain_id = "Visit",
      cost_type_concept_id = 32814L,
      total_paid = 100.0,
      total_charge = 150.0,
      amount_allowed = 120.0,
      paid_by_payer = 80.0,
      paid_by_patient = 20.0
    )
    DBI::dbWriteTable(con, "cost", cost_data, overwrite = TRUE)
    cdm <- cdmFromCon(con, cdmSchema = "main", writeSchema = "main")
  }
  
  return(cdm)
}
