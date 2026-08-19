# HERMES R Package Audit Report

**Package Name:** HERMES (Health Economic Resource Modeling & Evaluation System)  
**Version:** 0.1.0  
**Audit Date:** August 18, 2026  
**Auditor:** Expert Data Scientist, Bioinformatician & HEOR Software Auditor  
**Target Architecture:** 6-Stage Analytical Pipeline on OMOP CDM (R >= 4.1, `omopgenerics`, `CDMConnector`, `CohortCharacteristics`, `PatientProfiles`, `Cyclops`, `CohortMethod`, `BCEA`, DuckDB/Eunomia)

---

## 1. Executive Summary

A comprehensive technical, mathematical, and architectural audit of the **HERMES** R package was conducted on August 18, 2026. This evaluation tracks progress against findings identified in the August 13, 2026 baseline audit, assesses codebase health across all 6 stages of the analytical pipeline, and validates package behavior against native Eunomia DuckDB databases.

### Status Snapshot
Since August 13, 2026, the HERMES engineering team achieved significant milestones:
- **Exports and Documentation**: Fully populated `NAMESPACE` (12 exported functions) and generated roxygen2 `.Rd` documentation.
- **5-Domain HCRU Extraction Engine**: Implemented an end-to-end HCRU extraction module (`R/hcru.R`, 514 lines) covering Inpatient (LOS, ICU, 30d/90d readmissions), Outpatient (GP, Specialist, ED), Pharmacotherapy (fills, days supply, PDC persistence), Diagnostics/Procedures, and Post-Acute care (SNF stays), linked to OMOP `cost` records.
- **Stage 2 -> Stage 3 Bridge**: Connected Stage 2 to Stage 3 via `PatientProfiles` feature extraction (`addAge`, `addSex`) and `Cyclops` regularized logistic regression, enabling authentic data flow through the causal pipeline.
- **Test Suite Hygiene & Coverage**: Removed anti-pattern `source()` statements, integrated real GiBleed Eunomia CDM test workflows, and achieved **92.95% overall code coverage** with 128 passing `testthat` assertions.

### Remaining Critical Blockers & Newly Identified Debt
Despite substantial progress, the package retains critical mathematical and architectural debt that impedes production deployment:

1. **Uncalibrated PSA Transition Sampling (Remediation Incomplete - CRITICAL)**: `simulate_economics()` (`R/simulation.R`, line 123) still uses the arbitrary Dirichlet pseudo-count multiplier `alphas <- s_trans[r, ] * 100`. This decouples Probabilistic Sensitivity Analysis (PSA) variance from actual cohort sample size ($N$), distorting confidence bounds and Cost-Effectiveness Acceptability Curves (CEAC).
2. **Cycle Cost Rate vs. Cumulative Follow-Up Cost Mismatch (CRITICAL)**: `compile_trajectories()` calculates `mean_cost` as the total unadjusted cumulative expenditure per patient over the observation window (e.g. 1 year). `simulate_economics()` then applies this total cost **at every 30-day Markov cycle** across 122 cycles (10-year horizon), inflating projected lifetime expenditures by >12-fold.
3. **BCEA Strategy Index Inversion (CRITICAL)**: `trajectories.R` and `simulation.R` order strategies as `Strategy 1 = Target` and `Strategy 2 = Comparator`. `BCEA::bcea` interprets Strategy 1 as the reference/baseline and Strategy 2 as the new intervention, inverting incremental metrics ($\Delta C = C_{\text{comp}} - C_{\text{target}}$ and $\Delta E = E_{\text{comp}} - E_{\text{target}}$) and flipping the ICER.
4. **Client-Side In-Memory Collection OOM Hazard (CRITICAL)**: `extract_hcru()` executes `cdm$cost |> collect()` (`R/hcru.R`, line 376), pulling the entire `cost` table into client R memory before joining. On enterprise OMOP CDMs with millions of rows, this causes fatal Out-of-Memory (OOM) process crashes.
5. **Broken `assess_balance()` Diagnostic Engine (CRITICAL)**: `assess_balance()` references `ps_obj$hcru_obj$cm_data` (which is `NULL`) and requires class `CohortMethodData`, causing balance assessment to silently return an empty data frame without calculating Standardized Mean Differences (SMD).
6. **S3 Constructor Bypass & Deep List Nesting (WARNING)**: Constructors in `R/s3_classes.R` remain bypassed in Stages 3 through 6. Pipeline stages wrap prior stage outputs into deeply nested sub-lists (`cea$traj_obj$ps_obj$hcru_obj$cdm`), breaking class inheritance and flat introspection.

