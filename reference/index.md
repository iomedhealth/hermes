# Package index

## Stage 1: Cohort Generation

Functions for defining, initializing, and building care episodes.

- [`init()`](https://rdrr.io/pkg/CohortEconomics/man/init.html) :
  Initialize a HERMES study (Stage 1: Cohort Generation) (from
  CohortEconomics)
- [`compute_hospitalization_cohorts()`](https://rdrr.io/pkg/CohortUtilisation/man/compute_hospitalization_cohorts.html)
  [`computeHospitalizationCohorts()`](https://rdrr.io/pkg/CohortUtilisation/man/compute_hospitalization_cohorts.html)
  : Generate Hospitalization and Readmission Cohorts (Stage 1 & 2) (from
  CohortUtilisation)
- [`computeInfusionCohorts()`](https://rdrr.io/pkg/CohortUtilisation/man/computeInfusionCohorts.html)
  : Create Infusion Administration Episode Cohorts (from
  CohortUtilisation)

## Stage 2: Cohort Utilization & Cost Enrichers

In-database cohort enrichment verbs following PatientProfiles patterns.

- [`addInpatients()`](https://rdrr.io/pkg/CohortUtilisation/man/addInpatients.html)
  [`addHospitalizations()`](https://rdrr.io/pkg/CohortUtilisation/man/addInpatients.html)
  [`addInpatient()`](https://rdrr.io/pkg/CohortUtilisation/man/addInpatients.html)
  [`addIcuStays()`](https://rdrr.io/pkg/CohortUtilisation/man/addInpatients.html)
  : Add Inpatient and ICU Hospitalization Metrics to a Cohort (from
  CohortUtilisation)
- [`addEmergencyCare()`](https://rdrr.io/pkg/CohortUtilisation/man/addEmergencyCare.html)
  [`addEmergency()`](https://rdrr.io/pkg/CohortUtilisation/man/addEmergencyCare.html)
  [`addEmergencyVisits()`](https://rdrr.io/pkg/CohortUtilisation/man/addEmergencyCare.html)
  : Add Emergency Care Utilization Metrics to a Cohort (from
  CohortUtilisation)
- [`addOutpatientVisits()`](https://rdrr.io/pkg/CohortUtilisation/man/addOutpatientVisits.html)
  : Add Outpatient and Emergency Visits to a Cohort (from
  CohortUtilisation)
- [`addVisits()`](https://rdrr.io/pkg/CohortUtilisation/man/addVisits.html)
  : Add Multi-Setting Visit Utilization Metrics to a Cohort (from
  CohortUtilisation)
- [`addPrescriptions()`](https://rdrr.io/pkg/CohortUtilisation/man/addPrescriptions.html)
  : Add Prescription and Medication Metrics to a Cohort (from
  CohortUtilisation)
- [`addProcedures()`](https://rdrr.io/pkg/CohortUtilisation/man/addProcedures.html)
  : Add Diagnostic Measurements and Procedure Occurrences to a Cohort
  (from CohortUtilisation)
- [`addCosts()`](https://rdrr.io/pkg/CohortCosts/man/addCosts.html) :
  Add Direct Medical Costs to a Cohort (from CohortCosts)

## Stage 2: Summarisation & Reporting

Standardised result summaries and publication-ready table & plot
formatters.

- [`summariseUtilization()`](https://rdrr.io/pkg/CohortUtilisation/man/summariseUtilization.html)
  : Summarise Healthcare Resource Utilization for a Cohort (from
  CohortUtilisation)
- [`summariseCosts()`](https://rdrr.io/pkg/CohortCosts/man/summariseCosts.html)
  : Summarise Direct Medical Costs for a Cohort (from CohortCosts)
- [`tableUtilization()`](https://rdrr.io/pkg/CohortUtilisation/man/tableUtilization.html)
  : Format Summarised Utilization as a Table (from CohortUtilisation)
- [`tableCosts()`](https://rdrr.io/pkg/CohortCosts/man/tableCosts.html)
  : Format Summarised Direct Costs as a Table (from CohortCosts)
- [`plotUtilization()`](https://rdrr.io/pkg/CohortUtilisation/man/plotUtilization.html)
  : Plot Summarised Healthcare Resource Utilization (from
  CohortUtilisation)
- [`plotCosts()`](https://rdrr.io/pkg/CohortCosts/man/plotCosts.html) :
  Plot Summarised Direct Medical Costs (from CohortCosts)
- [`summarise_baseline()`](https://rdrr.io/pkg/CohortEconomics/man/summarise_baseline.html)
  : Summarise baseline demographics and comorbidities (Stage 2:
  Baseline) (from CohortEconomics)
- [`extract_hcru()`](https://rdrr.io/pkg/CohortEconomics/man/extract_hcru.html)
  [`extractHcru()`](https://rdrr.io/pkg/CohortEconomics/man/extract_hcru.html)
  : Extract Healthcare Resource Utilization (HCRU) from OMOP CDM (Stage
  2: HCRU) (from CohortEconomics)

## Stage 3: Propensity Score

Causal adjustment and matching.

- [`fit_ps()`](https://rdrr.io/pkg/CohortEconomics/man/fit_ps.html) :
  Fit Propensity Score Model (Stage 3: Causal Adjustment) (from
  CohortEconomics)
- [`adjust_ps()`](https://rdrr.io/pkg/CohortEconomics/man/adjust_ps.html)
  : Adjust Propensity Scores (Stage 3: Causal Adjustment) (from
  CohortEconomics)
- [`assess_balance()`](https://rdrr.io/pkg/CohortEconomics/man/assess_balance.html)
  : Assess Covariate Balance (Stage 3: Causal Adjustment) (from
  CohortEconomics)

## Stage 4: Trajectories

State-cost extraction and transitions.

- [`compile_trajectories()`](https://rdrr.io/pkg/CohortEconomics/man/compile_trajectories.html)
  : Compile State Trajectories and Costs (Stage 4: Trajectory
  Compilation) (from CohortEconomics)

## Stage 5 & 6: Simulation & CEA

Economic simulation and decision analysis.

- [`simulate_economics()`](https://rdrr.io/pkg/CohortEconomics/man/simulate_economics.html)
  : Simulate Economic Outcomes (Stage 5: Economic Simulation) (from
  CohortEconomics)
- [`run_cea()`](https://rdrr.io/pkg/CohortEconomics/man/run_cea.html) :
  Run Cost-Effectiveness Analysis (Stage 6: Decision Analysis) (from
  CohortEconomics)
- [`plot_ceac()`](https://rdrr.io/pkg/CohortEconomics/man/plot_ceac.html)
  : Plot Cost-Effectiveness Acceptability Curve (CEAC) (from
  CohortEconomics)
- [`plot_plane()`](https://rdrr.io/pkg/CohortEconomics/man/plot_plane.html)
  : Plot Cost-Effectiveness Plane (from CohortEconomics)
- [`table_summary()`](https://rdrr.io/pkg/CohortEconomics/man/table_summary.html)
  : Summary Table (from CohortEconomics)

## Mock Data & Testing Utilities

Helpers for creating synthetic in-memory OMOP CDM test references.

- [`mockHERMES()`](https://iomedhealth.github.io/omopHeor/reference/mockHERMES.md)
  : Create a Mock OMOP CDM Reference for Testing and Demonstrations
