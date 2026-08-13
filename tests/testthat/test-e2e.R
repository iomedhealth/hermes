test_that("End-to-End pipeline produces valid CEA plots", {
  # skip_if_not_installed("BCEA")

  # Stage 1: Init
  Sys.setenv(EUNOMIA_DATA_FOLDER = file.path(tempdir(), "eunomia"))
  con <- DBI::dbConnect(duckdb::duckdb(), CDMConnector::eunomiaDir("GiBleed"))
  withr::defer(DBI::dbDisconnect(con, shutdown = TRUE))
  cdm <- CDMConnector::cdmFromCon(con, cdmSchema = "main", writeSchema = "main")

  # Create real cohorts from GiBleed conditions with semantic clinical meaning
  # Target: Polyp of colon (4285898)
  # Comparator: Diverticular disease (4266809)
  # Outcome: Gastrointestinal hemorrhage (192671)

  cdm$target_cohort <- CohortConstructor::conceptCohort(
    cdm = cdm,
    conceptSet = list(target_cohort = 4285898L),
    name = "target_cohort"
  )

  cdm$comparator_cohort <- CohortConstructor::conceptCohort(
    cdm = cdm,
    conceptSet = list(comparator_cohort = 4266809L),
    name = "comparator_cohort"
  )

  cdm$outcome_cohort <- CohortConstructor::conceptCohort(
    cdm = cdm,
    conceptSet = list(outcome_cohort = 192671L),
    name = "outcome_cohort"
  )

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