---

## 2. Constitutional Compliance Check

| Principle | Status | Audit Findings & Evidence |
| :--- | :---: | :--- |
| **I. Zero Wheel-Reinvention (Package Wrapping Strategy)** | **PARTIAL** | Wraps `CDMConnector`, `PatientProfiles`, `CohortCharacteristics`, `Cyclops`, and `BCEA` (**PASS**). However, Stage 3 bypasses multi-covariate extraction in `CohortMethod`, Stage 4 bypasses `Cohort2Trajectory` / `TrajectoryMarkovAnalysis` using a hardcoded 2-state/30-day model, and Stage 5 bypasses `hesim` / `heemod`. |
| **II. Standardized OMOP CDM & COST Integration** | **PARTIAL** | Core OMOP tables remain immutable (**PASS**). 5 HCRU domains and `cost` table records are linked to cohort subjects and health states (**PASS**). However, `extract_hcru()` executes unconstrained `cdm$cost \|> collect()` into client RAM (`R/hcru.R` line 376), creating severe scalability vulnerabilities. `summarise_baseline()` hardcodes scratch table name `target_profiled_temp` (`R/baseline.R` line 41). |
| **III. Pipeable S3 Architecture** | **PARTIAL** | Fully compliant with base R pipe `\|>` and `<-` assignment (**PASS**). However, S3 constructors in `R/s3_classes.R` (`new_hermes_ps`, `new_hermes_trajectories`, `new_hermes_sim`, `new_hermes_cea`) are bypassed, resulting in deep nested sub-lists (`sim$traj_obj$ps_obj$hcru_obj`). |
| **IV. Test-First & Coverage (NON-NEGOTIABLE)** | **PASS** | 128/128 tests pass across 8 test suites. 92.95% code coverage. End-to-end (`test-e2e.R`) and PS tests (`test-stage3-ps.R`) execute on real DuckDB/Eunomia GiBleed cohorts via `CohortConstructor::conceptCohort()`. Vestigial `source()` call removed. |
| **V. 6-Stage Analytical Pipeline Alignment** | **PASS** | All 6 stages execute end-to-end with authentic data flow. Real PS matching drives transition probability calculation and decision analysis plotting. |

---

## 3. Verification of Past Remediation Points (from Aug 13 Audit)

| # | Remediation Item | Target Stage | Aug 18 Status | Audit Evidence & Residual Debt |
| :---: | :--- | :---: | :---: | :--- |
| **1** | Populate `NAMESPACE` & Documentation | Core / Exports | **RESOLVED** | `NAMESPACE` exports 12 functions. All `.Rd` files generated in `man/`. Clean export validation. |
| **2** | 5-Domain HCRU Engine & Windowing | Stage 2 (`R/hcru.R`) | **SUBSTANTIALLY RESOLVED** | Inpatient (LOS, ICU, 30d/90d readmissions), Outpatient (GP/Spec/ED), Pharmacotherapy (fills, days, PDC), Diagnostics, and Post-Acute care implemented with baseline/follow-up windows. *Residual debt: In-memory table collection and missing DRG lookup fallback.* |
| **3** | Stage 2 -> Stage 3 Bridge (`R/ps.R`) | Stage 3 (`R/ps.R`) | **RESOLVED** | `fit_ps()` extracts `age` and `sex` via `PatientProfiles` and fits `Cyclops` logistic model. Propensity scores populate `matched_pop`. *Residual debt: `assess_balance()` broken; covariates limited to age/sex.* |
| **4** | Remove Silent Fallback Defaults | Stage 4 & 5 | **RESOLVED** | Hardcoded fallback matrices and dummy costs in `simulation.R` and `trajectories.R` replaced with explicit `stop()` assertions. |
| **5** | Calibrate PSA Dirichlet Sampling | Stage 5 (`R/simulation.R`) | **UNRESOLVED (CRITICAL)** | `R/simulation.R` line 123 retains `alphas <- s_trans[r, ] * 100`. Pseudo-count multiplier remains hardcoded to 100 rather than calibrated from observed transition counts $n_{ij} + 1$. |
| **6** | Test Suite Hygiene & Real CDM Execution | Tests | **RESOLVED** | `source()` removed from `test-stage6-cea.R`. `test-stage3-ps.R` and `test-e2e.R` run on native DuckDB Eunomia. |

