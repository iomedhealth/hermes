# Changelog

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
  - [`addInpatients()`](../reference/addInpatients.md) is now the
    primary DARWIN EU-standard function for inpatient and ICU cohort
    enrichment, replacing
    [`addHospitalizations()`](../reference/addInpatients.md).
  - [`addHospitalizations()`](../reference/addInpatients.md) and
    [`addInpatient()`](../reference/addInpatients.md) are preserved as
    fully functional backward-compatible exported aliases.
  - Added `stratifySpecialty = TRUE` and `specialties` parameter to
    compute specialty-specific inpatient admissions
    (`{specialty}_inpatient_admissions_*`).
- **Dedicated Emergency Care Enricher (`addEmergencyCare`)**:
  - Added [`addEmergencyCare()`](../reference/addEmergencyCare.md) (with
    aliases [`addEmergency()`](../reference/addEmergencyCare.md) and
    [`addEmergencyVisits()`](../reference/addEmergencyCare.md)).
  - Uses dual-criteria detection capturing emergency encounters via OMOP
    emergency visit concepts (`9203`, `262`, `581478`) **and** Emergency
    Medicine provider specialty concepts (`38004510`).
  - Supports granular specialty stratification
    (`{specialty}_emergency_visits_*`).
- **Composite Multi-Setting Enricher (`addVisits`)**:
  - Added [`addVisits()`](../reference/addVisits.md) to orchestrate
    Inpatient, Outpatient, and Emergency care enrichment in a single
    execution.
  - Supports selective setting filtering
    (`settings = c("inpatient", "outpatient", "emergency")`) and unified
    specialty mapping.

------------------------------------------------------------------------

## HERMES 0.2.0

### Initial Modular HCRU & CEA Release

- Layer 1: Care Episode Constructors
  ([`computeHospitalizationCohorts()`](../reference/compute_hospitalization_cohorts.md),
  [`computeInfusionCohorts()`](../reference/computeInfusionCohorts.md)).
- Layer 2: In-database cohort enrichers
  ([`addOutpatientVisits()`](../reference/addOutpatientVisits.md),
  [`addPrescriptions()`](../reference/addPrescriptions.md),
  [`addProcedures()`](../reference/addProcedures.md),
  [`addCosts()`](../reference/addCosts.md)).
- Layer 3: Analytical summarisation and reporting
  ([`summariseUtilization()`](../reference/summariseUtilization.md),
  [`summariseCosts()`](../reference/summariseCosts.md),
  [`tableUtilization()`](../reference/tableUtilization.md),
  [`tableCosts()`](../reference/tableCosts.md),
  [`plotUtilization()`](../reference/plotUtilization.md),
  [`plotCosts()`](../reference/plotCosts.md)).
- End-to-end 6-stage analytical pipeline support (Cohorts,
  Baseline/HCRU, PS Adjustment, Trajectories, Simulation, CEA).
