test_that("End-to-End pipeline produces valid CEA plots", {
  # skip_if_not_installed("BCEA")

  # Stage 1: Init
  cdm <- hermes_test_cdm()
  study <- init(cdm)

  # Stage 2: Baseline & HCRU
  study <- summarise_baseline(study)
  study <- extract_hcru(study)

  # Stage 3: PS Adjustment
  study <- fit_ps(study)
  study <- adjust_ps(study)

  # Stage 4: Trajectories
  study <- compile_trajectories(study)

  # Stage 5: Simulation
  study <- run_simulation(study)

  # Stage 6: CEA & Plotting
  study <- compute_cea(study)

  # Generate plots
  p_ceac <- plot_ceac(study)
  p_plane <- plot_plane(study)

  # Verify plots were generated (BCEA usually returns ggplot objects or lists)
  expect_false(is.null(p_ceac))
  expect_false(is.null(p_plane))
})