---

## 4. Deep Dive Technical Findings by Stage

```text
========================================================================================
                                PIPELINE FINDINGS MAP
========================================================================================
 Stage 1 (Init)        ──> [WARN] Missing omopgenerics::isCohortTable() validation (L26)
 Stage 2 (Baseline)    ──> [WARN] Hardcoded temp table 'target_profiled_temp' (L41)
                           [WARN] Comparator cohort omitted from baseline summary (L35)
 Stage 2 (HCRU)        ──> [CRITICAL] Unbounded cdm$cost |> collect() in RAM (L376)
                           [SUGGESTION] DRG lookup fallback unbuilt (L361)
 Stage 3 (PS)          ──> [CRITICAL] assess_balance() references NULL cm_data (L173)
                           [WARN] Greedy caliper matches on raw probability, not logit (L127)
                           [SUGGESTION] Confounder extraction limited to age and sex (L32)
 Stage 4 (Trajectories)──> [CRITICAL] Selection bias: zero-cost cohort patients excluded (L85)
                           [WARN] Hardcoded 30-day binary window drops long-term outcomes (L44)
 Stage 5 (Simulation)  ──> [CRITICAL] Uncalibrated Dirichlet multiplier (* 100) (L123)
                           [CRITICAL] Cumulative cost applied as per-cycle rate (L139)
 Stage 6 (Decision)    ──> [CRITICAL] BCEA strategy ordering inverted (Target vs SoC) (L25)
                           [SUGGESTION] Argument named 'study' instead of 'cea_obj' (L55)
========================================================================================
```

---

### Stage 1: Cohort Generation (`R/init.R`)

- **Finding 1.1 (WARNING): Incomplete Cohort Class and Content Validation**
  - **Location**: `R/init.R`, lines 26–30, 33–38
  - **Technical Implication**: `init()` verifies table name existence in `names(cdm)` using string matching, but fails to check whether the referenced table is an authentic `omopgenerics` cohort table (`omopgenerics::isCohortTable(cdm[[cohort_name]])`). Furthermore, if an input cohort table contains 0 subjects, `init()` succeeds without a warning, propagating empty tables into downstream stages.
  - **Remediation**:
    ```r
    for (cohort_name in c(target_cohort, comparator_cohort, outcome_cohort)) {
      if (!cohort_name %in% names(cdm)) {
        stop(sprintf("Cohort table '%s' not found in CDM", cohort_name))
      }
      if (!omopgenerics::isCohortTable(cdm[[cohort_name]])) {
        stop(sprintf("Table '%s' is not a valid omopgenerics cohort table", cohort_name))
      }
      cnt <- omopgenerics::cohortCount(cdm[[cohort_name]])
      if (nrow(cnt) == 0 || sum(cnt$number_subjects, na.rm = TRUE) == 0) {
        warning(sprintf("Cohort '%s' is empty (0 subjects).", cohort_name))
      }
    }
    ```

---

### Stage 2: Baseline Characterization & HCRU Extraction (`R/baseline.R`, `R/hcru.R`)

