test_that("compute_hospitalization_cohorts collapses overlaps, contiguous visits, and finds readmissions", {
  con <- DBI::dbConnect(duckdb::duckdb(), ":memory:")
  withr::defer(DBI::dbDisconnect(con, shutdown = TRUE))

  person <- tibble::tibble(
    person_id = 1:3,
    gender_concept_id = 0L,
    year_of_birth = 1990L,
    month_of_birth = 1L,
    day_of_birth = 1L,
    race_concept_id = 0L,
    ethnicity_concept_id = 0L
  )

  visit_occurrence <- tibble::tibble(
    visit_occurrence_id = 1:8,
    person_id = c(1L, 1L, 1L, 2L, 2L, 2L, 3L, 3L),
    visit_concept_id = 9201L,
    visit_start_date = as.Date(c(
      "2020-01-01", "2020-01-05", "2020-01-20", # Person 1: overlap (1-7 & 5-10), then gap (20-25) -> readmission
      "2020-02-01", "2020-02-10", "2020-03-01", # Person 2: bad end date, NA end date, normal
      "2020-01-01", "2020-03-01"                # Person 3: > 30 days gap -> no readmission
    )),
    visit_end_date = as.Date(c(
      "2020-01-07", "2020-01-10", "2020-01-25",
      "2019-01-01", NA, "2020-03-05",
      "2020-01-05", "2020-03-05"
    )),
    visit_type_concept_id = 0L
  )

  observation_period <- tibble::tibble(
    observation_period_id = 1:3,
    person_id = 1:3,
    observation_period_start_date = as.Date("2000-01-01"),
    observation_period_end_date = as.Date("2025-12-31"),
    period_type_concept_id = 0L
  )

  DBI::dbWriteTable(con, "person", person)
  DBI::dbWriteTable(con, "visit_occurrence", visit_occurrence)
  DBI::dbWriteTable(con, "observation_period", observation_period)

  cdm <- CDMConnector::cdmFromCon(con, cdmSchema = "main", writeSchema = "main")

  # 1. Run snake_case
  res <- compute_hospitalization_cohorts(cdm, name = "hosp_cohort", readmission_window = 30L)
  cohort_data <- res |> dplyr::collect()

  # Person 1: Overlapping visits 1 & 2 merged into Jan 1 - Jan 10
  # Visit 3: Jan 20 - Jan 25
  p1_hosp <- cohort_data |> dplyr::filter(.data$subject_id == 1L, .data$cohort_definition_id == 1L)
  expect_equal(nrow(p1_hosp), 2)
  expect_true(any(p1_hosp$cohort_start_date == as.Date("2020-01-01") & p1_hosp$cohort_end_date == as.Date("2020-01-10")))
  expect_true(any(p1_hosp$cohort_start_date == as.Date("2020-01-20") & p1_hosp$cohort_end_date == as.Date("2020-01-25")))

  # Person 1 Readmission (Jan 20 is 10 days after Jan 10 discharge)
  p1_readm <- cohort_data |> dplyr::filter(.data$subject_id == 1L, .data$cohort_definition_id == 2L)
  expect_equal(nrow(p1_readm), 1)
  expect_equal(p1_readm$cohort_start_date, as.Date("2020-01-20"))

  # Person 2: Fixed invalid/NA dates
  p2_hosp <- cohort_data |> dplyr::filter(.data$subject_id == 2L, .data$cohort_definition_id == 1L)
  expect_equal(nrow(p2_hosp), 3)
  expect_true(all(p2_hosp$cohort_start_date <= p2_hosp$cohort_end_date))

  # Person 3: Gap is > 30 days -> 0 readmissions
  p3_readm <- cohort_data |> dplyr::filter(.data$subject_id == 3L, .data$cohort_definition_id == 2L)
  expect_equal(nrow(p3_readm), 0)

  # Check metadata
  expect_equal(omopgenerics::settings(res)$cohort_name, c("hospitalization", "readmission"))

  # 2. Test camelCase alias compatibility
  res_camel <- computeHospitalizationCohorts(cdm, name = "hosp_cohort_camel", readmission_window = 30L)
  cohort_data_camel <- res_camel |> dplyr::collect()
  expect_equal(nrow(cohort_data_camel), nrow(cohort_data))
})
