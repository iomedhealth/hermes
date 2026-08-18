# Data Model: HCRU Domain Extraction & Financial Linkage

## Entities & Tables

### 1. Cohort Population Reference (`cohort_patients`)
- **Description**: In-database combined patient table constructed from target and comparator (and outcome) cohorts.
- **Fields**:
  - `subject_id` (integer / bigint, PK): Unique patient identifier.
  - `cohort_start_date` (date): Patient index date.
  - `cohort_end_date` (date): Patient cohort exit date.
  - `cohort_type` (character): Cohort origin identifier (`target`, `comparator`, `outcome`).

### 2. Inpatient & ICU Utilization (`inpatient_utilization`)
- **Description**: Summarized inpatient admissions and intensive care utilization per patient and window.
- **Fields**:
  - `subject_id` (integer): Patient identifier.
  - `window` (character): `baseline` or `followup`.
  - `inpatient_admissions` (integer): Total number of inpatient hospital admissions.
  - `inpatient_los_days` (numeric): Total days spent as an inpatient (`sum(visit_end_date - visit_start_date)`).
  - `icu_admissions` (integer): Total number of ICU admissions.
  - `icu_los_days` (numeric): Total days spent in ICU.
  - `readmissions_30d` (integer, optional): Number of hospital readmissions within 30 days of previous discharge.
  - `readmissions_90d` (integer, optional): Number of hospital readmissions within 90 days of previous discharge.

### 3. Outpatient & Emergency Utilization (`outpatient_utilization`)
- **Description**: Ambulatory encounters stratified by setting and clinician specialty per patient and window.
- **Fields**:
  - `subject_id` (integer): Patient identifier.
  - `window` (character): `baseline` or `followup`.
  - `emergency_visits` (integer): Count of emergency department (ED) encounters.
  - `gp_visits` (integer): Count of General Practitioner / Primary Care visits.
  - `specialist_visits` (integer): Count of Medical Specialist consultations.
  - `other_outpatient_visits` (integer): Count of unstratified outpatient hospital clinic visits.

### 4. Pharmacotherapy Utilization (`pharmacotherapy_utilization`)
- **Description**: Prescription medications and dispensed supply summary per patient and window.
- **Fields**:
  - `subject_id` (integer): Patient identifier.
  - `window` (character): `baseline` or `followup`.
  - `prescription_fills` (integer): Total count of distinct drug dispensing / exposure events.
  - `total_days_supply` (numeric): Sum of `days_supply` across all dispensed prescriptions.
  - `pdc` (numeric, optional): Proportion of Days Covered (0.0 to 1.0) if adherence evaluation enabled.

### 5. Diagnostics & Procedures Utilization (`procedures_diagnostics`)
- **Description**: Interventions and laboratory measurements summary per patient and window.
- **Fields**:
  - `subject_id` (integer): Patient identifier.
  - `window` (character): `baseline` or `followup`.
  - `procedure_count` (integer): Total count of recorded procedural occurrences.
  - `measurement_count` (integer): Total count of laboratory and diagnostic measurements.

### 6. Post-Acute Care Utilization (`post_acute`)
- **Description**: Skilled post-acute care and hospice encounters per patient and window.
- **Fields**:
  - `subject_id` (integer): Patient identifier.
  - `window` (character): `baseline` or `followup`.
  - `post_acute_stays` (integer): Total count of Skilled Nursing Facility (SNF) / Hospice stays.
  - `post_acute_los_days` (numeric): Total days in post-acute care facilities.

### 7. Linked Financial Costs (`costs` & `costs_by_domain`)
- **Description**: Event-linked direct medical expenditures grouped by patient, clinical domain, and health state.
- **Fields**:
  - `subject_id` (integer): Patient identifier.
  - `cost_domain` (character): Source domain (`Inpatient`, `Outpatient`, `Emergency`, `Drug`, `Procedure`, `Measurement`, `PostAcute`).
  - `health_state` (character): Assigned state (`State_Baseline`, `State_Outcome`).
  - `total_paid` (numeric): Cumulative amount paid by payer and patient.
  - `total_charge` (numeric): Cumulative billed charges.

## Entity Relationships

```
[ study$cdm$target_cohort ]     \
                                  --> [ cohort_patients ] (Combined cohort & index dates)
[ study$cdm$comparator_cohort ] /
          |
          +---> inner_join with visit_occurrence (Inpatient & ICU concepts) --------> [ inpatient_utilization ]
          +---> inner_join with visit_occurrence + provider (Outpatient concepts) --> [ outpatient_utilization ]
          +---> inner_join with drug_exposure ---------------------------------------> [ pharmacotherapy_utilization ]
          +---> inner_join with procedure_occurrence & measurement ------------------> [ procedures_diagnostics ]
          +---> inner_join with visit_occurrence (SNF & Hospice concepts) -----------> [ post_acute ]
          |
          +---> inner_join domain events with cost table (matching domain & PK) ------> [ costs & costs_by_domain ]
```

## Validation Rules

1. **Cohort Confinement**: Every record in `inpatient_utilization`, `outpatient_utilization`, `pharmacotherapy_utilization`, `procedures_diagnostics`, `post_acute`, and `costs` MUST belong to a `subject_id` present in `cohort_patients`.
2. **Temporal Window Consistency**: An event is classified into `baseline` if `cohort_start_date + baseline_window[1] <= event_start_date <= cohort_start_date + baseline_window[2]`. An event is classified into `followup` if `cohort_start_date + followup_window[1] <= event_start_date <= cohort_start_date + followup_window[2]`.
3. **Non-Negative Metrics**: Counts, length of stay days, days supply, and cost aggregates must be >= 0.
4. **State Classification**: If `outcome_date` exists for a patient, events on or after `outcome_date` are tagged `State_Outcome`; otherwise `State_Baseline`.