- **Finding 2.1 (WARNING): Scratch Schema Table Collision & Comparator Omission in Baseline Summary**
  - **Location**: `R/baseline.R`, lines 35–48
  - **Technical Implication**: 
    1. Line 41 writes intermediate data to `name = "target_profiled_temp"` with `overwrite = TRUE`. In multi-tenant environments or parallel execution threads sharing a single `writeSchema`, concurrent runs will collide and corrupt intermediate cohort state.
    2. Although the code comment (line 33) states *"We summarize both target and comparator if they exist"*, line 35 exclusively profiles `study$target_cohort`. `study$comparator_cohort` is never profiled or summarized, leaving the comparator uncharacterized.
  - **Remediation**: Use session-unique temporary table names (e.g. `paste0("tmp_prof_", as.integer(Sys.time()), "_", sample.int(1e5, 1))`) and profile both target and comparator cohorts.

- **Finding 2.2 (CRITICAL): Unbounded Client-Side Collection of OMOP `COST` Table**
  - **Location**: `R/hcru.R`, lines 376, 137, 251, 295, 309
  - **Technical Implication**: `cost_raw <- cdm$cost |> collect()` (line 376) pulls the **entire** database `cost` table into local client memory prior to cohort filtering and domain joins. In real-world enterprise databases containing tens of millions of records, this triggers fatal Out-of-Memory (OOM) errors. Additionally, using `filter(person_id %in% cohort_sub_ids)` with large cohorts passes thousands of literal IDs, breaching SQL parameter limits (e.g. Oracle 1,000, SQL Server 2,100).
  - **Remediation**: Execute database-side semi-joins directly using `dbplyr`:
    ```r
    # Execute database-side filtering before collection
    study_subjects_db <- cdm[[target_name]] |>
      dplyr::select(subject_id = "subject_id") |>
      dplyr::union_all(cdm[[comp_name]] |> dplyr::select(subject_id = "subject_id")) |>
      dplyr::distinct()

    cost_db <- cdm$cost |>
      dplyr::inner_join(study_subjects_db, by = c("person_id" = "subject_id"))
    ```

- **Finding 2.3 (SUGGESTION): Missing DRG Fallback Dictionary Integration**
  - **Location**: `R/hcru.R`, lines 361–375; `vignettes/hcru_logic.Rmd`, lines 50–64
  - **HEOR Implication**: `vignettes/hcru_logic.Rmd` specifies DRG fallback when financial columns are masked or zero. Currently, `extract_hcru()` only logs a warning if the `cost` table is missing, but lacks DRG code lookup mappings (`drg_concept_id` / `drg_source_value`).

---

### Stage 3: Causal Propensity Score Adjustment (`R/ps.R`)

- **Finding 3.1 (CRITICAL): Broken `assess_balance()` Engine Preventing SMD Diagnostics**
  - **Location**: `R/ps.R`, lines 173–177
  - **Technical Implication**: `assess_balance()` checks `!is.null(ps_obj$hcru_obj$cm_data)`. However, `fit_ps()` stores data at `ps_obj$cm_data`, meaning `ps_obj$hcru_obj$cm_data` is always `NULL`. Furthermore, `fit_ps()` produces a standard data frame, so `inherits(..., "CohortMethodData")` evaluates to `FALSE`. Consequently, `assess_balance()` silently returns an empty `data.frame()`, completely disabling Standardized Mean Difference (SMD) diagnostics and Love plot generation.
  - **Remediation**: Compute empirical SMDs directly from `ps_obj$cm_data` pre- and post-matching:
    ```r
    assess_balance <- function(ps_obj, ...) {
      pop <- ps_obj$matched_pop
      data_all <- ps_obj$cm_data
      if (is.null(pop) || nrow(pop) == 0 || is.null(data_all)) {
        ps_obj$smd_summary <- data.frame()
        return(ps_obj)
      }
      # Calculate SMD for age and sex pre vs post matching
      vars <- c("age", "sex_num")
      calc_smd <- function(df) {
        t <- df[df$treatment == 1, ]
        c <- df[df$treatment == 0, ]
        sapply(vars, function(v) {
          m1 <- mean(t[[v]], na.rm = TRUE); v1 <- var(t[[v]], na.rm = TRUE)
          m0 <- mean(c[[v]], na.rm = TRUE); v0 <- var(c[[v]], na.rm = TRUE)
          abs(m1 - m0) / sqrt((v1 + v0) / 2)
        })
      }
      smd_pre <- calc_smd(data_all)
      smd_post <- calc_smd(pop |> dplyr::inner_join(data_all |> dplyr::select(subject_id, treatment, age, sex_num), by = c("subject_id", "treatment")))
      
      ps_obj$smd_summary <- data.frame(
        covariate = vars,
        smd_unadjusted = smd_pre,
        smd_adjusted = smd_post
      )
      structure(ps_obj, class = c("hermes_ps", "hermes_study", "list"))
    }
    ```

