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
- **Naming Conventions (DARWIN EU Standard):**
  - **Functions & Arguments:** Use `lowerCamelCase`
    (e.g. `addInpatientHcru()`,
    [`computeHospitalizationCohorts()`](https://rdrr.io/pkg/CohortUtilisation/man/compute_hospitalization_cohorts.html),
    `indexDate = "cohort_start_date"`). Provide snake_case aliases if
    backward compatibility is needed.
  - **Database & Cohort Columns:** Use `snake_case` for all table column
    names (e.g. `cohort_start_date`, `inpatient_admissions`,
    `days_supply`, `total_paid`).
  - **S3 Classes:** Use `snake_case` prefixed with `hermes_`
    (e.g. `hermes_study`, `hermes_hcru`).
- **OMOP/OHDSI Rules:**
  - Never modify core OMOP tables. Write temporary work tables to
    designated result/scratch schemas.
  - Rely on `omopgenerics` accessors (`cohortCount()`, `settings()`).
  - Do not create custom extractors where official OHDSI/DARWIN package
    methods exist.
- **Testing:**
  - Place unit tests in `tests/testthat/`.
  - Ensure all new logic has test coverage using `testthat`.
- **Formatting & Linting:**
  - Adhere to `.github/CONTRIBUTING.md` and
    `extras/PackageMaintenance.R`.
  - Run `styler::style_dir()` and
    `lintr::lint_package(".", linters = lintr::linters_with_defaults(lintr::object_name_linter(styles = "camelCase")))`
    before committing.

------------------------------------------------------------------------

## 3. Mandatory CI, Build & Monorepo Conformance Rules

Before staging, committing, or pushing any changes, every agent must
strictly verify the following conformance checks:

1.  **Package Name Case Sensitivity**:
    - The metapackage name is strictly `omopHeor`. Always write
      [`library(omopHeor)`](https://iomedhealth.github.io/omopHeor/) and
      `test_check("omopHeor")`. Never use variants that fail on
      case-sensitive Linux CI runners.
2.  **Local Monorepo Subpackage Resolution**:
    - Subpackages (`CohortUtilisation`, `CohortCosts`,
      `CohortEconomics`) must be installed and documented locally before
      building the root metapackage:

      ``` r

      pak::pkg_install(c("local::packages/CohortUtilisation", "local::packages/CohortCosts", "local::packages/CohortEconomics"))
      ```

    - In GitHub Actions workflows (`.github/workflows/`), always pass
      `local::packages/*` to `extra-packages` in
      `r-lib/actions/setup-r-dependencies@v2`.
3.  **Vignette Execution Verification**:
    - Every vignette under `vignettes/*.Rmd` must render cleanly without
      errors before pushing:

      ``` r

      lapply(list.files("vignettes", pattern = "[.]Rmd$", full.names = TRUE), rmarkdown::render, output_dir = tempdir())
      ```

    - Ensure all function signatures and arguments called in vignettes
      match active exported APIs.
4.  **Documentation & `pkgdown` Index Conformance**:
    - Run `devtools::document()` across all subpackages (`packages/*`)
      and root (`.`).
    - Every exported function and alias in `man/*.Rd` must be indexed
      under `reference:` in `_pkgdown.yml`.
    - Verify site build locally:
      `pkgdown::build_site(preview = FALSE, install = FALSE)`.
5.  **Clean `R CMD check`**:
    - Ensure
      `rcmdcheck::rcmdcheck(args = c("--no-manual", "--as-cran"), error_on = "warning")`
      passes with 0 errors and 0 warnings on all 3 subpackages and root.

------------------------------------------------------------------------

## 4. Release & Version Management

- **Monorepo Version Synchronization Rule**:
  - The root metapackage `omopHeor` and all 3 subpackages
    (`CohortUtilisation`, `CohortCosts`, `CohortEconomics`) must
    strictly maintain synchronized semantic versioning across all
    `DESCRIPTION` files and internal dependency bounds
    (`CohortUtilisation (>= X.Y.Z)`).
- **Automated Version Bumping**:
  - Agents must use `extras/bumpVersion.R` to bump versions:

    ``` bash
    # Bump patch (e.g. 0.6.1 -> 0.6.2)
    Rscript extras/bumpVersion.R patch

    # Bump minor (e.g. 0.6.1 -> 0.7.0)
    Rscript extras/bumpVersion.R minor

    # Bump major (e.g. 0.6.1 -> 1.0.0)
    Rscript extras/bumpVersion.R major

    # Set explicit version
    Rscript extras/bumpVersion.R 0.7.0
    ```

  - Can also be sourced and invoked within R: `bumpVersion("patch")`.
- **Release Checklist**:
  1.  **Bump Version**: Run
      `Rscript extras/bumpVersion.R <patch|minor|major>` to update all 4
      `DESCRIPTION` files and refresh documentation.

  2.  **Verify Conformance**: Run local tests (`devtools::test()`) and
      package checks
      ([`rcmdcheck::rcmdcheck()`](http://r-lib.github.io/rcmdcheck/reference/rcmdcheck.md)).

  3.  **Commit**: Stage and commit release changes:

      ``` bash
      git commit -am "chore(release): bump version to X.Y.Z"
      ```

  4.  **Tag & Publish Release**:

      ``` bash
      git tag vX.Y.Z
      gh release create vX.Y.Z --title "vX.Y.Z" --notes "Release notes for vX.Y.Z"
      ```

------------------------------------------------------------------------

For additional context about technologies to be used, project structure,
shell commands, and other important information, read the current plan:
specs/005-hcru-domain-extraction/plan.md
