# HERMES API & Architecture Specification

**Version:** 0.1.0 (Draft)  
**Package Name:** `HERMES` (`Health Economic Resource Modeling & Evaluation System`)  
**Target R Version:** R >= 4.1  

---

## 1. Design Principles & Architecture

`HERMES` provides a unified, pipeline-friendly interface for Healthcare Resource Utilization (HCRU) and Cost-Effectiveness Analysis (CEA) using observational healthcare data structured in the OMOP Common Data Model (CDM).

### Core Principles
1. **Explicit Namespace Usage:** Designed for function calls using `hermes::<function>()` (e.g., `hermes::init()`, `hermes::compute_cea()`).
2. **Pipe-Friendly Workflow:** Functions accept and return S3 study objects, supporting the base R pipe operator (`|>`).
3. **Delegation to Existing Packages:** Wraps established OHDSI, DARWIN EU, and HEOR R packages (`CDMConnector`, `PatientProfiles`, `CohortCharacteristics`, `CohortMethod`, `Cohort2Trajectory`, `TrajectoryMarkovAnalysis`, `hesim`, `BCEA`) rather than re-implementing core algorithms.
4. **Native OMOP `COST` Integration:** Directly queries and extracts cost data from the OMOP CDM `COST` table (`total_paid`, `total_charge`, `cost_type_concept_id`).
5. **Standardized Outputs:** Summaries and metrics output as `omopgenerics::summarised_result` objects for standardized reporting (`gt`, `flextable`).

---

## 2. Object Flow & S3 Class Hierarchy

```
  cdm (omop_reference)
       |
       v
  [ hermes::init() ] ──────────────────────────> hermes_study
       |
       v
  [ hermes::extract_hcru() ] ──────────────────> hermes_hcru
       |
       v
  [ hermes::fit_ps() |> hermes::adjust_ps() ] -> hermes_ps
       |
       v
  [ hermes::compile_trajectories() ] ──────────> hermes_trajectories
       |
       v
  [ hermes::run_simulation() ] ────────────────> hermes_sim
       |
       v
  [ hermes::compute_cea() ] ───────────────────> hermes_cea
```

---

## 3. Detailed Stage-by-Stage Function Specifications

### Stage 1: Cohort Setup & Study Initialization

#### `hermes::init()`
Initializes a `hermes_study` object, linking the target treatment/exposure cohort, comparator cohort, and optional clinical outcome cohorts.

```r
hermes::init(
  cdm,
  target_cohort,
  comparator_cohort,
  outcome_cohorts = NULL,
  study_name = "HERMES Study"
)
```

* **Arguments:**
  * `cdm`: A `cdm_reference` object created via `CDMConnector::cdmFromCon()`.
  * `target_cohort`: String. Name of the target/exposed cohort table in the `cdm`.
  * `comparator_cohort`: String. Name of the comparator/unexposed cohort table in the `cdm`.
  * `outcome_cohorts`: Character vector (optional). Names of clinical outcome cohort tables.
  * `study_name`: String. Title/identifier for the study.
* **Returns:** An object of class `hermes_study`.
* **Underlying Engine:** `omopgenerics`, `CDMConnector`.

---

### Stage 2: Descriptive Baseline & HCRU Extraction

#### `hermes::summarise_baseline()`
Generates unadjusted baseline demographic and clinical characterization tables.

```r
hermes::summarise_baseline(
  study,
  demographics = TRUE,
  covariates = NULL
)
```

* **Arguments:**
  * `study`: A `hermes_study` object.
  * `demographics`: Logical. Whether to compute age, sex, and prior observation time.
  * `covariates`: List or character vector of concept sets / feature names.
* **Returns:** Updated `hermes_study` containing baseline `summarised_result` tables.
* **Underlying Engine:** `PatientProfiles`, `CohortCharacteristics`.

#### `hermes::extract_hcru()`
Extracts healthcare resource utilization counts, event rates, and direct medical expenditures from the OMOP CDM.

```r
hermes::extract_hcru(
  study,
  observation_window = c(0, 365),
  visit_domains = c("inpatient", "outpatient", "emergency"),
  drug_domains = TRUE,
  cost_domain = "cost",
  cost_field = "total_paid"
)
```