- **Finding 3.2 (WARNING): Caliper Matching on Raw Probability vs. Standardized Logit Scale**
  - **Location**: `R/ps.R`, lines 126–130
  - **Methodological Implication**: `adjust_ps()` performs nearest-neighbor matching by checking `abs(c_ps - ps_t) <= caliper` directly on the raw propensity score scale ($[0, 1]$). In causal inference literature (Austin 2011, Rosenbaum & Rubin 1985), a caliper of 0.2 must be defined on the *standardized logit scale* ($\text{logit}(PS) = \ln(PS / (1 - PS))$ with tolerance $0.2 \times \sigma_{\text{logit}}$). Matching on the probability scale distorts matches in high- and low-probability tails.

- **Finding 3.3 (SUGGESTION): Confounder Adjustment Restricted to Age and Sex**
  - **Location**: `R/ps.R`, lines 30–46, 61–65
  - **Clinical Implication**: `fit_ps()` hardcodes covariate extraction to `addAge()` and `addSex()`. Real-world HEOR studies require adjustment for baseline comorbidities (e.g. Charlson Comorbidity Index, prior myocardial infarction, diabetes) and baseline healthcare utilization to eliminate residual confounding.

---

### Stage 4: Trajectory Compilation & State Costs (`R/trajectories.R`)

- **Finding 4.1 (CRITICAL): Upward Selection Bias in State Cost Estimation**
  - **Location**: `R/trajectories.R`, lines 84–102
  - **Mathematical Implication**: `costs_summary` groups `ps_obj$hcru_obj$costs` by `health_state` and `subject_id`. However, `ps_obj$hcru_obj$costs` only contains patients who generated at least one billable event in the `cost` table. Matched patients who incurred \$0 are excluded from the aggregation. As a consequence, `n_patients` represents the number of *cost-incurring patients* rather than the *total cohort size*, biasing mean health state costs substantially upward.
  - **Remediation**: Left-join `matched_pop` with `costs` so zero-cost patients are included with `patient_total = 0`.

- **Finding 4.2 (WARNING): Hardcoded 30-Day Binary Outcome Window Dropping Longitudinal Events**
  - **Location**: `R/trajectories.R`, lines 41–50
  - **HEOR Implication**: `calc_trans()` calculates transition probability as `n_outcome_30d / n_total` where `days_to_outcome <= 30`. Patients experiencing the outcome event on day 31 or later are classified as never experiencing the outcome ($p = 0$). Cycle length and follow-up time horizons must be user-configurable parameters rather than a fixed 30-day cutoff.

---

### Stage 5: Economic Simulation Engine (`R/simulation.R`)

