# Changelog

## omopHeor 0.6.0

### CRAN Readiness & Metapackage Renaming

- **Metapackage Renamed to `omopHeor`**:
  - Renamed umbrella metapackage from `hermes` to `omopHeor` to
    eliminate namespace collision with existing Bioconductor package
    (`hermes` for RNA-Seq QC).
  - Dynamic startup hook updated to display `omopHeor` version and
    attached packages upon
    [`library(omopHeor)`](https://iomedhealth.github.io/omopHeor/).
  - Verified 100% namespace availability across CRAN and Bioconductor.
- **CRAN Policy & Package Footprint Compliance**:
  - **`CohortCosts` Size Reduction**: Removed 46.2 MB of static catalog
    files from `inst/extdata/` to keep package archive \< 50 KB (well
    within CRAN’s \< 5 MB limit).
  - **Dependency Sanitization**: Purged `Remotes:` and GitHub-only
    packages (`Cohort2Trajectory`, `TrajectoryMarkovAnalysis`) across
    all `DESCRIPTION` files.
  - **Acronym Expansion**: Expanded all domain acronyms on first mention
    in all `DESCRIPTION` files (OMOP, CDM, HCRU, HEOR, CEA) and wrapped
    software package names in single quotes.
  - **Import Standardization**: Fixed `dbplyr`, `dplyr`, and `rlang`
    imports to eliminate unused namespace NOTEs on `R CMD check`.
  - **Canonical URLs**: Updated repository and website links to
    canonical HTTPS without 301 redirects (`https://www.iomed.health/`,
    `https://github.com/iomedhealth/hermes/issues`).

------------------------------------------------------------------------