* **Arguments:**
  * `study`: A `hermes_study` object.
  * `observation_window`: Integer vector of length 2 `c(start_day, end_day)` relative to index date.
  * `visit_domains`: Character vector of visit types to quantify (`inpatient`, `outpatient`, `emergency`).
  * `drug_domains`: Logical. Quantify prescription refills and days supply.
  * `cost_domain`: String. Name of the OMOP `COST` table in the CDM (default `"cost"`).
  * `cost_field`: String. OMOP `COST` column to extract (`"total_paid"`, `"total_charge"`, `"amount_allowed"`).
* **Returns:** A `hermes_hcru` object containing utilization counts, Length of Stay (LOS), and direct medical cost distributions.
* **Underlying Engine:** `omopgenerics`, `dbplyr`, OMOP `COST` table queries.

---

### Stage 3: Causal Propensity Score (PS) Adjustment

#### `hermes::fit_ps()`
Fits high-dimensional regularized logistic regression models to estimate propensity scores $P(\text{Target} \mid X)$.

```r
hermes::fit_ps(
  study_or_hcru,
  covariates,
  prior = "laplace",
  variance = 0.01
)
```

* **Arguments:**
  * `study_or_hcru`: A `hermes_study` or `hermes_hcru` object.
  * `covariates`: High-dimensional feature matrix or concept set lists.
  * `prior`, `variance`: Hyperparameters for regularized regression.
* **Returns:** A `hermes_ps` object.
* **Underlying Engine:** `CohortMethod`, `Cyclops`.

#### `hermes::adjust_ps()`
Applies patient trimming, matching, or weighting to create balanced comparative cohorts.

```r
hermes::adjust_ps(
  ps_object,
  method = c("matching", "iptw", "trimming"),
  ratio = 1,
  caliper = 0.2
)
```

* **Arguments:**
  * `ps_object`: A `hermes_ps` object.
  * `method`: String (`"matching"`, `"iptw"`, `"trimming"`).
  * `ratio`: Integer. Matching ratio (1:1, 1:k).
  * `caliper`: Numeric. Standardized logit caliper width.
* **Returns:** Updated `hermes_ps` object with matched/weighted patient identifiers.
* **Underlying Engine:** `CohortMethod`.

#### `hermes::assess_balance()`
Computes Standardized Mean Differences (SMD) and generates balance diagnostic plots (Love plots).

```r
hermes::assess_balance(ps_adjusted_object)
```

* **Returns:** `summarised_result` containing pre/post-adjustment SMDs and `ggplot2` Love plot.

---

### Stage 4: Trajectory Compilation & State-Cost Extraction

#### `hermes::compile_trajectories()`
Compiles long-term patient timelines into discrete, mutually exclusive health states over uniform time cycles.

```r
hermes::compile_trajectories(
  ps_adjusted_object,
  state_definitions,
  cycle_length = "30 days"
)
```

* **Arguments:**
  * `ps_adjusted_object`: A `hermes_ps` object.
  * `state_definitions`: Named list defining health states based on clinical conditions/cohorts.
  * `cycle_length`: String (e.g., `"30 days"`, `"1 month"`).
* **Returns:** A `hermes_trajectories` object.
* **Underlying Engine:** `Cohort2Trajectory`.

#### `hermes::extract_state_costs()`
Extracts state-specific medical expenditure distributions from the OMOP `COST` table and calculates state-to-state transition probabilities.

```r
hermes::extract_state_costs(
  trajectories,
  dist_type = c("gamma", "lognormal")
)
```

* **Arguments:**
  * `trajectories`: A `hermes_trajectories` object.
  * `dist_type`: Parametric distribution family for cost modeling.
* **Returns:** Updated `hermes_trajectories` with transition probability matrices and parametric cost distributions per health state.
* **Underlying Engine:** `TrajectoryMarkovAnalysis`, OMOP `COST` table.

---

### Stage 5: Economic Simulation

#### `hermes::run_simulation()`
Integrates transition probabilities and state-cost distributions into an economic state-transition model.

