# Quickstart: Modular Package Suite & Metapackage

This guide demonstrates how to install and use the 3 modular domain packages (`CohortUtilisation`, `CohortCosts`, `CohortEconomics`) both independently and via the `hermes` metapackage.

---

## 1. Using the Unified Metapackage (`hermes`)

Install and load the entire HEOR suite in one command:

```r
# Install entire suite from repository root
pak::pkg_install("iomedhealth/hermes")

# Load all 3 domain packages simultaneously
library(hermes)
#> ── Attaching packages ────────────────────────────────── hermes 0.3.0 ──
#> ✔ CohortUtilisation 0.3.0     ✔ CohortEconomics   0.3.0
#> ✔ CohortCosts       0.3.0
```

Run an end-to-end pipeline:

```r
cdm <- hermesTestCdm()

# 1. Healthcare Resource Utilization (CohortUtilisation)
cohortEnriched <- cdm$target_cohort |>
  addVisits(window = list(baseline = c(-365, -1), followup = c(0, 365))) |>
  addPrescriptions(window = list(followup = c(0, 365)))

# 2. Medical Costs Linkage (CohortCosts)
cohortEnriched <- cohortEnriched |>
  addCosts(window = list(followup = c(0, 365)))

# 3. Economic Modeling & Simulation (CohortEconomics)
study <- init(cdm, "target_cohort", "comparator_cohort", "outcome_cohort") |>
  fit_ps() |>
  adjust_ps() |>
  compile_trajectories() |>
  simulate_economics() |>
  run_cea()
```

---

## 2. Using `CohortUtilisation` Standalone (No Heavy CEA Dependencies)

For epidemiological and resource utilization studies without economic simulation engines:

```r
# Install only CohortUtilisation
pak::pkg_install("iomedhealth/hermes?subdir=packages/CohortUtilisation")

library(CohortUtilisation)

# Enrich cohort with inpatient, outpatient, and emergency care
cohortEnriched <- cdm$target_cohort |>
  addInpatients(window = list(followup = c(0, 365))) |>
  addEmergencyCare(window = list(followup = c(0, 365))) |>
  addOutpatientVisits(window = list(followup = c(0, 365)))

# Summarise utilization
summaryRes <- summariseUtilization(cohortEnriched)
```

---

## 3. Using `CohortCosts` Standalone

For cost-of-illness and expenditure studies:

```r
pak::pkg_install("iomedhealth/hermes?subdir=packages/CohortCosts")

library(CohortCosts)

# Link OMOP costs and summarise
cohortCosts <- cdm$target_cohort |>
  addCosts(window = list(followup = c(0, 365)))

summaryCost <- summariseCosts(cohortCosts)
```
