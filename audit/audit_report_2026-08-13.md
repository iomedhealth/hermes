# HERMES R Package Audit Report

**Package Name:** HERMES (Health Economics and Outcomes Research Pipeline on OMOP CDM)  
**Version:** 0.1.0  
**Audit Date:** August 13, 2026  
**Auditor:** Expert Data Scientist, R Package Developer & HEOR Software Auditor  
**Target Architecture:** 6-Stage Analytical Pipeline on OMOP CDM (R >= 4.1, `omopgenerics`, `CDMConnector`, `CohortMethod`, `BCEA`, DuckDB/Eunomia)

---

## 1. Executive Summary

HERMES presents a well-conceived high-level architectural design intended to execute Real-World Evidence (RWE) and Health Economics and Outcomes Research (HEOR) workflows directly on OMOP Common Data Model (CDM) databases. The vision—aligning a pipeable S3 class framework with a 6-stage analytical pipeline (Cohort Generation → Baseline/HCRU → Causal PS Adjustment → Trajectories → Economic Simulation → Decision Analysis)—is outstanding and meets a critical demand in clinical economics.

However, a rigorous technical audit reveals that **the repository is currently in an early prototype/alpha state with major silent execution failures, incomplete implementations, and missing core HEOR features**:

1. **Silent Fallback Cascade in End-to-End Pipeline**: The end-to-end integration test (`test-e2e.R`) passes quietly only because upstream failures in Stage 3 (Propensity Score) trigger hardcoded mock fallbacks in Stage 4 (Trajectories) and Stage 5 (Simulation). Real CDM data flow breaks between Stages 2 and 3 because `CohortMethod::getDbCohortMethodData` is never called.
2. **Stage 2 HCRU Primitive Implementation**: `extract_hcru()` (`R/hcru.R`) consists of a 5-line unwindowed `dplyr::group_by(cost_domain_id)` query across the raw `cost` table. It fails to filter by patient cohort, lacks temporal baseline vs. follow-up windowing, and entirely omits the 5 core HEOR utilization domains (Inpatient, Outpatient/ED, Pharmacotherapy, Diagnostics/Procedures, Post-Acute Care).
3. **Empty Package Exports**: The `NAMESPACE` file is completely empty (0 exported functions). `roxygen2::roxygenise()` has not been run to generate exports or documentation, rendering the package unbuildable for downstream users.
4. **S3 Class Hierarchy & Nesting Anti-Patterns**: S3 constructors in `R/s3_classes.R` are bypassed in Stages 3 through 6. Pipeline functions wrap previous stage outputs into deeply nested sub-lists (`sim$traj_obj$ps_obj$hcru_obj$study`), breaking class inheritance and inspection.
5. **Mathematical Uncalibrated PSA Engine**: Stage 5 PSA sampling uses an arbitrary multiplier (`alphas <- s_trans[r, ] * 100`) for Dirichlet transition uncertainty, injecting uncalibrated variance that distorts Probabilistic Sensitivity Analysis.

---

## 2. Constitutional Compliance Check

The codebase was evaluated against the 5 core principles defined in `.specify/memory/constitution.md`:

| Principle | Compliance Status | Audit Findings & Evidence |
| :--- | :---: | :--- |
| **I. Zero Wheel-Reinvention (Package Wrapping Strategy)** | **PARTIAL FAIL** | Wraps `CDMConnector`, `PatientProfiles`, `CohortCharacteristics`, `CohortMethod`, `Cyclops`, and `BCEA`. However, Stage 4 (`R/trajectories.R`) bypasses `Cohort2Trajectory` / `TrajectoryMarkovAnalysis`, and Stage 5 (`R/simulation.R`) bypasses `hesim` / `heemod` using hand-rolled, simplified pure-R logic (`# ponytail:` shortcuts). |
| **II. Standardized OMOP CDM & COST Integration** | **PARTIAL FAIL** | Core OMOP tables are never modified or written to (**PASS**). Temporary tables use `writeSchema` via `PatientProfiles::addDemographics()` (**PASS**). However, `extract_hcru()` queries `cdm$cost` without cohort or date joins, resulting in un-windowed database-wide aggregation rather than cohort-specific HCRU extraction (`R/hcru.R` lines 31–38). |
| **III. Pipeable S3 Architecture** | **PARTIAL FAIL** | Consistently uses base R pipe `\|>` and `<-` assignment with `snake_case` naming (**PASS**). However, constructors in `R/s3_classes.R` are bypassed in `R/ps.R`, `R/trajectories.R`, `R/simulation.R`, and `R/cea.R`, causing S3 class hierarchy breakage and deeply nested object structures. |
| **IV. Test-First & Coverage (NON-NEGOTIABLE)** | **PARTIAL FAIL** | Unit test files exist for all 6 stages using DuckDB/Eunomia (**PASS**). However, Stage 3–5 unit tests rely on synthetic mock lists, and `test-e2e.R` passes via silent fallback defaults. `test-stage6-cea.R` contains anti-pattern `source("../../R/cea.R")`, and `NAMESPACE` is unpopulated. |
| **V. 6-Stage Analytical Pipeline Alignment** | **PARTIAL FAIL** | All 6 stages exist conceptually and function signatures align. However, data flow breaks after Stage 2 due to missing `CohortMethod` feature extraction, causing Stages 3, 4, 5, and 6 to execute on `NULL`/`NA` or mock data. |

