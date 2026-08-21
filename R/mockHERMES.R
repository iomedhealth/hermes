#' Create a Mock OMOP CDM Reference for Testing and Demonstrations
#'
#' @param numberIndividuals Number of synthetic individuals to create. Default: 10.
#'
#' @return A `cdm_reference` object connected to an in-memory DuckDB database.
#' @export
#' @rdname mockOmopHeor
#' @aliases mockHERMES
#'
#' @examples
#' \donttest{
#' library(omopHeor)
#' cdm <- mockOmopHeor()
#' }
mockOmopHeor <- function(numberIndividuals = 10) {
  # ponytail: self-contained mock duckdb CDM reference for vignettes and examples
  con <- DBI::dbConnect(duckdb::duckdb(), ":memory:")

  person <- tibble::tibble(
    person_id = seq_len(numberIndividuals),
    gender_concept_id = rep(c(8507L, 8532L), length.out = numberIndividuals),
    year_of_birth = rep(1980L, numberIndividuals),
    month_of_birth = rep(1L, numberIndividuals),
    day_of_birth = rep(1L, numberIndividuals),
    race_concept_id = rep(0L, numberIndividuals),
    ethnicity_concept_id = rep(0L, numberIndividuals)
  )

  observation_period <- tibble::tibble(
    observation_period_id = seq_len(numberIndividuals),
    person_id = seq_len(numberIndividuals),
    observation_period_start_date = rep(as.Date("2000-01-01"), numberIndividuals),
    observation_period_end_date = rep(as.Date("2025-12-31"), numberIndividuals),
    period_type_concept_id = rep(0L, numberIndividuals)
  )

  provider <- tibble::tibble(
    provider_id = c(1L, 2L),
    specialty_concept_id = c(38004446L, 38004477L) # 38004446 = General Practice, 38004477 = Specialist
  )

  visit_occurrence <- tibble::tibble(
    visit_occurrence_id = c(1L, 2L, 3L, 4L, 5L, 6L, 7L, 8L),
    person_id = c(1L, 1L, 1L, 1L, 1L, 1L, 1L, 2L),
    visit_concept_id = c(
      9201L, # 1: Inpatient (followup)
      9201L, # 2: Inpatient readmission within 30d (followup)
      32037L, # 3: ICU (followup)
      9203L, # 4: Emergency (baseline)
      9202L, # 5: Outpatient GP (followup)
      9202L, # 6: Outpatient Specialist (followup)
      42898160L, # 7: SNF / Post-acute (followup)
      9201L # 8: Inpatient for person 2 (followup)
    ),
    visit_start_date = as.Date(c(
      "2010-02-01", "2010-02-20", "2010-02-02", "2009-10-01",
      "2010-03-01", "2010-04-01", "2010-05-01", "2010-03-10"
    )),
    visit_end_date = as.Date(c(
      "2010-02-05", "2010-02-23", "2010-02-04", "2009-10-01",
      "2010-03-01", "2010-04-01", "2010-05-10", "2010-03-15"
    )),
    visit_type_concept_id = rep(44818517L, 8),
    provider_id = c(1L, 1L, 1L, 1L, 1L, 2L, 1L, 1L)
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

  condition_occurrence <- tibble::tibble(
    condition_occurrence_id = c(1L, 2L, 3L),
    person_id = c(1L, 1L, 1L),
    condition_concept_id = c(4285898L, 4266809L, 192671L),
    condition_start_date = as.Date(c("2010-01-01", "2010-06-01", "2010-12-01")),
    condition_end_date = as.Date(c("2010-01-10", "2010-06-10", "2010-12-10")),
    condition_type_concept_id = rep(0L, 3)
  )

  DBI::dbWriteTable(con, "person", person)
  DBI::dbWriteTable(con, "observation_period", observation_period)
  DBI::dbWriteTable(con, "provider", provider)
  DBI::dbWriteTable(con, "visit_occurrence", visit_occurrence)
  DBI::dbWriteTable(con, "drug_exposure", drug_exposure)
  DBI::dbWriteTable(con, "procedure_occurrence", procedure_occurrence)
  DBI::dbWriteTable(con, "measurement", measurement)
  DBI::dbWriteTable(con, "condition_occurrence", condition_occurrence)
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
  cdm$target_cohort <- omopgenerics::newCohortTable(cdm$target_cohort, .softValidation = TRUE)
  cdm <- omopgenerics::insertTable(cdm, name = "comparator_cohort", table = comparator)
  cdm$comparator_cohort <- omopgenerics::newCohortTable(cdm$comparator_cohort, .softValidation = TRUE)
  cdm <- omopgenerics::insertTable(cdm, name = "outcome_cohort", table = outcome)
  cdm$outcome_cohort <- omopgenerics::newCohortTable(cdm$outcome_cohort, .softValidation = TRUE)

  cdm
}

#' @rdname mockOmopHeor
#' @export
mockHERMES <- function(numberIndividuals = 10) {
  mockOmopHeor(numberIndividuals = numberIndividuals)
}
