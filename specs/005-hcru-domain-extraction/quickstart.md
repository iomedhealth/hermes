# Quickstart Guide: HCRU Domain Extraction & Financial Linkage

## 1. Prerequisites

Ensure you have initialized an OMOP CDM reference with target, comparator, and outcome cohort tables:

```r
library(HERMES)
library(CDMConnector)
library(dplyr)

# Connect to OMOP CDM (e.g., Eunomia)
con <- DBI::dbConnect(duckdb::duckdb(), CDMConnector::eunomiaDir("GiBleed"))
cdm <- CDMConnector::cdmFromCon(con, cdmSchema = "main", writeSchema = "main")

# Initialize study
study <- init(
  cdm = cdm,
  target_cohort = "target_cohort",
  comparator_cohort = "comparator_cohort",
  outcome_cohort = "outcome_cohort"
)
```

## 2. Extracting Utilization & Costs

Execute `extract_hcru()` with custom baseline and follow-up temporal windows:

```r
# Extract baseline characteristics (optional, can be chained)
study <- summarise_baseline(study)

# Extract HCRU across all 5 domains and link OMOP COST records
study <- extract_hcru(
  study = study,
  baseline_window = c(-365, -1),
  followup_window = c(0, 365),
  cost_field = "total_paid",
  calculate_readmissions = TRUE,
  persistence = FALSE
)
```

## 3. Inspecting Domain Summaries

Access domain-specific utilization and financial metrics:

```r
# View inpatient admissions and length of stay
head(study$hcru$inpatient)

# View outpatient encounters stratified by GP vs Specialist vs ED
head(study$hcru$outpatient)

# View pharmacy fills and days supply
head(study$hcru$pharmacotherapy)

# View linked cost records tagged by health state
head(study$costs)

# View patient-level aggregated summary across all domains
head(study$hcru$patient_summary)
```

## 4. Continuing Pipeline Flow

The enriched `study` object seamlessly feeds into downstream causal adjustment and economic simulations:

```r
# Stage 3: Propensity Score Adjustment
study <- fit_ps(study)
study <- adjust_ps(study)

# Stage 4: Trajectory Compilation
study <- compile_trajectories(study)

# Stage 5: Economic Simulation
study <- simulate_economics(study)

# Stage 6: Decision Analysis
study <- run_cea(study)
```
