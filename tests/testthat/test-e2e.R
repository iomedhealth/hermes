test_that("End-to-End pipeline produces valid CEA plots", {
  # skip_if_not_installed("BCEA")

  # Stage 1: Init
  Sys.setenv(EUNOMIA_DATA_FOLDER = file.path(tempdir(), "eunomia"))
  con <- DBI::dbConnect(duckdb::duckdb(), CDMConnector::eunomiaDir("GiBleed"))
  withr::defer(DBI::dbDisconnect(con, shutdown = TRUE))
  cdm <- CDMConnector::cdmFromCon(con, cdmSchema = "main", writeSchema = "main")

  # Create real cohorts from GiBleed conditions
  cohort <- cdm$condition_occurrence |>
    dplyr::inner_join(cdm$observation_period, by = "person_id") |>
    dplyr::filter(
      .data$condition_start_date >= .data$observation_period_start_date, 
      .data$condition_start_date <= .data$observation_period_end_date
    ) |>
    dplyr::select(
      subject_id = "person_id", 
      cohort_start_date = "condition_start_date", 
      cohort_end_date = "condition_start_date"
    ) |>
    dplyr::mutate(cohort_definition_id = 1L) |>
    dplyr::distinct(.data$subject_id, .data$cohort_definition_id, .keep_all = TRUE)

  target_cohort <- cohort |> 
    dplyr::filter(.data$subject_id %% 2 == 0) |> 
    dplyr::compute(name = "target_cohort", temporary = FALSE)
    
  comparator_cohort <- cohort |> 
    dplyr::filter(.data$subject_id %% 2 == 1) |> 
    dplyr::compute(name = "comparator_cohort", temporary = FALSE)
    
  outcome_cohort <- cohort |> 
    dplyr::filter(.data$subject_id %% 5 == 0) |> 
    dplyr::compute(name = "outcome_cohort", temporary = FALSE)

  cdm$target_cohort <- omopgenerics::newCohortTable(target_cohort)
  cdm$comparator_cohort <- omopgenerics::newCohortTable(comparator_cohort)
  cdm$outcome_cohort <- omopgenerics::newCohortTable(outcome_cohort)

  study <- init(cdm, "target_cohort", "comparator_cohort", "outcome_cohort")

  # Stage 2: Baseline & HCRU
  study <- summarise_baseline(study)
  study <- extract_hcru(study)

  # Stage 3: PS Adjustment
  study <- fit_ps(study)
  study <- adjust_ps(study)

  # Stage 4: Trajectories
  study <- compile_trajectories(study)

  # Stage 5: Simulation
  study <- simulate_economics(study)

  # Stage 6: CEA & Plotting
  study <- run_cea(study)

  # Generate plots
  p_ceac <- plot_ceac(study)
  p_plane <- plot_plane(study)

  # Verify plots were generated
  expect_false(is.null(p_ceac))
  expect_false(is.null(p_plane))
})