- **Finding 5.1 (CRITICAL): Uncalibrated PSA Transition Uncertainty (Hardcoded Dirichlet Multiplier)**
  - **Location**: `R/simulation.R`, lines 122–127
  - **Mathematical Implication**:
    ```r
    for (r in 1:nrow(s_trans)) {
      alphas <- s_trans[r, ] * 100
      alphas[alphas == 0] <- 0.001
      g_draws <- stats::rgamma(length(alphas), shape = alphas, scale = 1)
      s_trans[r, ] <- g_draws / sum(g_draws)
    }
    ```
    Dirichlet parameter vectors $\boldsymbol{\alpha}$ represent the effective sample count of observed transitions ($\alpha_{ij} = n_{ij} + \alpha_{0,ij}$). Multiplying probabilities by a fixed factor of 100 imposes an arbitrary pseudo-sample size of $N=100$. For a large trial ($N=50,000$), this artificially inflates parameter variance by 500-fold; for a small cohort ($N=10$), it understates parameter uncertainty.
  - **Remediation**: Pass observed transition count matrix $N_{ij}$ from Stage 4 into Stage 5 and set $\alpha_{ij} = n_{ij} + 0.5$ (Jeffreys prior).

- **Finding 5.2 (CRITICAL): Mathematical Scale Mismatch: Cumulative Cost Applied as Per-Cycle Expenditure**
  - **Location**: `R/simulation.R`, lines 135–144; `R/trajectories.R`, lines 84–102
  - **Mathematical Implication**: In Stage 4, `mean_cost` represents the unadjusted total cumulative cost per patient across the entire follow-up window (e.g. 365 days). In Stage 5, `simulate_economics()` runs 122 cycles (30-day cycles over 10 years) and adds `cycle_cost <- sum(current_state * s_costs) * discount_vec[cycle]` **at each cycle**. Applying an annual cumulative cost 12 times per year over 10 years inflates total projected lifetime costs by more than 12-fold!
  - **Remediation**: Normalize state costs in Stage 4 to cost per day ($\text{mean\_cost} / \text{followup\_days}$), and in Stage 5 compute `cycle_cost <- sum(current_state * s_costs) * (cycle_days) * discount_vec[cycle]`.

- **Finding 5.3 (SUGGESTION): Omission of Half-Cycle Correction**
  - **Location**: `R/simulation.R`, lines 135–144
  - **Methodological Implication**: Discrete Markov cohort simulation applies state costs and utilities at discrete cycle endpoints without half-cycle correction (e.g. trapezoidal rule $0.5 \cdot C_0 + \sum C_t + 0.5 \cdot C_T$), introducing systematic integration bias over long time horizons.

---

### Stage 6: Decision Analysis & Post-Processing (`R/cea.R`)

- **Finding 6.1 (CRITICAL): Inverted BCEA Strategy Assignment Inverting ICER and Recommendations**
  - **Location**: `R/cea.R`, lines 25–32; `R/simulation.R`, lines 32–34
  - **HEOR Implication**: `simulate_economics()` iterates strategies using `names(traj_obj$matrices)`, producing Strategy 1 = Target and Strategy 2 = Comparator. In `BCEA::bcea(e = e_mat, c = c_mat)`, BCEA treats Strategy 1 as the reference/baseline intervention and Strategy 2 as the new intervention. Consequently, BCEA computes:
    $$\Delta C = C_{\text{comp}} - C_{\text{target}}, \quad \Delta E = E_{\text{comp}} - E_{\text{target}}$$
    $$\text{ICER} = \frac{C_{\text{comp}} - C_{\text{target}}}{E_{\text{comp}} - E_{\text{target}}}$$
    This evaluates the cost-effectiveness of the *Comparator replacing the Target*, inverting the standard HEOR formulation where the Target intervention is evaluated relative to Standard of Care.
  - **Remediation**: Ensure Strategy 1 is Comparator (Standard of Care) and Strategy 2 is Target (New Treatment) when passing matrices to `BCEA::bcea()`.

- **Finding 6.2 (SUGGESTION): Function Parameter Naming Inconsistency**
  - **Location**: `R/cea.R`, lines 55, 71, 97
  - **Technical Implication**: `plot_ceac(study)`, `plot_plane(study)`, and `table_summary(study)` use the parameter name `study` rather than `cea_obj` or `hermes_cea`, inconsistent with `API_SPECIFICATION.Rmd` and standard S3 dispatch conventions.

