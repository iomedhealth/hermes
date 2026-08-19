# Data Model: DARWIN EU-Aligned Cohort Utilization APIs

## 1. Entities & Table Schemas

### 1.1 Source & Enriched Cohort Table (`cohort_table`)
- **Origin**: Created via `CohortConstructor` or `CDMConnector::cdmFromCon()`.
- **Base Columns**:
  - `cohort_definition_id` (integer): Unique cohort identifier.
  - `subject_id` (integer / bigint): Patient identifier matching OMOP `person_id`.
  - `cohort_start_date` (date): Patient index / cohort entry date.
  - `cohort_end_date` (date): Patient cohort exit date.

- **Dynamic Enriched Columns (Added via `add*` Verbs)**:
  | Domain Verb | Column Name Template | Data Type | Description |
  | :--- | :--- | :--- | :--- |
  | `addHospitalizations` | `inpatient_admissions_{window}` | integer | Count of general inpatient hospital admissions |
  | | `inpatient_los_days_{window}` | numeric | Total length of stay in days across admissions |
  | | `icu_admissions_{window}` | integer | Count of Intensive Care Unit (ICU) admissions |
  | | `icu_los_days_{window}` | numeric | Total length of stay in ICU in days |
  | | `readmissions_30d_{window}` | integer | Admissions within 30 days of a prior discharge |
  | | `readmissions_90d_{window}` | integer | Admissions within 90 days of a prior discharge |
  | `addOutpatientVisits` | `gp_visits_{window}` | integer | Primary care / General Practitioner visits |
  | | `specialist_visits_{window}` | integer | Ambulatory specialist consultations |
  | | `emergency_visits_{window}` | integer | Emergency Room (ED) visits |
  | | `other_outpatient_visits_{window}` | integer | Unclassified clinic / hospital ambulatory visits |
  | `addPrescriptions` | `rx_fills_{window}` | integer | Number of distinct drug dispensing / exposure events |
  | | `days_supply_{window}` | numeric | Cumulative days of medication supply dispensed |
  | | `pdc_{window}` | numeric | Proportion of Days Covered (0.0 to 1.0) |
  | | `infusions_{window}` | integer | Count of parenteral / intravenous administration events |
  | `addProcedures` | `lab_tests_count_{window}` | integer | Count of laboratory and diagnostic measurements |
  | | `imaging_count_{window}` | integer | Count of diagnostic imaging scans (CT, MRI, X-ray) |
  | | `procedures_count_{window}` | integer | Count of surgical and therapeutic procedures |
  | `addCosts` | `cost_inpatient_{window}` | numeric | Inpatient care paid expenditures |
  | | `cost_outpatient_{window}` | numeric | Outpatient care paid expenditures |
  | | `cost_drug_{window}` | numeric | Pharmacy / medication paid expenditures |
  | | `cost_procedure_{window}` | numeric | Procedural paid expenditures |
  | | `cost_total_{window}` | numeric | Sum of all direct medical expenditures |

---

### 1.2 Care Episode Cohort Table (`episode_cohort_table`)
- **Origin**: Generated via `computeHospitalizationCohorts()` and `computeInfusionCohorts()`.
- **Columns**:
  - `cohort_definition_id` (integer):
    - `1`: `inpatient_stay` (collapsed discrete hospitalizations)
    - `2`: `icu_stay` (intensive care stays)
    - `3`: `readmission_30d` (subsequent admissions within 30 days)
    - `4`: `infusion_episode` (intravenous drug therapy)
  - `subject_id` (integer): Patient ID.
  - `cohort_start_date` (date): Episode start date.
  - `cohort_end_date` (date): Episode discharge / completion date.

---

### 1.3 Analytical Result Table (`omopgenerics::summarised_result`)
- **Origin**: Generated via `summariseUtilization()` and `summariseCosts()`.
- **Standard Columns**:
  - `cdm_name` (character): Source CDM database name (e.g. `"Synthea_OMOP"`).
  - `group_name` (character): Grouping variable identifier (e.g. `"cohort_name"`).
  - `group_level` (character): Name of the target cohort (e.g. `"target_drug"`).
  - `strata_name` (character): Stratification variables combined with `&&&` (e.g. `"sex"`, `"age_group &&& sex"`).
  - `strata_level` (character): Stratification category values combined with `&&&` (e.g. `"Female"`, `"18-64 &&& Female"`).
  - `variable_name` (character): Metric evaluated (e.g. `"inpatient_admissions_followup"`).
  - `variable_level` (character): Sub-variable / level if applicable (or `NA`).
  - `estimate_name` (character): Statistical estimator (`"mean"`, `"sd"`, `"median"`, `"q25"`, `"q75"`, `"min"`, `"max"`, `"count"`, `"percentage"`).
  - `estimate_type` (character): Data format (`"numeric"`, `"integer"`, `"percentage"`).
  - `estimate_value` (character): Formatted string representation of the estimate.
  - `additional_name` (character): Context variables (`"overall"` or `"window"`).
  - `additional_level` (character): Context variable values.

---

## 2. Entity Relationships & Pipeline Flow

```text
[ cdm$visit_occurrence ] ───┐
[ cdm$drug_exposure ]    ───┼──> [ Episode Constructors ] ──> [ standalone episode cohort tables ]
[ cdm$provider ]         ───┤    (computeHospitalizationCohorts,
                             │     computeInfusionCohorts)
                             │
[ cdm$target_cohort ]    ───┴──> [ Cohort Enrichers ]      ──> [ cdm$study_enriched ]
                                 (addHospitalizations,          (retains all cohort rows,
                                  addOutpatientVisits,           adds windowed metric cols)
                                  addPrescriptions,                      │
                                  addProcedures,                         │
                                  addCosts)                              │
                                                                         ▼
                                                            [ Analytics & Reporting ]
                                                            (summariseUtilization,
                                                             summariseCosts)
                                                                         │
                                                                         ▼
                                                            [ summarised_result ]
                                                                         │
                                                                         ▼
                                                            [ tableUtilization / visOmopTable ]
```

---

## 3. Validation Rules

1. **Cohort Identity Preservation**: Every row in the input cohort `x` MUST exist in the output cohort table with unchanged `cohort_definition_id`, `subject_id`, `cohort_start_date`, and `cohort_end_date`.
2. **Zero-Utilization Completeness**: When a subject has 0 records in a given clinical domain, all count and duration columns for that domain MUST be filled with `0` (never `NA`, except for ratio metrics like `pdc` where denominator is 0).
3. **Non-Negative Metrics**: All event counts, lengths of stay (LOS), days supply, and financial expenditures MUST be `>= 0`.
4. **Window Boundary Validity**: An event on date `d` falls in window `[w_start, w_end]` relative to index date `t0` iff `t0 + w_start <= d <= t0 + w_end`.
