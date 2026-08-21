# Quickstart & Verification Guide: omopHeor CRAN Pre-Flight

**Feature**: `010-omopheor-cran-cleanup`
**Date**: 2026-08-21

## 1. Local Monorepo Build and Install
```r
# Step 1: Install subpackages in dependency order
pak::pkg_install(c(
  "local::packages/CohortUtilisation",
  "local::packages/CohortCosts",
  "local::packages/CohortEconomics"
))

# Step 2: Install metapackage
pak::pkg_install("local::.")
```

## 2. Verify Metapackage Attachment & Pipeline
```r
library(omopHeor)

# Create synthetic mock CDM
cdm <- mockHERMES(numberIndividuals = 20)

# Verify Stage 1 - 6 pipeline
study <- init(
  cdm = cdm,
  target_cohort = "target_cohort",
  comparator_cohort = "comparator_cohort",
  outcome_cohort = "outcome_cohort"
)

# Verify enricher functions
cdm$target_cohort <- cdm$target_cohort |>
  addInpatients() |>
  addCosts()
```

## 3. Verify CRAN Conformance Across All Packages
```bash
# Verify subpackage 1: CohortUtilisation
R CMD build packages/CohortUtilisation
R CMD check --no-manual --as-cran CohortUtilisation_*.tar.gz

# Verify subpackage 2: CohortCosts
R CMD build packages/CohortCosts
R CMD check --no-manual --as-cran CohortCosts_*.tar.gz

# Verify subpackage 3: CohortEconomics
R CMD build packages/CohortEconomics
R CMD check --no-manual --as-cran CohortEconomics_*.tar.gz

# Verify root metapackage: omopHeor
R CMD build .
R CMD check --no-manual --as-cran omopHeor_*.tar.gz
```

Expected result: 0 Errors, 0 Warnings, 1 Note ("New submission") for each package archive.
