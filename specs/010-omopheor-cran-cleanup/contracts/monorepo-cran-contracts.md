# Interface Contracts: omopHeor & Monorepo CRAN Release

**Feature**: `010-omopheor-cran-cleanup`
**Date**: 2026-08-21

## 1. Metapackage Public API Contract

### Loading & Attachment
```r
library(omopHeor)
```
- **Startup Output**: Tidyverse-style CLI box listing attached packages:
  - `CohortUtilisation <version>`
  - `CohortCosts <version>`
  - `CohortEconomics <version>`
- **Exported Namespace**: Directly re-exports all domain functions without namespace collisions.

### Core Exported Signatures
- **Stage 1**: `init(cdm, target_cohort, comparator_cohort, outcome_cohort)`
- **Stage 2**: `summarise_baseline()`, `extract_hcru()`, `summariseUtilization()`, `summariseCosts()`, `addInpatients()`, `addOutpatientVisits()`, `addEmergencyCare()`, `addPrescriptions()`, `addProcedures()`, `addCosts()`
- **Stage 3**: `fit_ps()`, `adjust_ps()`, `assess_balance()`
- **Stage 4**: `compile_trajectories()`
- **Stage 5**: `simulate_economics()`
- **Stage 6**: `run_cea()`, `plot_ceac()`, `plot_plane()`, `table_summary()`
- **Synthetic Testing**: `mockHERMES(numberIndividuals = 10)`

## 2. Package Metadata & Description Contracts

### Acronym Expansion Standards (CRAN Policy)
All `DESCRIPTION` files must expand the following acronyms in the `Description:` field:
- **OMOP**: Observational Medical Outcomes Partnership (OMOP)
- **CDM**: Common Data Model (CDM)
- **HCRU**: Healthcare Resource Utilization (HCRU)
- **HEOR**: Health Economics and Outcomes Research (HEOR)
- **CEA**: Cost-Effectiveness Analysis (CEA)
- **PS**: Propensity Score (PS)

### Forbidden Metadata
- No `Remotes:` field.
- No references to GitHub repositories in `Suggests:` or `Imports:`.
- No HTTP links or 301 redirects; all URLs must be canonical HTTPS.

## 3. Package Size & Structure Contracts
- `CohortCosts` archive must not contain uncompressed raw datasets > 1 MB.
- All temporary databases generated during tests or examples must be created in `:memory:` or `tempdir()` and cleaned up on exit.