---

### Architectural & S3 Class Hierarchy Review (`R/s3_classes.R`)

- **Finding 7.1 (WARNING): S3 Constructor Bypass & Deep Nested Sub-Lists**
  - **Location**: `R/s3_classes.R`, lines 10–24; `R/ps.R`, line 78; `R/trajectories.R`, line 107; `R/simulation.R`, line 151; `R/cea.R`, line 36
  - **Technical Implication**: Constructors `new_hermes_ps()`, `new_hermes_trajectories()`, `new_hermes_sim()`, and `new_hermes_cea()` are completely bypassed (coverage: 33.3%). Functions construct ad-hoc lists nesting previous stage objects:
    $$\text{hermes\_cea} \supset \text{traj\_obj} \supset \text{ps\_obj} \supset \text{hcru\_obj} \supset \text{study} \supset \text{cdm}$$
    Accessing fundamental metadata requires awkward chaining (`cea$traj_obj$ps_obj$hcru_obj$cdm`).
  - **Remediation**: Maintain flat object attributes passed through constructors:
    ```r
    new_hermes_ps <- function(cdm, target_cohort, comparator_cohort, outcome_cohort,
                            cm_data, model, matched_pop, smd_summary = data.frame(), ...) {
      structure(
        list(
          cdm = cdm,
          target_cohort = target_cohort,
          comparator_cohort = comparator_cohort,
          outcome_cohort = outcome_cohort,
          cm_data = cm_data,
          model = model,
          matched_pop = matched_pop,
          smd_summary = smd_summary,
          ...
        ),
        class = c("hermes_ps", "hermes_study", "list")
      )
    }
    ```

---

## 5. Test Suite & QA Assessment

### Test Suite Execution Summary
- **Total Test Files**: 8 files (`test-stage1-init.R`, `test-stage2-hcru.R`, `test-stage3-ps.R`, `test-stage4-trajectories.R`, `test-stage5-simulation.R`, `test-stage6-cea.R`, `test-fixture.R`, `test-e2e.R`).
- **Test Results**: **128 PASS / 0 FAIL / 0 WARN / 0 SKIP**.
- **Execution Engine**: Native DuckDB in-memory database and Eunomia GiBleed synthetic CDM.

### Code Coverage Breakdown (`covr::package_coverage()`)
| Source File | Line Coverage | Assessment |
| :--- | :---: | :--- |
| `R/init.R` | 100.00% | Full coverage of Stage 1 cohort initialization. |
| `R/baseline.R` | 100.00% | Full coverage of baseline characteristics profiling. |
| `R/hcru.R` | 97.99% | Comprehensive coverage across all 5 utilization domains. |
| `R/simulation.R` | 88.76% | High coverage of PSA Markov simulation engine. |
| `R/cea.R` | 85.71% | High coverage of BCEA post-processing and plotting. |
| `R/trajectories.R` | 85.53% | High coverage of transition matrix and cost derivation. |
| `R/ps.R` | 82.93% | Covers `fit_ps` and `adjust_ps`; `assess_balance` branch unreached due to bug. |
| `R/s3_classes.R` | 33.33% | Low coverage due to constructor bypass anti-pattern. |
| **Total Package Coverage** | **92.95%** | **Outstanding test coverage.** |

---

## 6. Actionable Remediation Plan

