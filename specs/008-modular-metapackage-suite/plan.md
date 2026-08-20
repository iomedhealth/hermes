# Implementation Plan: Modular DARWIN EU Package Suite & Metapackage

**Branch**: `008-modular-metapackage-suite` | **Date**: Thu Aug 20 2026 | **Spec**: [specs/008-modular-metapackage-suite/spec.md](spec.md)

**Input**: Feature specification from `specs/008-modular-metapackage-suite/spec.md`

## Summary

Restructure the HERMES repository into an R monorepo containing 3 focused, modular DARWIN EU domain packages plus 1 root umbrella metapackage:
1. **`CohortUtilisation` (`packages/CohortUtilisation`)**: Lightweight HCRU extraction (`addInpatients`, `addEmergencyCare`, `addOutpatientVisits`, `addVisits`, `addPrescriptions`, `addProcedures`, `computeHospitalizationCohorts`, `computeInfusionCohorts`, `summariseUtilization`, `tableUtilization`, `plotUtilization`).
2. **`CohortCosts` (`packages/CohortCosts`)**: Direct medical cost linkage, reporting, and regional/national unit cost tariffs (`addCosts`, `summariseCosts`, `tableCosts`, `plotCosts`, tariff datasets).
3. **`CohortEconomics` (`packages/CohortEconomics`)**: Causal PS adjustment, health-state trajectory compilation, Markov microsimulations, and Cost-Effectiveness Analysis (`fit_ps`, `compile_trajectories`, `simulate_economics`, `run_cea`).
4. **`hermes` (Root Metapackage)**: Umbrella package at the repository root attaching all three packages via `library(hermes)` with tidyverse-style startup messages, accompanied by a unified `pkgdown` documentation website.

## Technical Context

**Language/Version**: R (>= 4.1.0)

**Monorepo Layout**:
- Root directory: `hermes` metapackage (`DESCRIPTION`, `NAMESPACE`, `R/zzz.R`, `_pkgdown.yml`, `vignettes/`)
- Sub-packages: `packages/CohortUtilisation`, `packages/CohortCosts`, `packages/CohortEconomics`

**Primary Dependencies by Package**:
- **`CohortUtilisation`**: `omopgenerics` (>= 0.3.0), `CDMConnector` (>= 1.4.0), `PatientProfiles` (>= 1.2.0), `CohortCharacteristics` (>= 0.3.0), `CohortConstructor` (>= 0.2.0), `visOmopResults`, `dbplyr`, `dplyr`, `rlang`, `glue`, `cli`
- **`CohortCosts`**: `omopgenerics`, `CDMConnector`, `PatientProfiles`, `visOmopResults`, `dbplyr`, `dplyr`, `rlang`, `glue`, `cli`
- **`CohortEconomics`**: `CohortUtilisation`, `CohortCosts`, `BCEA`, `hesim`, `heemod`, `CohortMethod`, `Cyclops`, `Cohort2Trajectory`, `TrajectoryMarkovAnalysis`
- **`hermes` (Metapackage)**: `CohortUtilisation`, `CohortCosts`, `CohortEconomics`, `cli`, `rlang`

**Testing**: `testthat` (3.0.0+) with independent test suites in each sub-package.

**Conventions**: Base R pipe `|>`, `<-` assignment, `lowerCamelCase` functions and arguments, `snake_case` database table columns, PascalCase package names (`CohortUtilisation`, `CohortCosts`, `CohortEconomics`).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] **I. Zero Wheel-Reinvention**: Leverages standard R monorepo architecture and tidyverse metapackage pattern without bespoke build tools.
- [x] **II. Standardized OMOP CDM Integration**: All sub-packages directly interact with OMOP CDM tables via `omopgenerics` and `CDMConnector`.
- [x] **III. Pipeable S3 & DARWIN EU Architecture**: Enforces `lowerCamelCase` functions, `snake_case` columns, and returns standard `cohort_table` and `summarised_result` objects.
- [x] **IV. Test-First & Coverage**: Each sub-package possesses its own independent `testthat` suite verifying isolated execution.
- [x] **V. 6-Stage Pipeline Alignment**: Cleanly maps Stage 1-2 to `CohortUtilisation` & `CohortCosts`, and Stage 3-6 to `CohortEconomics`.

## Project Structure

### Monorepo Directory Tree

```text
HERMES-modular/
├── DESCRIPTION                     # Root metapackage: hermes
├── NAMESPACE
├── R/
│   ├── zzz.R                       # Metapackage attach hook & startup banner
│   └── reexports.R                 # Optional convenient top-level re-exports
├── _pkgdown.yml                    # Unified cross-package documentation catalog
├── vignettes/                      # End-to-end HEOR vignettes
│
└── packages/
    ├── CohortUtilisation/          # HCRU Domain Package
    │   ├── DESCRIPTION
    │   ├── NAMESPACE
    │   ├── R/
    │   │   ├── addInpatients.R
    │   │   ├── addEmergencyCare.R
    │   │   ├── addOutpatientVisits.R
    │   │   ├── addVisits.R
    │   │   ├── addPrescriptions.R
    │   │   ├── addProcedures.R
    │   │   ├── computeHospitalizationCohorts.R
    │   │   ├── computeInfusionCohorts.R
    │   │   ├── summariseUtilization.R
    │   │   ├── tableUtilization.R
    │   │   ├── plotUtilization.R
    │   │   └── utilities.R
    │   └── tests/testthat/
    │
    ├── CohortCosts/                # Direct Costs & Tariffs Domain Package
    │   ├── DESCRIPTION
    │   ├── NAMESPACE
    │   ├── R/
    │   │   ├── addCosts.R
    │   │   ├── summariseCosts.R
    │   │   ├── tableCosts.R
    │   │   └── plotCosts.R
    │   ├── data/                   # Spanish / EU cost tables & indices
    │   └── tests/testthat/
    │
    └── CohortEconomics/            # PS, Trajectories, Markov & CEA Domain Package
        ├── DESCRIPTION
        ├── NAMESPACE
        ├── R/
        │   ├── init.R
        │   ├── baseline.R
        │   ├── ps.R
        │   ├── trajectories.R
        │   ├── simulation.R
        │   ├── cea.R
        │   ├── mockHERMES.R
        │   └── s3_classes.R
        └── tests/testthat/
```

## Complexity Tracking

*No constitutional violations. Monorepo pattern enables both root one-line installation and granular modular installations.*
