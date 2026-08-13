# Quickstart: Running End-to-End Pipeline on CDM Data

```R
library(HERMES)
library(CDMConnector)
library(CohortConstructor)
library(DBI)
library(duckdb)

# 1. Connect to CDM
con <- DBI::dbConnect(duckdb::duckdb(), CDMConnector::eunomiaDir("GiBleed"))
cdm <- CDMConnector::cdmFromCon(con, cdmSchema = "main", writeSchema = "main")

# 2. Define Cohorts
cdm$target_cohort <- CohortConstructor::conceptCohort(cdm, list(target = 4285898L), "target_cohort")
cdm$comparator_cohort <- CohortConstructor::conceptCohort(cdm, list(comp = 4266809L), "comparator_cohort")
cdm$outcome_cohort <- CohortConstructor::conceptCohort(cdm, list(outcome = 192671L), "outcome_cohort")

# 3. Stage 1: Init
study <- init(cdm, "target_cohort", "comparator_cohort", "outcome_cohort")

# 4. Stage 2: Baseline & HCRU
study <- summarise_baseline(study)
study <- extract_hcru(study)

# 5. Stage 3: PS Fitting & Matching
study <- fit_ps(study)
study <- adjust_ps(study)

# 6. Stage 4: Trajectory Compilation
study <- compile_trajectories(study)

# 7. Stage 5: Economic Simulation
study <- simulate_economics(study)

# 8. Stage 6: Decision Analysis & CEA Plots
study <- run_cea(study)
p_ceac <- plot_ceac(study)
p_plane <- plot_plane(study)

print(p_ceac)
```
