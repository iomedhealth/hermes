# Data Model: Inpatient, Emergency Care, and Unified Visit Enrichers

## 1. Input Data Structures

### 1.1 Study Cohort Table (`x`)
A table adhering to `omopgenerics::cohort_table` structure.

| Field | Type | Description |
|---|---|---|
| `cohort_definition_id` | `integer` | Identifier of the cohort definition |
| `subject_id` | `integer` / `bigint` | Person ID (maps to OMOP `person.person_id`) |
| `cohort_start_date` | `date` | Cohort entry index date |
| `cohort_end_date` | `date` | Cohort exit date |
| `[other columns]` | Any | Existing baseline covariates / demographic columns preserved |

### 1.2 CDM Source Tables

- **`visit_occurrence`**:
  - `visit_occurrence_id` (`integer`): Primary key.
  - `person_id` (`integer`): Subject identifier.
  - `visit_concept_id` (`integer`): Standard OMOP concept ID (Inpatient, ER, Outpatient).
  - `visit_start_date` (`date`): Admission / encounter start date.
  - `visit_end_date` (`date`): Discharge / encounter end date.
  - `provider_id` (`integer`): Foreign key to `provider`.

- **`provider`**:
  - `provider_id` (`integer`): Primary key.
  - `specialty_concept_id` (`integer`): Standard OMOP concept ID for provider clinical specialty.

---

## 2. Enriched Output Column Specifications

### 2.1 Inpatient Care Columns (`addInpatients`, `addHospitalizations`)

| Column Pattern | Type | Description |
|---|---|---|
| `inpatient_admissions_{window}` | `integer` | Count of general inpatient hospital admissions |
| `inpatient_los_days_{window}` | `numeric` | Cumulative length of stay (days) across inpatient admissions |
| `icu_admissions_{window}` | `integer` | Count of Intensive Care Unit admissions |
| `icu_los_days_{window}` | `numeric` | Cumulative length of stay (days) in ICU |
| `readmissions_30d_{window}` | `integer` | Count of readmissions within 30 days of previous discharge |
| `readmissions_90d_{window}` | `integer` | Count of readmissions within 90 days of previous discharge |
| `{specialty}_inpatient_admissions_{window}` | `integer` | Inpatient admissions under specified provider specialty |

### 2.2 Emergency Care Columns (`addEmergencyCare`, `addEmergency`)

| Column Pattern | Type | Description |
|---|---|---|
| `emergency_visits_{window}` | `integer` | Count of acute emergency encounters (ER visit concept OR Emergency Medicine provider specialty) |
| `{specialty}_emergency_visits_{window}` | `integer` | Emergency visits attended by designated medical specialists |

### 2.3 Outpatient Care Columns (`addOutpatientVisits`)

| Column Pattern | Type | Description |
|---|---|---|
| `gp_visits_{window}` | `integer` | Count of primary care / General Practice outpatient visits |
| `specialist_visits_{window}` | `integer` | Count of specialist outpatient visits |
| `other_outpatient_visits_{window}` | `integer` | Count of other / unclassified outpatient visits |
| `{specialty}_visits_{window}` | `integer` | Outpatient visits under specified provider specialty |

### 2.4 Unified Care Columns (`addVisits`)
Combines all requested columns from Inpatient, Outpatient, and Emergency care settings in a single table output.

---

## 3. Data Integrity & Validation Rules

1. **Zero-Utilization Imputation**: All metric columns are non-nullable in the returned table (`0L` for counts, `0.0` for durations).
2. **Subject Preservation**: $N_{\text{output}} = N_{\text{input}}$ with identical `cohort_definition_id`, `subject_id`, and index dates.
3. **Episode Boundary Clamp**: Same-day discharges or data anomalies where `visit_end_date < visit_start_date` enforce $\text{LOS} = \max(0, \text{end} - \text{start})$.
4. **Specialty Resolution**: Visits with missing or non-matching provider specialty fall back to generic domain buckets (`other_outpatient_visits` or general admissions) without error.