```r
hermes::run_simulation(
  trajectories,
  time_horizon = 10,
  cycle_length = "30 days",
  discount_cost = 0.03,
  discount_qaly = 0.03,
  n_samples = 1000
)
```

* **Arguments:**
  * `trajectories`: A `hermes_trajectories` object.
  * `time_horizon`: Numeric (years). Total projection period.
  * `cycle_length`: String. Duration of each Markov cycle.
  * `discount_cost`, `discount_qaly`: Annual discount rates.
  * `n_samples`: Integer. Number of Probabilistic Sensitivity Analysis (PSA) iterations.
* **Returns:** A `hermes_sim` object containing simulated cost and QALY trajectories across iterations.
* **Underlying Engine:** `hesim`, `heemod`.

---

### Stage 6: Decision Analysis & Post-Processing (CEA)

#### `hermes::compute_cea()`
Calculates Incremental Cost-Effectiveness Ratios (ICER) and Net Monetary Benefit (NMB) across willingness-to-pay (WTP) thresholds.

```r
hermes::compute_cea(
  sim_object,
  wtp_thresholds = seq(0, 100000, by = 5000)
)
```

* **Arguments:**
  * `sim_object`: A `hermes_sim` object.
  * `wtp_thresholds`: Numeric vector of WTP values per QALY gained.
* **Returns:** A `hermes_cea` object.
* **Underlying Engine:** `BCEA`.

#### Visualization & Summary Helpers

```r
# Generate Cost-Effectiveness Acceptability Curve (CEAC)
hermes::plot_ceac(cea_object)

# Generate Cost-Effectiveness Plane (Scatter plot)
hermes::plot_plane(cea_object)

# Export executive summary table
hermes::table_summary(cea_object, format = c("gt", "flextable"))
```

---

## 4. Native OMOP `COST` Table Query Strategy

When `hermes::extract_hcru()` or `hermes::extract_state_costs()` is invoked, HERMES generates optimized SQL via `dbplyr` targeting the OMOP `COST` table:

```sql
SELECT 
  c.person_id,
  c.cost_domain_id,
  c.cost_type_concept_id,
  c.total_paid,
  c.total_charge,
  c.paid_by_payer,
  c.paid_by_patient,
  v.visit_concept_id,
  v.visit_start_date,
  v.visit_end_date
FROM cdm.cost c
JOIN cdm.visit_occurrence v 
  ON c.cost_event_id = v.visit_occurrence_id 
 AND c.cost_domain_id = 'Visit'
WHERE c.person_id IN (SELECT subject_id FROM study_cohort);
```

---

## 5. End-to-End Pipeline Example

```r
library(HERMES)
library(CDMConnector)

# Connect to database
cdm <- cdmFromCon(con = db_con, cdmSchema = "main", writeSchema = "scratch")

# Run 6-Stage HERMES Analysis Pipeline
results <- cdm |>
  hermes::init(
    target_cohort     = "cancer_hz",
    comparator_cohort = "cancer_non_hz",
    outcome_cohorts   = c("phn", "hzo"),
    study_name        = "HORION Economic Analysis"
  ) |>
  hermes::extract_hcru(
    observation_window = c(0, 365),
    visit_domains      = c("inpatient", "outpatient", "emergency"),
    cost_field         = "total_paid"
  ) |>
  hermes::fit_ps(
    covariates = c("age", "sex", "prior_treatments", "comorbidities")
  ) |>
  hermes::adjust_ps(
    method = "matching",
    ratio  = 1
  ) |>
  hermes::compile_trajectories(
    state_definitions = list(
      acute = "hz_acute_cohort",
      chronic = "phn_chronic_cohort",
      recovered = "recovered_cohort"
    ),
    cycle_length = "30 days"
  ) |>
  hermes::extract_state_costs() |>
  hermes::run_simulation(
    time_horizon = 10,
    n_samples    = 1000
  ) |>
  hermes::compute_cea(
    wtp_thresholds = seq(0, 100000, by = 5000)
  )

# Render Decision Analytic Visuals
hermes::plot_ceac(results)
hermes::plot_plane(results)
hermes::table_summary(results, format = "gt")
```