---

## 3. Deep Dive Technical Findings (Stages 1–6)

### Stage 1: Cohort Generation (`R/init.R`)

- **Finding 1.1 (WARNING): Minimal Cohort Validation & Class Checking**
  - **Location**: `R/init.R`, lines 12–16, 27–35
  - **Technical Implication**: `init()` checks if table names exist in `names(cdm)`, but does not validate whether the tables are valid `omopgenerics` cohort tables (`omopgenerics::isCohortTable()`) or whether they contain valid target, comparator, or outcome subjects.
- **Finding 1.2 (CRITICAL): Unpopulated `NAMESPACE` File**
  - **Location**: `NAMESPACE`, lines 1–2
  - **Technical Implication**: Although `@export` tags exist in `R/*.R` files, `NAMESPACE` contains zero export directives. Installing and loading `HERMES` via `library(HERMES)` fails to export `init`, `summarise_baseline`, `extract_hcru`, `fit_ps`, `compile_trajectories`, `simulate_economics`, or `run_cea`.

---

### Stage 2: Baseline & HCRU Extraction (`R/baseline.R`, `R/hcru.R`)

- **Finding 2.1 (WARNING): Hardcoded Temporary Table Schema Overwrite**
  - **Location**: `R/baseline.R`, lines 14–18
  - **Technical Implication**: `target_profiled` is written to `writeSchema` with fixed name `target_profiled_temp` and `overwrite = TRUE`. Running concurrent HERMES sessions on a shared scratch schema will cause table collision and data corruption.
- **Finding 2.2 (CRITICAL): Absence of Cohort Filtering and Baseline/Follow-Up Windowing in HCRU**
  - **Location**: `R/hcru.R`, lines 31–38
  - **Technical Implication**: `extract_hcru()` executes `study$cdm$cost |> group_by(cost_domain_id) |> summarise(...) |> collect()`. This aggregates costs across the *entire database*, including non-study subjects and events occurring outside patient observation windows or index dates.
- **Finding 2.3 (CRITICAL): Complete Omission of the 5 HEOR Utilization Domains**
  - **Location**: `R/hcru.R`, lines 31–38
  - **HEOR Implication**: `extract_hcru()` groups purely by `cost_domain_id` (e.g., "Condition", "Drug"). It fails to extract or categorize the required HEOR utilization domains:
    1. **Inpatient Care**: Zero extraction of hospital admissions, Length of Stay (LOS) in days, ICU admissions/duration, or 30/90-day hospital readmissions. Requires joining `visit_occurrence` / `visit_detail` where `visit_concept_id %in% c(9201, 32037, 581379)`.
    2. **Outpatient & Emergency Care**: Zero extraction of GP visits, specialist consultations, ED visits (`visit_concept_id %in% c(9203, 581477)`), or outpatient clinic visits (`9202`).
    3. **Pharmacotherapy & Prescriptions**: Zero extraction of prescription fills, specialty infusions, days supply, treatment duration, or persistence (PDC/MPR) from `drug_exposure`.
    4. **Diagnostics & Procedures**: Zero extraction of laboratory tests (`measurement`), diagnostic imaging, or endoscopic/surgical procedures (`procedure_occurrence`).
    5. **Post-Acute & Supportive Care**: Zero extraction of Skilled Nursing Facility (SNF) stays (`42898160`), home healthcare, rehabilitation, or palliative/hospice care.

---

### Stage 3: Causal Propensity Score Adjustment (`R/ps.R`)

- **Finding 3.1 (CRITICAL): Missing `getDbCohortMethodData` Extraction Causing Pipeline Disconnect**
  - **Location**: `R/ps.R`, lines 9–15
  - **Technical Implication**: `fit_ps()` expects `hcru_obj$cm_data` to contain a valid `CohortMethodData` object. However, no function in HERMES calls `CohortMethod::getDbCohortMethodData()` to extract covariates from the CDM. Consequently, `cm_data` is always `NULL`, `CohortMethod::createPs` is skipped, and `fit_ps()` silently returns `model = NULL`.
