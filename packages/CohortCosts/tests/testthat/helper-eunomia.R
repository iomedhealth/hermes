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
    person_id = c(1L, 2L, 3L),
    gender_concept_id = c(8507L, 8532L, 8507L),
    year_of_birth = c(1980L, 1975L, 1990L),
    race_concept_id = c(0L, 0L, 0L),
    ethnicity_concept_id = c(0L, 0L, 0L)
  )
  observation_period <- tibble::tibble(
    observation_period_id = c(1L, 2L, 3L),
    person_id = c(1L, 2L, 3L),
    observation_period_start_date = as.Date(c("2000-01-01", "2000-01-01", "2000-01-01")),
    observation_period_end_date = as.Date(c("2020-12-31", "2020-12-31", "2020-12-31")),
    period_type_concept_id = c(0L, 0L, 0L)
  )
  condition_occurrence <- tibble::tibble(
    condition_occurrence_id = c(1L, 2L, 3L),
    person_id = c(1L, 1L, 1L),
    condition_concept_id = c(4285898L, 4266809L, 192671L),
    condition_start_date = as.Date(c("2010-01-01", "2010-06-01", "2010-12-01")),
    condition_end_date = as.Date(c("2010-01-10", "2010-06-10", "2010-12-10")),
    condition_type_concept_id = c(0L, 0L, 0L)
  )
  provider <- tibble::tibble(
    provider_id = c(1L, 2L, 3L),
    specialty_concept_id = c(38004446L, 38004477L, 38004510L) # 38004446 = General Practice, 38004477 = Specialist, 38004510 = Emergency Medicine
  )
  visit_occurrence <- tibble::tibble(
    visit_occurrence_id = c(1L, 2L, 3L, 4L, 5L, 6L, 7L, 8L, 9L),
    person_id = c(1L, 1L, 1L, 1L, 1L, 1L, 1L, 2L, 2L),
    visit_concept_id = c(
      9201L, # 1: Inpatient (followup)
      9201L, # 2: Inpatient readmission within 30d (followup)
      32037L, # 3: ICU (followup)
      9203L, # 4: Emergency (baseline)
      9202L, # 5: Outpatient GP (followup)
      9202L, # 6: Outpatient Specialist (followup)
      42898160L, # 7: SNF / Post-acute (followup)
      9201L, # 8: Inpatient for person 2 (followup)
      9202L  # 9: Outpatient visit attended by Emergency Medicine specialist (provider 3) (followup)
    ),
    visit_start_date = as.Date(c(
      "2010-02-01",
      "2010-02-20",
      "2010-02-02",
      "2009-10-01",
      "2010-03-01",
      "2010-04-01",
      "2010-05-01",
      "2010-03-10",
      "2010-06-01"
    )),
    visit_end_date = as.Date(c(
      "2010-02-05", # 4 days LOS
      "2010-02-23", # 3 days LOS
      "2010-02-04", # 2 days LOS
      "2009-10-01", # 0 days LOS
      "2010-03-01", # 0 days LOS
      "2010-04-01", # 0 days LOS
      "2010-05-10", # 9 days LOS
      "2010-03-15", # 5 days LOS
      "2010-06-01"  # 0 days LOS
    )),
    visit_type_concept_id = rep(44818517L, 9),
    provider_id = c(1L, 1L, 1L, 1L, 1L, 2L, 1L, 1L, 3L)
  )
  drug_exposure <- tibble::tibble(
    drug_exposure_id = c(1L, 2L, 3L, 4L),
    person_id = c(1L, 1L, 2L, 1L),
    drug_concept_id = c(1124300L, 1118084L, 1124300L, 19078461L),
    drug_exposure_start_date = as.Date(c("2010-01-15", "2009-08-01", "2010-02-01", "2010-03-01")),
    drug_exposure_end_date = as.Date(c("2010-02-14", "2009-08-31", "2010-03-02", "2010-03-01")),
    drug_type_concept_id = rep(38000177L, 4),
    route_concept_id = c(4132161L, 4132161L, 4132161L, 4171047L), # 4171047 = Intravenous
    days_supply = c(30L, 30L, 30L, 1L),
    quantity = c(30, 30, 30, 1)
  )
  procedure_occurrence <- tibble::tibble(
    procedure_occurrence_id = c(1L, 2L),
    person_id = c(1L, 1L),
    procedure_concept_id = c(4163872L, 4163872L),
    procedure_date = as.Date(c("2010-02-01", "2009-11-15")),
    procedure_type_concept_id = rep(38000275L, 2)
  )
  measurement <- tibble::tibble(
    measurement_id = c(1L, 2L),
    person_id = c(1L, 1L),
    measurement_concept_id = c(3004410L, 3004410L),
    measurement_date = as.Date(c("2010-02-02", "2009-12-01")),
    measurement_type_concept_id = rep(44818702L, 2)
  )
  cost <- tibble::tibble(
    cost_id = c(1L, 2L, 3L, 4L, 5L, 6L, 7L),
    cost_event_id = c(1L, 2L, 3L, 1L, 1L, 1L, 1L),
    cost_domain_id = c("Condition", "Condition", "Condition", "Visit", "Drug", "Procedure", "Measurement"),
    cost_type_concept_id = rep(32814L, 7),
    total_paid = c(500.0, 550.0, 100.0, 2000.0, 80.0, 300.0, 50.0),
    total_charge = c(600.0, 650.0, 150.0, 3000.0, 100.0, 400.0, 70.0),
    amount_allowed = c(500.0, 550.0, 100.0, 2000.0, 80.0, 300.0, 50.0),
    paid_by_payer = c(400.0, 450.0, 80.0, 1800.0, 60.0, 250.0, 40.0),
    paid_by_patient = c(100.0, 100.0, 20.0, 200.0, 20.0, 50.0, 10.0)
  )

  DBI::dbWriteTable(con, "person", person)
  DBI::dbWriteTable(con, "observation_period", observation_period)
  DBI::dbWriteTable(con, "condition_occurrence", condition_occurrence)
  DBI::dbWriteTable(con, "provider", provider)
  DBI::dbWriteTable(con, "visit_occurrence", visit_occurrence)
  DBI::dbWriteTable(con, "drug_exposure", drug_exposure)
  DBI::dbWriteTable(con, "procedure_occurrence", procedure_occurrence)
  DBI::dbWriteTable(con, "measurement", measurement)
  DBI::dbWriteTable(con, "cost", cost)

  cdm <- CDMConnector::cdmFromCon(con, cdmSchema = "main", writeSchema = "main")

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
  cdm$target_cohort <- newCohortTable(cdm$target_cohort)
  cdm <- omopgenerics::insertTable(cdm, name = "comparator_cohort", table = comparator)
  cdm$comparator_cohort <- newCohortTable(cdm$comparator_cohort)
  cdm <- omopgenerics::insertTable(cdm, name = "outcome_cohort", table = outcome)
  cdm$outcome_cohort <- newCohortTable(cdm$outcome_cohort)

  return(cdm)
}

hermesTestCdm <- hermes_test_cdm
