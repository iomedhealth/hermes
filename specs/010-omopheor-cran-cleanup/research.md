# Research: omopHeor Metapackage Renaming and CRAN Readiness

**Feature**: `010-omopheor-cran-cleanup`
**Date**: 2026-08-21

## Key Decisions & Findings

### 1. Metapackage Renaming to `omopHeor`
- **Decision**: Rename the root metapackage from `hermes` to `omopHeor`.
- **Rationale**: 
  - The name `hermes` is already registered on Bioconductor for RNA-Seq data processing. CRAN policy strictly rejects any package name collision with active Bioconductor or CRAN packages (case-insensitive).
  - `omopHeor` is verified to be 100% unreserved and available on both CRAN and Bioconductor.
  - Aligns with the DARWIN EU and OHDSI ecosystem naming pattern (`omopgenerics`, `visOmopResults`, `CohortUtilisation`, `CohortCosts`, `CohortEconomics`).
- **Alternatives Considered**:
  - `hermesheor`: Kept "hermes" prefix, but less idiomatic for OHDSI/OMOP community.
  - `omophermes`: Available, but `omopHeor` directly conveys domain purpose (OMOP HEOR / Health Economics & Outcomes Research).

### 2. Dependency Sanitization & Removal of `Remotes`
- **Decision**: Remove all non-CRAN packages (`Cohort2Trajectory`, `TrajectoryMarkovAnalysis`) and the `Remotes:` field from all `DESCRIPTION` files.
- **Rationale**:
  - CRAN strictly prohibits the `Remotes:` field (`WARNING: Unknown, possibly misspelled, fields in DESCRIPTION: 'Remotes'`).
  - CRAN requires every package listed in `Imports:`, `Depends:`, and `Suggests:` to be published on CRAN or Bioconductor.
  - HERMES Stage 4 (`CohortEconomics/R/trajectories.R`) already implements native OMOP / pure-R trajectory state transitions and does not rely on GitHub-only packages at runtime.
- **Alternatives Considered**:
  - Keeping them in `Suggests` with runtime `requireNamespace`: Rejected by CRAN because non-CRAN packages in `Suggests` trigger CRAN incoming feasibility WARNINGs.

### 3. Footprint Reduction in `CohortCosts`
- **Decision**: Delete large Spanish catalog files (`costs_spain.json` 28 MB, `costs_spain.csv` 17 MB, and `costs_spain.parquet` 1.1 MB) from `packages/CohortCosts/inst/extdata/`.
- **Rationale**:
  - CRAN enforces an archive size limit of < 5 MB. `CohortCosts` was 46.3 MB due to these static assets.
  - `CohortCosts` core R functions query the OMOP CDM `cdm$cost` table directly and never read from `inst/extdata/`.
  - Canonical Spanish cost data remains in the repository root (`data/costs_spain.*`) for external CLI workflows and Airflow pipelines.
- **Alternatives Considered**:
  - Compressing data to `.rda`: Still unnecessary weight (~1 MB) for data not utilized by package functions.

### 4. CRAN Submission Sequencing Strategy
- **Decision**: Follow a 3-wave phased submission process:
  1. **Wave 1 (Independent Subpackages)**: Submit `CohortUtilisation` and `CohortCosts` simultaneously.
  2. **Wave 2 (Analytical Core)**: Submit `CohortEconomics` once Wave 1 is live on CRAN.
  3. **Wave 3 (Metapackage)**: Submit `omopHeor` once Wave 2 is live on CRAN.
- **Rationale**: CRAN cannot build a package that depends on an unpublished package. Staged release ensures strict adherence to CRAN dependency graph constraints.

### 5. Fast Synthetic Examples & Acronym Expansion
- **Decision**: Add self-contained `@examples` using synthetic in-memory DuckDB references via `CDMConnector` / `mockHERMES` with runtime < 5s. Expand all acronyms (OMOP, CDM, HCRU, HEOR, CEA) on first mention in all `DESCRIPTION` files.
- **Rationale**: Required by CRAN Repository Policy and Automated Incoming Checks.
