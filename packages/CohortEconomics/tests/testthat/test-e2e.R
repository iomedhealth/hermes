test_that("End-to-End pipeline produces valid CEA plots", {
  # skip_if_not_installed("BCEA")

  # Stage 1: Init
  Sys.setenv(EUNOMIA_DATA_FOLDER = file.path(tempdir(), "eunomia"))
  con <- DBI::dbConnect(duckdb::duckdb(), CDMConnector::eunomiaDir("GiBleed"))
  withr::defer(DBI::dbDisconnect(con, shutdown = TRUE))

  # Inject synthetic realistic costs so E2E uses actual logic instead of fallback
  DBI::dbExecute(con, "
    CREATE OR REPLACE TABLE cost AS
    SELECT
      ROW_NUMBER() OVER () as cost_id,
      condition_occurrence_id as cost_event_id,
      'Condition' as cost_domain_id,
      32814 as cost_type_concept_id,
      CASE
        WHEN condition_concept_id IN (4285898, 4266809) THEN 500.0
        WHEN condition_concept_id = 192671 THEN 100.0
        ELSE 50.0
      END as total_paid,
      CASE
        WHEN condition_concept_id IN (4285898, 4266809) THEN 600.0
        WHEN condition_concept_id = 192671 THEN 150.0
        ELSE 75.0
      END as total_charge
    FROM condition_occurrence
  ")

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
  study <- extract_hcru(study, calculate_readmissions = TRUE)

  expect_true(inherits(study, "hermes_hcru"))
  expect_true(!is.null(study$costs))
  expect_true(is.data.frame(study$costs))
  expect_true(!is.null(study$hcru$patient_summary))
  expect_true(is.data.frame(study$hcru$inpatient))
  expect_true(is.data.frame(study$hcru$outpatient))
  expect_true(is.data.frame(study$hcru$pharmacotherapy))
  expect_true(is.data.frame(study$hcru$procedures_diagnostics))
  expect_true(is.data.frame(study$hcru$post_acute))
  expect_gt(nrow(study$hcru$patient_summary), 0)

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
  expect_false(is.null(study$traj_obj$ps_obj$cm_data))
  expect_false(is.null(study$traj_obj$ps_obj$model))
  expect_true(is.data.frame(study$traj_obj$ps_obj$matched_pop))
  expect_gt(nrow(study$traj_obj$ps_obj$matched_pop), 0)
  expect_gt(length(study$traj_obj$matrices), 0)

  expect_false(is.null(p_ceac))
  expect_false(is.null(p_plane))

  # Test modular cohort enricher pipeline
  cdm$target_cohort_enriched <- cdm$target_cohort |>
    addInpatients(window = list(baseline = c(-365, -1), followup = c(0, 365))) |>
    addOutpatientVisits(window = list(followup = c(0, 365))) |>
    addEmergencyCare(window = list(followup = c(0, 365))) |>
    addPrescriptions(window = list(followup = c(0, 365))) |>
    addProcedures(window = list(followup = c(0, 365))) |>
    addCosts(window = list(followup = c(0, 365)), name = "target_cohort_enriched")

  expect_true(inherits(cdm$target_cohort_enriched, "cohort_table"))
  enriched_df <- cdm$target_cohort_enriched |> dplyr::collect()
  expect_equal(nrow(enriched_df), nrow(cdm$target_cohort |> dplyr::collect()))
  expect_true("inpatient_admissions_followup" %in% colnames(enriched_df))
  expect_true("cost_total_followup" %in% colnames(enriched_df))

  util_sum <- summariseUtilization(cdm$target_cohort_enriched)
  expect_true(inherits(util_sum, "summarised_result"))
  omopgenerics::validateResultArgument(util_sum)

  tbl_util <- tableUtilization(util_sum, type = "tibble")
  expect_true(is.data.frame(tbl_util))
})
