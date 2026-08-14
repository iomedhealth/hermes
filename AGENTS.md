# HERMES Agent Guidelines & Architecture Instructions

Welcome to the **HERMES** repository. HERMES is an R package ecosystem
for Real-World Evidence (RWE) and Health Economics and Outcomes Research
(HEOR) focused on Healthcare Resource Utilization (HCRU) and
Cost-Effectiveness Analysis (CEA) on OMOP CDM data.

------------------------------------------------------------------------

## 1. Core Architecture & The 6-Stage Analytical Pipeline

Agents developing functions or modules in HERMES must align their
implementations with the 6-stage framework:

1.  **Stage 1: Cohort Generation**
    - Define target treatment, comparator, and clinical outcome cohorts
      using standardized vocabularies.
    - Enforce `omopgenerics` standards for cohort table creation and
      cohort naming (`snake_case`, \<100 characters).
2.  **Stage 2: Descriptive Baseline & HCRU Characterization**
    - Build unadjusted baseline tables enriched with demographics.
    - Evaluate entry timing and cohort attrition.
    - Extract raw unadjusted care utilization (hospitalizations,
      outpatient visits, ED visits, drug prescriptions) and direct
      medical costs.
3.  **Stage 3: Causal Propensity Score (PS) Adjustment**
    - Fit high-dimensional regularized logistic regression models based
      on baseline clinical features.
    - Provide modular helpers for matching, trimming, weighting, and SMD
      balance diagnostic plots.
4.  **Stage 4: Trajectory Compilation & State-Cost Extraction**
    - Aggregate longitudinal patient timelines into discrete, mutually
      exclusive health states over uniform time cycles.
    - Compute state-to-state transition probability matrices and pull
      state-specific cost distributions directly from the OMOP `COST`
      table.
5.  **Stage 5: Economic Simulation**
    - Provide wrappers and exporters for decision-analytic
      state-transition models and microsimulations incorporating
      parametric uncertainty.
6.  **Stage 6: Decision Analysis & Post-Processing (CEA)**
    - Export standardized summaries and plots for Incremental
      Cost-Effectiveness Ratios (ICER), Net Monetary Benefit (NMB), and
      Cost-Effectiveness Acceptability Curves (CEAC).

------------------------------------------------------------------------

## 2. Code Style & Development Guidelines

- **Language:** R (Target R \>= 4.1).
- **Pipes:** Always use the base R pipe `|>` instead of `%>%`.
- **Assignment:** Always use `<-` for assignment (never `=`).
- **Naming Conventions:** Use `snake_case` for functions, parameters,
  and variable names.
- **OMOP/OHDSI Rules:**
  - Never modify core OMOP tables. Write temporary work tables to
    designated result/scratch schemas.
  - Rely on `omopgenerics` accessors (`cohortCount()`, `settings()`).
  - Do not create custom extractors where official OHDSI/DARWIN package
    methods exist.
- **Testing:**
  - Place unit tests in `tests/testthat/`.
  - Ensure all new logic has test coverage using `testthat`.
- **Formatting:**
  - Run `styler::style_dir()` and `lintr::lint_dir()` before committing.

For additional context about technologies to be used, project structure,
shell commands, and other important information, read the current plan:
specs/004-fix-e2e-data-flow/plan.md
