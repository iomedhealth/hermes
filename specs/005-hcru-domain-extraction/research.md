# Research & Technical Decisions: HCRU Domain Extraction & Financial Linkage

## Decision 1: Cohort Joining & Database-Side Temporal Windowing

- **Decision**: Extract patient cohort members by combining `study$target_cohort` and `study$comparator_cohort` (and optionally `study$outcome_cohort`) into a single cohort CTE/table containing `subject_id` and `cohort_start_date`. Perform all domain filtering and windowing database-side using `dbplyr` date operations before `collect()`.
- **Rationale**: 
  - Adheres to Principle II (Standardized OMOP CDM Integration) and Principle I (Zero Wheel-Reinvention).
  - Joining cohort subjects via `inner_join` on `subject_id` restricts all downstream table scans (visits, drugs, procedures, measurements, costs) to only study participants, drastically reducing memory usage and query time.
  - Window calculation (`event_date` between `cohort_start_date + baseline_window[1]` and `cohort_start_date + baseline_window[2]` for baseline, and `cohort_start_date + followup_window[1]` and `cohort_start_date + followup_window[2]` for follow-up) ensures event counts and costs are partitioned into baseline vs. follow-up intervals without leaking post-index events into baseline characteristics.
- **Alternatives Considered**:
  - *Collecting raw tables into R memory first*: Rejected because downloading millions of rows from `visit_occurrence`, `drug_exposure`, and `cost` into R memory crashes with realistic CDM scales and violates dbplyr best practices.
  - *Extracting only target cohort*: Rejected because comparative HEOR analysis requires unadjusted utilization and cost extraction across both target and comparator cohorts.

## Decision 2: 5-Domain Utilization Modeling & Concept Mapping

- **Decision**: Define standard OMOP concept ID sets for the 5 core HEOR utilization domains:
  1. **Inpatient & ICU**: `visit_concept_id %in% c(9201, 32037, 8717, 581379)` (Inpatient, ICU, Inpatient Hospital, ER & Inpatient). Compute admission counts and Length of Stay (LOS) as `sum(visit_end_date - visit_start_date)`. Optional 30/90-day readmissions.
  2. **Outpatient & Emergency**: `visit_concept_id %in% c(9202, 9203, 581477)` (Outpatient, ER, Outpatient Hospital). Left-join `provider` on `provider_id`. Differentiate ED (`visit_concept_id == 9203`), GP (`specialty_concept_id == 38004446` or unassigned outpatient), and Specialist (other `specialty_concept_id`).
  3. **Pharmacotherapy**: Query `drug_exposure`. Compute prescription fill count and total `days_supply`. Optional PDC / MPR adherence metrics.
  4. **Procedures & Diagnostics**: Query `procedure_occurrence` and `measurement`. Aggregate count of procedures and diagnostic tests per patient.
  5. **Post-Acute Care**: Query `visit_occurrence` for SNF/Hospice concepts (e.g. `visit_concept_id %in% c(42898160, 32036, 8546)`). Aggregate stay counts and LOS.
- **Rationale**:
  - Aligns with standard HEOR economic evaluation methodologies (NICE, ISPOR, CADTH) where cost drivers are separated by site of care and service category.
  - Using OMOP standard concept IDs ensures portability across disparate CDM databases (Eunomia, Synthea, Claims, EHR).
- **Alternatives Considered**:
  - *Single generic visit count*: Rejected because mixing intensive ICU stays with standard outpatient consultations distorts unit costs and microsimulation health states.

## Decision 3: Financial Linkage Architecture & Cost Field Aggregation

- **Decision**: Join clinical domain event tables with the OMOP `cost` table on primary event key (`cost_event_id` = `<domain>_occurrence_id` or `drug_exposure_id`) and `cost_domain_id` matching domain string (`Visit`, `Drug`, `Procedure`, `Measurement`).
- **Rationale**:
  - The OMOP CDM v5.3+ `cost` table uses polymorphic linkage via `(cost_domain_id, cost_event_id)`. Joining without domain filtering risks false joins if IDs collide across different entity tables.
  - Aggregates `total_paid` and `total_charge` (or user-configurable `cost_field`), tagging costs with `health_state` ("State_Baseline" vs. "State_Outcome") based on the relative timing of the event versus the patient's outcome date.
- **Alternatives Considered**:
  - *Hardcoded cost values or synthetic fallback*: Rejected; violates Constitution Principle II and fails to utilize real CDM financials.
  - *Directly querying cost table without domain event join*: Rejected; loses patient cohort linkage and temporal context.

## Decision 4: S3 Return Structure & Downstream Compatibility

- **Decision**: Keep the `hermes_hcru` object as a flat S3 list maintaining the class hierarchy `c("hermes_hcru", "hermes_study", "list")` created via `new_hermes_hcru()`.
  - Attach domain-specific utilization tables (`inpatient`, `outpatient`, `pharmacotherapy`, `procedures_diagnostics`, `post_acute`) and financial summaries (`costs`, `costs_by_domain`, `patient_utilization`) as named elements at the top level of the returned study object.
  - Ensure `study$costs` maintains the existing schema (`subject_id`, `total_paid`, `total_charge`, `health_state`, `cost_domain`) required by Stage 4 `compile_trajectories()`.
- **Rationale**:
  - Ensures full backward compatibility with Stage 3 (`fit_ps()`), Stage 4 (`compile_trajectories()`), and Stage 5 (`simulate_economics()`).
  - Follows Constitution Principle III (Pipeable S3 Architecture) avoiding deeply nested structs that complicate user access and inspection.
