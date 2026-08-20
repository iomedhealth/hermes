# Package index

## Stage 1: Cohort Generation

Functions for defining, initializing, and building care episodes.

- [`init()`](init.md) : Initialize a HERMES study (Stage 1: Cohort
  Generation)
- [`compute_hospitalization_cohorts()`](compute_hospitalization_cohorts.md)
  [`computeHospitalizationCohorts()`](compute_hospitalization_cohorts.md)
  : Generate Hospitalization and Readmission Cohorts (Stage 1 & 2)
- [`computeInfusionCohorts()`](computeInfusionCohorts.md) : Create
  Infusion Administration Episode Cohorts

## Stage 2: Cohort Utilization & Cost Enrichers

In-database cohort enrichment verbs following PatientProfiles patterns.

- [`addHospitalizations()`](addHospitalizations.md) : Add Inpatient and
  ICU Hospitalization Metrics to a Cohort
- [`addOutpatientVisits()`](addOutpatientVisits.md) : Add Outpatient and
  Emergency Visits to a Cohort
- [`addPrescriptions()`](addPrescriptions.md) : Add Prescription and
  Medication Metrics to a Cohort
- [`addProcedures()`](addProcedures.md) : Add Diagnostic Measurements
  and Procedure Occurrences to a Cohort
- [`addCosts()`](addCosts.md) : Add Direct Medical Costs to a Cohort

## Stage 2: Summarisation & Reporting

Standardised result summaries and publication-ready table & plot
formatters.

- [`summariseUtilization()`](summariseUtilization.md) : Summarise
  Healthcare Resource Utilization for a Cohort
- [`summariseCosts()`](summariseCosts.md) : Summarise Direct Medical
  Costs for a Cohort
- [`tableUtilization()`](tableUtilization.md) : Format Utilization
  Results as Visual Tables
- [`tableCosts()`](tableCosts.md) : Format Cost Results as Visual Tables
- [`plotUtilization()`](plotUtilization.md) : Plot Healthcare Resource
  Utilization
- [`plotCosts()`](plotCosts.md) : Plot Direct Medical Costs
- [`summarise_baseline()`](summarise_baseline.md) : Summarise baseline
  demographics and comorbidities (Stage 2: Baseline)
- [`extract_hcru()`](extract_hcru.md) [`extractHcru()`](extract_hcru.md)
  : Extract Healthcare Resource Utilization (HCRU) from OMOP CDM (Stage
  2: HCRU)

## Stage 3: Propensity Score

Causal adjustment and matching.

- [`fit_ps()`](fit_ps.md) : Fit Propensity Score Model (Stage 3: Causal
  Adjustment)
- [`adjust_ps()`](adjust_ps.md) : Adjust Propensity Scores (Stage 3:
  Causal Adjustment)
- [`assess_balance()`](assess_balance.md) : Assess Covariate Balance
  (Stage 3: Causal Adjustment)

## Stage 4: Trajectories

State-cost extraction and transitions.

- [`compile_trajectories()`](compile_trajectories.md) : Compile State
  Trajectories and Costs (Stage 4: Trajectory Compilation)

## Stage 5 & 6: Simulation & CEA

Economic simulation and decision analysis.

- [`simulate_economics()`](simulate_economics.md) : Simulate Economic
  Outcomes (Stage 5: Economic Simulation)
- [`run_cea()`](run_cea.md) : Run Cost-Effectiveness Analysis (Stage 6:
  Decision Analysis)
- [`plot_ceac()`](plot_ceac.md) : Plot Cost-Effectiveness Acceptability
  Curve (CEAC)
- [`plot_plane()`](plot_plane.md) : Plot Cost-Effectiveness Plane
- [`table_summary()`](table_summary.md) : Summary Table

## Mock Data & Testing Utilities

Helpers for creating synthetic in-memory OMOP CDM test references.

- [`mockHERMES()`](mockHERMES.md) : Create a Mock OMOP CDM Reference for
  Testing and Demonstrations
