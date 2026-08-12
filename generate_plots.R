devtools::load_all(".")
cdm <- hermes_test_cdm()
study <- init(cdm) |>
  summarise_baseline() |>
  extract_hcru() |>
  fit_ps() |>
  adjust_ps() |>
  compile_trajectories() |>
  run_simulation() |>
  compute_cea()

png("ceac.png", width=800, height=600, res=100)
plot_ceac(study)
invisible(dev.off())

png("plane.png", width=800, height=600, res=100)
plot_plane(study)
invisible(dev.off())
