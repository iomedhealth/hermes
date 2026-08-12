# Data Model & R S3 Object Hierarchy: Eunomia Test Implementation

## 1. R S3 Pipeline Objects

The HERMES pipeline processes data across 6 stages through a sequential S3 class object hierarchy:

```
cdm_reference (OMOP CDM)
   │
   ├──> hermes_study (Stage 1: init)
   │       │
   │       ├──> hermes_hcru (Stage 2: summarise_baseline, extract_hcru)
   │       │       │
   │       │       ├──> hermes_ps (Stage 3: fit_ps, adjust_ps, assess_balance)
   │       │       │       │
   │       │       │       ├──> hermes_trajectories (Stage 4: compile_trajectories, extract_state_costs)
   │       │       │       │       │
   │       │       │       │       ├──> hermes_sim (Stage 5: run_simulation)
   │       │       │       │       │       │
   │       │       │       │       │       └──> hermes_cea (Stage 6: compute_cea, plots, summaries)
```

### S3 Class Definitions

1. **`hermes_study`**:
   - Class: `c("hermes_study", "list")`
   - Attributes: `cdm` (`cdm_reference`), `target_cohort` (string), `comparator_cohort` (string), `outcome_cohorts` (character vector), `study_name` (string), `baseline_summary` (`summarised_result` or NULL).

2. **`hermes_hcru`**:
   - Class: `c("hermes_hcru", "hermes_study", "list")`
   - Attributes: Extends `hermes_study` with `hcru_counts` (`tbbl`), `cost_summary` (`tbbl` containing extracted `total_paid`, `total_charge`, `amount_allowed`), `observation_window` (numeric vector).

3. **`hermes_ps`**:
   - Class: `c("hermes_ps", "hermes_study", "list")`
   - Attributes: Extends `hermes_study` with `ps_model` (fitted model), `matched_pop` (`tbbl`), `balance_summary` (`summarised_result`).

4. **`hermes_trajectories`**:
   - Class: `c("hermes_trajectories", "hermes_study", "list")`
   - Attributes: Extends `hermes_study` with `state_definitions` (list), `transition_matrix` (matrix), `state_cost_distributions` (list of parametric cost fits).

5. **`hermes_sim`**:
   - Class: `c("hermes_sim", "hermes_study", "list")`
   - Attributes: Extends `hermes_study` with `sim_results` (`tbbl` of simulated costs and QALYs across PSA iterations), `parameters` (list).

6. **`hermes_cea`**:
   - Class: `c("hermes_cea", "hermes_study", "list")`
   - Attributes: Extends `hermes_study` with `cea_results` (`bcea` object / summary), `wtp_thresholds` (numeric vector), `icer` (numeric), `nmb` (`tbbl`).

---

## 2. OMOP CDM `COST` Schema Interaction

Direct interaction with the OMOP CDM `COST` table (v5.3/v5.4):

| Field Name | Type | Key / Description |
|------------|------|-------------------|
| `cost_id` | Integer | Primary Key |
| `cost_event_id` | Integer | FK to `visit_occurrence_id`, `drug_exposure_id`, etc. |
| `cost_domain_id` | String | Domain ('Visit', 'Drug', 'Procedure', etc.) |
| `cost_type_concept_id` | Integer | Concept ID for cost type (e.g. payer reimbursement) |
| `total_paid` | Numeric | Direct expenditure total paid |
| `total_charge` | Numeric | Total amount charged |
| `amount_allowed` | Numeric | Contracted allowed amount |
| `paid_by_payer` | Numeric | Payer contribution |
| `paid_by_patient` | Numeric | Out-of-pocket contribution |
