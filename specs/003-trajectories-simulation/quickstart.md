# Quickstart: Stage 4 Trajectories and Stage 5 Economic Simulation

## Execution Example

```R
library(HERMES)
library(CDMConnector)

# Initialize Eunomia GiBleed test CDM
con <- DBI::dbConnect(duckdb::duckdb(), CDMConnector::eunomiaDir("GiBleed"))
cdm <- CDMConnector::cdmFromCon(con, cdmSchema = "main", writeSchema = "main")

# Build study
cdm$target_cohort <- CohortConstructor::conceptCohort(cdm, list(target = 4285898L), name = "target_cohort")
cdm$comparator_cohort <- CohortConstructor::conceptCohort(cdm, list(comp = 4266809L), name = "comparator_cohort")
cdm$outcome_cohort <- CohortConstructor::conceptCohort(cdm, list(out = 192671L), name = "outcome_cohort")

study <- init(cdm, "target_cohort", "comparator_cohort", "outcome_cohort") |>
  summarise_baseline() |>
  extract_hcru() |>
  fit_ps() |>
  adjust_ps()

# Stage 4: Compile Trajectories
traj <- compile_trajectories(study)
print(traj$matrices)
print(traj$costs)

# Stage 5: Economic Simulation (PSA)
sim <- simulate_economics(traj, time_horizon = 10, discount_rate = 0.03)
print(head(sim$hesim_ce$costs))
print(head(sim$hesim_ce$qalys))

# Stage 6: Run CEA
cea <- run_cea(sim)
plot_ceac(cea)
```

## Running Unit Tests

```bash
Rscript -e "devtools::test(filter = 'stage4|stage5|e2e')"
```