- **Finding 3.2 (WARNING): Hardcoded Matching Caliper & Missing Balance Visualization**
  - **Location**: `R/ps.R`, lines 33, 45–48
  - **Technical Implication**: `adjust_ps()` hardcodes `caliper = 0.2` on the standardized logit scale without user override arguments. `assess_balance()` returns raw `computeCovariateBalance` output without generating balance plots (Love plots) or summarizing top unbalanced covariates.

---

### Stage 4: Trajectory Compilation & Transition Matrices (`R/trajectories.R`)

- **Finding 4.1 (CRITICAL): Cascade Failure & Hardcoded 2-State Markov Model**
  - **Location**: `R/trajectories.R`, lines 16–50, 64–86
  - **Technical Implication**: Because Stage 3 produces `matched_pop = NA` due to missing `cm_data`, Stage 4 receives invalid data. When supplied with test data, `compile_trajectories()` hardcodes a 2-state model (`State_Baseline` and `State_Outcome`) with a fixed 30-day binary outcome window. It cannot model multi-state progression, recurrent events, competing risks, or dynamic state transitions.
- **Finding 4.2 (WARNING): Class Constructor Bypass & Object Nesting Anti-Pattern**
  - **Location**: `R/trajectories.R`, lines 89–97
  - **Technical Implication**: `compile_trajectories()` bypasses `new_hermes_trajectories()` from `R/s3_classes.R`. It returns a list that nests `ps_obj` inside `traj_obj$ps_obj` (which nests `hcru_obj`, which nests `study`). This deep nesting breaks flat S3 inspection and creates memory redundancy.

---

### Stage 5: Economic Simulation Engine (`R/simulation.R`)

- **Finding 5.1 (CRITICAL): Uncalibrated PSA Transition Sampling (Arbitrary Dirichlet Multiplier)**
  - **Location**: `R/simulation.R`, lines 103–108
  - **Mathematical/HEOR Implication**: Transition probability sampling uses `alphas <- s_trans[r, ] * 100` as pseudo-counts for Dirichlet sampling via Gamma draws. Multiplying probabilities by an arbitrary factor of 100 artificially injects a fixed, uncalibrated variance assumption ($N=100$) that completely ignores actual patient sample sizes, drastically distorting Probabilistic Sensitivity Analysis (PSA) parameter uncertainty.
- **Finding 5.2 (WARNING): Silent Fallback Clutter Masking Upstream Bugs**
  - **Location**: `R/simulation.R`, lines 15–27
  - **Technical Implication**: When `traj_obj` contains empty matrices or cost summaries, `simulate_economics()` silently substitutes hardcoded default matrices (`c(0.9, 0.1, 0, 1)`) and dummy costs (`500` / `100`). This masks upstream pipeline failures during test execution.

---

### Stage 6: Decision Analysis & Post-Processing (`R/cea.R`)

- **Finding 6.1 (SUGGESTION): Argument Naming Inconsistency & Class Bypass**
  - **Location**: `R/cea.R`, lines 20–23, 27–33
  - **Technical Implication**: `plot_ceac(study)`, `plot_plane(study)`, and `table_summary(study)` use the parameter name `study` instead of `cea_obj` or `hermes_cea`. `run_cea()` bypasses `new_hermes_cea()` and modifies classes via raw `class(out) <- c("hermes_cea", class(out))`.

---

## 4. Test Suite & QA Assessment

- **DuckDB & Eunomia Integration**:
  - `helper-eunomia.R` correctly initializes an in-memory DuckDB instance with synthetic tables (`person`, `observation_period`, `condition_occurrence`, `cost`) and handles clean teardown via `withr::defer()`.
- **Mock vs. Native Execution Assessment**:
  - Unit tests for Stages 3, 4, 5, and 6 (`test-stage3-ps.R`, `test-stage4-trajectories.R`, `test-stage5-simulation.R`, `test-stage6-cea.R`) rely almost entirely on synthetic mock data structures rather than executing against the Eunomia database.
- **Critical End-to-End Test (`test-e2e.R`) Analysis**:
  - `test-e2e.R` appears to execute the full pipeline. However, because `CohortMethod::getDbCohortMethodData` is missing in `R/ps.R`, `fit_ps()` returns `model = NULL`, `adjust_ps()` sets `matched_pop = NA`, `compile_trajectories()` generates empty matrices, and `simulate_economics()` triggers silent fallback defaults.
  - **Conclusion**: `test-e2e.R` passes by executing hardcoded mock fallbacks, NOT actual CDM data processing!
- **Codebase Anti-Patterns**:
  - `test-stage6-cea.R` (line 24) contains `source("../../R/cea.R")`, violating R package testing standards where test scripts must test loaded package exports.

---

## 5. Actionable Remediation Plan

