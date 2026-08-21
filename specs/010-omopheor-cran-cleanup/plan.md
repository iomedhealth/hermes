# Implementation Plan: omopHeor Metapackage Renaming and CRAN-Readiness Cleanup

**Branch**: `010-omopheor-cran-cleanup` | **Date**: 2026-08-21 | **Spec**: [specs/010-omopheor-cran-cleanup/spec.md](spec.md)

**Input**: User description: "execute the renaming and CRAN-readiness cleanup"

## Summary

This plan renames the root metapackage from `hermes` to `omopHeor` to eliminate namespace collision with an existing Bioconductor package (`hermes`), strips 46.2 MB of unused tariff data from `CohortCosts/inst/extdata/` to satisfy CRAN size limits (< 5 MB), purges all non-CRAN package dependencies (`Cohort2Trajectory`, `TrajectoryMarkovAnalysis`) and forbidden `Remotes:` fields across all `DESCRIPTION` files, expands acronyms and formats documentation according to CRAN repository policies, and guarantees clean `R CMD check --as-cran` passes across all 4 packages.

## Technical Context

**Language/Version**: R (>= 4.1.0)

**Primary Dependencies**: 
- CRAN Core: `CDMConnector (>= 1.4.0)`, `omopgenerics (>= 0.3.0)`, `dbplyr (>= 2.4.0)`, `dplyr (>= 1.1.0)`, `ggplot2`, `rlang`, `cli`, `glue`, `BCEA`, `duckdb`
- CRAN Suggests: `PatientProfiles`, `CohortConstructor`, `CohortCharacteristics`, `visOmopResults`, `CohortMethod`, `Cyclops`, `hesim`, `heemod`, `Eunomia`, `testthat (>= 3.0.0)`, `withr`, `covr`

**Storage**: In-memory DuckDB and database-backed OMOP CDM v5.3 / v5.4

**Testing**: `testthat (edition 3)`, `rcmdcheck` (`--no-manual --as-cran`)

**Target Platform**: CRAN (Linux x86_64/ARM64, Windows, macOS)

**Project Type**: Monorepo R package suite (3 domain subpackages + 1 umbrella metapackage)

**Performance Goals**: Fast synthetic examples (< 5 seconds total runtime per package check), tarball sizes < 1 MB.

**Constraints**: Strict adherence to CRAN repository policies (no non-CRAN deps, no `Remotes:`, unique package name, expanded acronyms in Description, < 5 MB package archive).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Zero Non-CRAN Dependencies**: All packages in `Imports:` and `Suggests:` must be published on CRAN or Bioconductor. (*PASS - GitHub packages removed*).
- **CRAN Archive Size Limit**: Package archives must be < 5 MB. (*PASS - `CohortCosts/inst/extdata` purged*).
- **Global Package Name Uniqueness**: Package name must not collide with any existing CRAN or Bioconductor package. (*PASS - `hermes` renamed to `omopHeor`*).
- **DARWIN EU / OHDSI Standards**: Snake case database columns, lowerCamelCase function names, S3 classes, base R pipes `|>`. (*PASS*).

## Project Structure

### Documentation (this feature)

```text
specs/010-omopheor-cran-cleanup/
├── plan.md              # Implementation plan
├── research.md          # Phase 0: CRAN policy and naming research
├── data-model.md        # Phase 1: Package architecture and dependency graph
├── quickstart.md        # Phase 1: Quickstart and pre-flight validation
├── contracts/           # Phase 1: Public interface contracts
│   └── monorepo-cran-contracts.md
└── checklists/
    └── requirements.md  # Requirements validation checklist
```

### Source Code Layout

```text
.
├── DESCRIPTION                      # Metapackage: omopHeor
├── LICENSE                          # MIT License
├── R/
│   ├── zzz.R                        # omopHeor startup banner
│   ├── reexports.R                  # Re-exports from subpackages
│   └── mockHERMES.R                 # Synthetic in-memory CDM fixture
├── tests/
│   ├── testthat.R                   # Metapackage test entrypoint
│   └── testthat/                    # Metapackage integration tests
├── vignettes/                       # Ecosystem vignettes
└── packages/
    ├── CohortUtilisation/           # Subpackage 1: HCRU metrics
    │   ├── DESCRIPTION
    │   ├── R/
    │   └── tests/
    ├── CohortCosts/                 # Subpackage 2: Direct medical costs
    │   ├── DESCRIPTION
    │   ├── R/
    │   └── tests/
    └── CohortEconomics/             # Subpackage 3: PS, Trajectories, Microsimulation, CEA
        ├── DESCRIPTION
        ├── R/
        └── tests/
```

## Implementation Phases

### Phase 1: Subpackage Cleanups & CRAN Readiness
1. **`CohortCosts`**:
   - Delete `packages/CohortCosts/inst/extdata/costs_spain.*` and `ine_indices_sanidad.*`.
   - Update `packages/CohortCosts/R/CohortCosts-package.R` to import from `dbplyr` (`#' @importFrom dbplyr in_schema`).
   - Format `Description:` in `packages/CohortCosts/DESCRIPTION` with expanded acronyms.
   - Run `devtools::document("packages/CohortCosts")`.
2. **`CohortEconomics`**:
   - Remove `Cohort2Trajectory`, `TrajectoryMarkovAnalysis`, and `Remotes:` from `packages/CohortEconomics/DESCRIPTION`.
   - Format `Description:` in `packages/CohortEconomics/DESCRIPTION` with expanded acronyms.
   - Fix `packages/CohortEconomics/tests/testthat/test-e2e.R` to qualify `CohortCosts::addCosts()` and ensure DuckDB fixtures avoid writing to `~/.duckdb`.
   - Run `devtools::document("packages/CohortEconomics")`.
3. **`CohortUtilisation`**:
   - Format `Description:` in `packages/CohortUtilisation/DESCRIPTION` with expanded acronyms.
   - Run `devtools::document("packages/CohortUtilisation")`.

### Phase 2: Metapackage Renaming (`hermes` → `omopHeor`)
1. **`DESCRIPTION`**:
   - Rename `Package: hermes` to `Package: omopHeor`.
   - Remove `Remotes:` and GitHub-only packages from `Suggests:`.
   - Expand all acronyms in `Description:`.
   - Fix canonical URLs (`https://www.iomed.health/`, `https://github.com/iomedhealth/hermes/issues`).
2. **`R/zzz.R`**:
   - Update startup message header from `hermes` to `omopHeor`.
3. **`tests/testthat.R`**:
   - Update to `library(omopHeor)` and `test_check("omopHeor")`.
4. **`R/mockHERMES.R` & Examples**:
   - Update `@examples` from `library(hermes)` to `library(omopHeor)`.
5. **Documentation, Vignettes, and Citations**:
   - Update `inst/CITATION` and `vignettes/*.Rmd` references to `library(omopHeor)`.
   - Run `devtools::document(".")`.

### Phase 3: Comprehensive Monorepo Validation
1. Install subpackages and metapackage locally.
2. Run `devtools::test()` on all subpackages and root.
3. Build `.tar.gz` packages and run `R CMD check --no-manual --as-cran` on all 4 archives.
4. Render all vignettes to verify error-free execution.