```text
+-----------------------------------------------------------------------------------+
|                        HERMES REMEDIATION ROADMAP (AUG 2026)                      |
+-----------------------------------------------------------------------------------+
| Milestone 1: Mathematical Engine Calibration & BCEA Alignment (CRITICAL)         |
|   1. Fix BCEA strategy ordering: SoC = Strategy 1, Target = Strategy 2.          |
|   2. Normalize Stage 4 costs to daily/cycle rates (prevent 12x inflation).       |
|   3. Calibrate Stage 5 Dirichlet sampling with observed transition counts (N_ij). |
|   4. Fix assess_balance() to compute empirical SMDs on matched populations.      |
+-----------------------------------------------------------------------------------+
                                         |
                                         v
+-----------------------------------------------------------------------------------+
| Milestone 2: Enterprise CDM Scalability & Database-Side Querying (CRITICAL)      |
|   1. Refactor extract_hcru() to execute dbplyr semi-joins on cdm$cost.           |
|   2. Eliminate unbounded cdm$cost |> collect() in client RAM.                     |
|   3. Replace hardcoded temporary table names in summarise_baseline().            |
+-----------------------------------------------------------------------------------+
                                         |
                                         v
+-----------------------------------------------------------------------------------+
| Milestone 3: S3 Architecture & Clinical Feature Expansion (WARNING / SUGGESTION) |
|   1. Adopt flat S3 object hierarchy across new_hermes_* constructors.             |
|   2. Expand Stage 3 PS covariates beyond age/sex (comorbidities, prior HCRU).    |
|   3. Implement logit-scale caliper matching and DRG fallback lookup.              |
+-----------------------------------------------------------------------------------+
```

### Milestone 1: Mathematical Engine Calibration (Immediate - CRITICAL)

1. **Invert Strategy Ordering for BCEA (`R/trajectories.R`, `R/simulation.R`)**:
   Ensure `comparator_transition` is indexed as Strategy 1 and `target_transition` as Strategy 2 so BCEA computes $\text{ICER} = (C_{\text{target}} - C_{\text{comp}}) / (E_{\text{target}} - E_{\text{comp}})$.
2. **Normalize Health State Costs**:
   In `R/trajectories.R`, divide cumulative costs by patient days observed to yield $\text{cost\_per\_day}$, and in `R/simulation.R`, multiply daily costs by cycle duration (e.g. 30 days).
3. **Calibrate PSA Dirichlet Uncertainty**:
   In `R/simulation.R`, replace `alphas <- s_trans[r, ] * 100` with $\alpha_{ij} = n_{ij} + 0.5$ using the empirical transition count matrix $N_{ij}$ from Stage 4.
4. **Fix `assess_balance()`**:
   Update `R/ps.R` to compute empirical unadjusted vs. adjusted SMDs for baseline covariates using `ps_obj$cm_data` and `ps_obj$matched_pop`.

### Milestone 2: Enterprise CDM Scalability (CRITICAL)

1. **Database-Side Semi-Joins in `extract_hcru()`**:
   Replace in-memory filtering (`cost_raw <- cdm$cost |> collect()`) with dbplyr semi-joins against cohort tables on the database server before calling `collect()`.
2. **Session-Unique Temporary Tables**:
   Update `R/baseline.R` to generate dynamic random table identifiers in `writeSchema`.

### Milestone 3: S3 Hierarchy & Clinical Generalization (WARNING / SUGGESTION)

1. **Enforce S3 Constructor Hierarchy**:
   Refactor `fit_ps`, `compile_trajectories`, `simulate_economics`, and `run_cea` to populate flat attributes and return via `new_hermes_*` constructors.
2. **Standardized Logit Caliper Matching**:
   Update `adjust_ps()` to compute distance on $\text{logit}(PS) / \text{sd}(\text{logit}(PS))$.
3. **Multi-Covariate Extraction**:
   Support user-specified condition concepts and prior utilization counts in `fit_ps()`.

---

## 7. Audit Conclusion & Sign-Off

The HERMES R package has made commendable progress between August 13 and August 18, 2026. The 5-domain HCRU extraction engine and real Eunomia integration establish a solid foundation for OMOP-native health economics. Resolving the identified mathematical scaling and Dirichlet calibration issues will elevate HERMES to a production-ready, publication-grade HEOR software ecosystem.

**Audit Status:** **CONDITIONALLY APPROVED (Pending Milestone 1 & 2 Remediation)**  
**Next Formal Audit Review:** September 1, 2026
