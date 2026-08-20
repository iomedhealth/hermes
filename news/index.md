# Changelog

## HERMES 0.5.0

### Major Architecture & Modularization Update

- **Monorepo Architecture with 3 Standalone DARWIN EU Domain Packages**:
  - **`CohortUtilisation` (`packages/CohortUtilisation`)**: Lightweight,
    standalone package for Healthcare Resource Utilization (HCRU)
    extraction (`addInpatients`, `addEmergencyCare`,
    `addOutpatientVisits`, `addVisits`, `addPrescriptions`,
    `addProcedures`, `computeHospitalizationCohorts`,
    `computeInfusionCohorts`, `summariseUtilization`,
    `tableUtilization`, `plotUtilization`) with 0 heavy simulation
    dependencies.
  - **`CohortCosts` (`packages/CohortCosts`)**: Dedicated direct medical
    costs and health economics costing package (`addCosts`,
    `summariseCosts`, `tableCosts`, `plotCosts`, Spanish unit cost
    tariffs & health price indices).
  - **`CohortEconomics` (`packages/CohortEconomics`)**: Comprehensive
    health economics modeling package for causal propensity scores,
    longitudinal health-state trajectories, Markov microsimulations, and
    Cost-Effectiveness Analysis (CEA) (`init`, `fit_ps`,
    `compile_trajectories`, `simulate_economics`, `run_cea`).
- **`hermes` Umbrella Metapackage**:
  - Root `hermes` metapackage allows single-command installation
    (`pak::pkg_install("iomedhealth/hermes")`).
  - Dynamic `.onAttach()` hook displays a tidyverse-style startup banner
    and attaches all three domain namespaces.
  - Re-exports all analytical verbs for frictionless scripting.
  - Unified `_pkgdown.yml` documentation website catalog.

------------------------------------------------------------------------

## HERMES 0.4.0

### Bug Fixes & Improvements

- **Open-Ended & Infinite Window Normalization**:
  - `validateWindow()` now seamlessly normalizes `Inf`, `-Inf`, and `NA`
    boundaries (`c(0, Inf)`, `c(0, NA)`, `c(-Inf, 0)`, `c(-Inf, Inf)`).
  - Enforced 100% lowercase `snake_case` column suffixes (`0_to_inf`,
    `minf_to_0`, `minf_to_inf`), preventing SQL database case-folding
    mismatch errors during table registration with `CDMConnector` and
    `omopgenerics`.
  - Safe date arithmetic and censoring evaluation across all 7 domain
    enrichers (`addInpatients`, `addEmergencyCare`,
    `addOutpatientVisits`, `addPrescriptions`, `addProcedures`,
    `addCosts`, `addVisits`).
- **Interactive Reports**:
  - Updated `reports/duckdb_hcru_report.Rmd` and generated
    `reports/duckdb_hcru_report.html` validating real-world multi-window
    and infinite follow-up performance against DuckDB OMOP CDM database.

------------------------------------------------------------------------

## HERMES 0.3.0

### New Features & Enhancements

- **Renamed Inpatient Enricher (`addInpatients`)**:
  - [`addInpatients()`](https://rdrr.io/pkg/CohortUtilisation/man/addInpatients.html)
    is now the primary DARWIN EU-standard function for inpatient and ICU
    cohort enrichment, replacing
    [`addHospitalizations()`](https://rdrr.io/pkg/CohortUtilisation/man/addInpatients.html).
  - [`addHospitalizations()`](https://rdrr.io/pkg/CohortUtilisation/man/addInpatients.html)
    and
    [`addInpatient()`](https://rdrr.io/pkg/CohortUtilisation/man/addInpatients.html)
    are preserved as fully functional backward-compatible exported
    aliases.
  - Added `stratifySpecialty = TRUE` and `specialties` parameter to
    compute specialty-specific inpatient admissions
    (`{specialty}_inpatient_admissions_*`).
- **Dedicated Emergency Care Enricher (`addEmergencyCare`)**:
  - Added
    [`addEmergencyCare()`](https://rdrr.io/pkg/CohortUtilisation/man/addEmergencyCare.html)
    (with aliases
    [`addEmergency()`](https://rdrr.io/pkg/CohortUtilisation/man/addEmergencyCare.html)
    and
    [`addEmergencyVisits()`](https://rdrr.io/pkg/CohortUtilisation/man/addEmergencyCare.html)).
  - Uses dual-criteria detection capturing emergency encounters via OMOP
    emergency visit concepts (`9203`, `262`, `581478`) **and** Emergency
    Medicine provider specialty concepts (`38004510`).
  - Supports granular specialty stratification
    (`{specialty}_emergency_visits_*`).
- **Composite Multi-Setting Enricher (`addVisits`)**:
  - Added
    [`addVisits()`](https://rdrr.io/pkg/CohortUtilisation/man/addVisits.html)
    to orchestrate Inpatient, Outpatient, and Emergency care enrichment
    in a single execution.
  - Supports selective setting filtering
    (`settings = c("inpatient", "outpatient", "emergency")`) and unified
    specialty mapping.

------------------------------------------------------------------------

## HERMES 0.2.0

### Initial Modular HCRU & CEA Release

- Layer 1: Care Episode Constructors
  ([`computeHospitalizationCohorts()`](https://rdrr.io/pkg/CohortUtilisation/man/compute_hospitalization_cohorts.html),
  [`computeInfusionCohorts()`](https://rdrr.io/pkg/CohortUtilisation/man/computeInfusionCohorts.html)).
- Layer 2: In-database cohort enrichers
  ([`addOutpatientVisits()`](https://rdrr.io/pkg/CohortUtilisation/man/addOutpatientVisits.html),
  [`addPrescriptions()`](https://rdrr.io/pkg/CohortUtilisation/man/addPrescriptions.html),
  [`addProcedures()`](https://rdrr.io/pkg/CohortUtilisation/man/addProcedures.html),
  [`addCosts()`](https://rdrr.io/pkg/CohortCosts/man/addCosts.html)).
- Layer 3: Analytical summarisation and reporting
  ([`summariseUtilization()`](https://rdrr.io/pkg/CohortUtilisation/man/summariseUtilization.html),
  [`summariseCosts()`](https://rdrr.io/pkg/CohortCosts/man/summariseCosts.html),
  [`tableUtilization()`](https://rdrr.io/pkg/CohortUtilisation/man/tableUtilization.html),
  [`tableCosts()`](https://rdrr.io/pkg/CohortCosts/man/tableCosts.html),
  [`plotUtilization()`](https://rdrr.io/pkg/CohortUtilisation/man/plotUtilization.html),
  [`plotCosts()`](https://rdrr.io/pkg/CohortCosts/man/plotCosts.html)).
- End-to-end 6-stage analytical pipeline support (Cohorts,
  Baseline/HCRU, PS Adjustment, Trajectories, Simulation, CEA).
