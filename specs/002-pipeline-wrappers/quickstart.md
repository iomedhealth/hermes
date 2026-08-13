# Quickstart

This outlines the intended usage of the HERMES pipeline wrappers once implemented.

```R
library(HERMES)

# Assume `cdm` is a valid CDM reference (e.g. from Eunomia)
results <- init(cdm) |>
  summarise_baseline() |>
  extract_hcru() |>
  fit_ps() |>
  compile_trajectories() |>
  simulate_economics() |>
  run_cea()
```