# Quickstart: Inpatient, Emergency Care, and Unified Visit Enrichers

This guide demonstrates how to enrich study cohorts with inpatient, emergency care, and unified visit utilization metrics in HERMES using DARWIN EU `lowerCamelCase` style conventions.

---

## 1. Modular Inpatient Enrichment with `addInpatients`

```r
library(HERMES)
library(dplyr)

cdm <- hermesTestCdm()

# Enrich target cohort with baseline and follow-up inpatient metrics
cohortInp <- cdm$target_cohort |>
  addInpatients(
    window = list(baseline = c(-365, -1), followup = c(0, 365)),
    readmissions = TRUE,
    stratifySpecialty = TRUE,
    specialties = list(
      cardiology = c(38004453L),
      oncology = c(38004507L)
    )
  )

# Preview results
cohortInp |>
  select(subject_id, inpatient_admissions_followup, inpatient_los_days_followup, icu_admissions_followup) |>
  collect()
```

---

## 2. Comprehensive Emergency Care Enrichment with `addEmergencyCare`

Captures emergency care identified either by emergency room visit concepts or by Emergency Medicine specialist provider IDs:

```r
cohortEr <- cdm$target_cohort |>
  addEmergencyCare(
    window = list(baseline = c(-365, -1), followup = c(0, 365)),
    stratifySpecialty = TRUE,
    specialties = list(
      pediatricEmergency = c(38004511L),
      traumaSurgery = c(38004499L)
    )
  )

cohortEr |>
  select(subject_id, emergency_visits_baseline, emergency_visits_followup) |>
  collect()
```

---

## 3. All-in-One Multi-Setting Enrichment with `addVisits`

Enrich with Inpatient, Outpatient, and Emergency care in a single unified call:

```r
cohortAllVisits <- cdm$target_cohort |>
  addVisits(
    window = list(baseline = c(-365, -1), followup = c(0, 365)),
    settings = c("inpatient", "outpatient", "emergency"),
    stratifySpecialty = TRUE,
    specialties = list(
      oncology = c(38004507L, 38004006L),
      cardiology = c(38004453L)
    ),
    readmissions = TRUE
  )

# Summarise utilization using PatientProfiles / CohortCharacteristics
summaryRes <- summariseUtilization(cohortAllVisits)
```
