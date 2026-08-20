# Quickstart Guide: DARWIN EU-Aligned Cohort Utilization APIs

This guide walks through using the modular cohort utilization and cost functions in **HERMES**.

---

## 1. Prerequisites & CDM Setup

```r
library(HERMES)
library(dplyr)
library(CDMConnector)

# Connect to OMOP CDM (e.g. DuckDB Eunomia test CDM)
cdm <- hermes_test_cdm()
```

---

## 2. Scenario 1: Create Care Episode Cohorts (`CohortConstructor` Style)

Construct discrete inpatient hospitalization episodes and 30-day readmissions as an OMOP cohort table in the database write schema:

```r
# Create hospitalization episodes table
cdm$hosp_episodes <- computeHospitalizationCohorts(
  cdm = cdm,
  name = "hosp_episodes",
  visitConceptIds = c(9201L, 8717L, 581379L),
  icuConceptIds = c(32037L),
  readmissionWindow = 30L
)

# Inspect cohort counts
omopgenerics::cohortCount(cdm$hosp_episodes)
```

---

## 3. Scenario 2: In-Database Cohort Enrichment (`PatientProfiles` Style)

Enrich study cohorts in-database with windowed utilization metrics and direct medical costs:

```r
# Pipe study cohort through domain enrichers
cdm$study_enriched <- cdm$target_cohort |>
  addHospitalizations(
    window = list(baseline = c(-365, -1), followup = c(0, 365)),
    readmissions = TRUE
  ) |>
  addOutpatientVisits(
    window = list(baseline = c(-365, -1), followup = c(0, 365)),
    stratifySpecialty = TRUE
  ) |>
  addPrescriptions(
    window = list(followup = c(0, 365)),
    daysSupply = TRUE,
    pdc = TRUE
  ) |>
  addProcedures(
    window = list(followup = c(0, 365))
  ) |>
  addCosts(
    window = list(followup = c(0, 365)),
    costField = "total_paid"
  ) |>
  compute(name = "study_enriched", temporary = FALSE, overwrite = TRUE)

# View enriched column structure
colnames(cdm$study_enriched)
```

---

## 4. Scenario 3: Summarisation & Reporting (`CohortCharacteristics` Style)

Aggregate utilization and costs into DARWIN EU standardized `summarised_result` objects and render publication-ready tables:

```r
# 1. Summarise healthcare resource utilization
utilSummary <- cdm$study_enriched |>
  summariseUtilization(
    strata = list("cohort_definition_id"),
    estimates = c("mean", "sd", "median", "q25", "q75", "min", "max")
  )

# 2. Summarise direct medical expenditures
costSummary <- cdm$study_enriched |>
  summariseCosts(
    strata = list("cohort_definition_id"),
    estimates = c("mean", "sd", "median", "q25", "q75")
  )

# 3. Render publication-ready GT table
tableUtilization(utilSummary, type = "gt")
```