```text
+-----------------------------------------------------------------------------------+
|                               REMEDIATION ROADMAP                                 |
+-----------------------------------------------------------------------------------+
| Phase 1: Pipeline Integrity & Exports (Immediate - CRITICAL)                     |
|   1. Populate NAMESPACE via roxygen2::roxygenise().                               |
|   2. Standardize S3 constructors in R/s3_classes.R and enforce flat objects.     |
|   3. Integrate CohortMethod::getDbCohortMethodData() in R/ps.R.                   |
|   4. Remove silent mock fallbacks in Stage 4 & 5 so pipeline fails explicitly.   |
+-----------------------------------------------------------------------------------+
                                         |
                                         v
+-----------------------------------------------------------------------------------+
| Phase 2: Comprehensive 5-Domain HCRU Extraction Engine (CRITICAL)                |
|   1. Refactor extract_hcru() to join cohort tables, index dates & target windows. |
|   2. Build 5 domain extractors (Inpatient, Outpatient/ED, Pharma, Diag, Post-Acute)|
|   3. Implement DRG fallback lookup and cost masking handling (docs/hcru_logic.md) |
+-----------------------------------------------------------------------------------+
                                         |
                                         v
+-----------------------------------------------------------------------------------+
| Phase 3: Mathematical Calibration & Test Hardening (WARNING / SUGGESTION)          |
|   1. Calibrate PSA Dirichlet concentration parameters from patient counts (N_ij). |
|   2. Refactor Stage 4 to support multi-state trajectories via Cohort2Trajectory. |
|   3. Eliminate source() in test-stage6-cea.R and update function parameter names. |
+-----------------------------------------------------------------------------------+
```

### Phase 1: Pipeline Integrity & Exports (Immediate - CRITICAL)

1. **Populate Package Exports**: Run `roxygen2::roxygenise()` to generate valid `.Rd` documentation and populate `NAMESPACE` with all `@export` directives.
2. **Fix S3 Constructor Hierarchy**: Update `R/s3_classes.R` constructors (`new_hermes_ps`, `new_hermes_trajectories`, `new_hermes_sim`, `new_hermes_cea`). Ensure pipeline functions call these constructors directly and maintain flat attribute lists rather than deeply nested stage objects.
3. **Bridge Stage 2 to Stage 3**: Modify `R/ps.R` to call `CohortMethod::getDbCohortMethodData()` using `study$cdm` and cohort definitions, populating `hcru_obj$cm_data` with valid baseline covariates.
4. **Remove Masking Fallbacks**: Remove hardcoded fallback logic from `R/simulation.R` (lines 15–27) and `R/trajectories.R` (lines 17–25) so that invalid data triggers explicit errors during testing rather than silent execution.

### Phase 2: Comprehensive 5-Domain HCRU Extraction Engine (CRITICAL)

Refactor `R/hcru.R` (`extract_hcru()`) to perform cohort-filtered, temporally windowed SQL/dbplyr joins against the OMOP CDM:

```r
# Target Architecture for extract_hcru()
extract_hcru <- function(study, baseline_window = c(-365, -1), followup_window = c(0, 365)) {
  # 1. Join target/comparator cohorts with CDM event tables
  # 2. Filter events by baseline_window and followup_window relative to cohort_start_date
  # 3. Categorize utilization into 5 domains via visit_concept_id / domain_id:
  #    - Inpatient: visit_concept_id %in% c(9201, 32037) -> count, LOS days, ICU days, 30/90d readmissions
  #    - Outpatient/ED: visit_concept_id %in% c(9202, 9203, 581477) -> GP, specialist, ED visits
  #    - Pharmacotherapy: drug_exposure -> fills, days_supply, PDC persistence
  #    - Diagnostics/Procedures: measurement & procedure_occurrence counts
  #    - Post-Acute: SNF (42898160), home health, hospice stays
  # 4. Join OMOP COST table on cost_event_id and cost_domain_id for direct medical costs
  # 5. Execute DRG lookup fallback if financial metrics are masked or missing
}
```

### Phase 3: Mathematical Calibration & Test Hardening (WARNING / SUGGESTION)

1. **Calibrate PSA Uncertainty**: Update `R/simulation.R` line 104 to set Dirichlet concentration parameters based on actual patient transition counts ($\alpha_{ij} = n_{ij} + 1$) rather than arbitrary pseudo-counts (`alphas <- s_trans[r, ] * 100`).
2. **Wrap Trajectory Engine**: Update Stage 4 (`R/trajectories.R`) to leverage `Cohort2Trajectory` / `TrajectoryMarkovAnalysis` for multi-state patient progression beyond the hardcoded 2-state model.
3. **Clean Test Suite**: Remove `source("../../R/cea.R")` from `test-stage6-cea.R` line 24. Update parameter names in `R/cea.R` (`plot_ceac`, `plot_plane`, `table_summary`) from `study` to `cea_obj`.