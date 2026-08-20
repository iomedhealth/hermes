# Monorepo Suite Contracts & Package Interfaces

This document specifies the exported functions, package assignments, and interface contracts across the 3 domain packages and the root metapackage.

---

## 1. `packages/CohortUtilisation`

### Exported Functions
- `addInpatients(x, indexDate, censorDate, window, visitConceptIds, icuConceptIds, icuSpecialtyConceptIds, stratifySpecialty, specialties, readmissions, nameStyle, name)`
- `addHospitalizations` (alias to `addInpatients`)
- `addInpatient` (alias to `addInpatients`)
- `addEmergencyCare(x, indexDate, censorDate, window, emergencyVisitConceptIds, emergencySpecialtyConceptIds, stratifySpecialty, specialties, nameStyle, name)`
- `addEmergency` (alias to `addEmergencyCare`)
- `addEmergencyVisits` (alias to `addEmergencyCare`)
- `addOutpatientVisits(x, indexDate, censorDate, window, stratifySpecialty, gpSpecialtyConceptIds, specialties, includeEmergency, nameStyle, name)`
- `addVisits(x, indexDate, censorDate, window, settings, stratifySpecialty, gpSpecialtyConceptIds, icuSpecialtyConceptIds, emergencySpecialtyConceptIds, specialties, ...)`
- `addPrescriptions(x, indexDate, censorDate, window, conceptSet, infusionRouteConceptIds, daysSupply, pdc, nameStyle, name)`
- `addProcedures(x, indexDate, censorDate, window, labConceptSet, imagingConceptSet, procedureConceptSet, nameStyle, name)`
- `computeHospitalizationCohorts(cdm, name, visitConceptIds, icuConceptIds, readmissionWindow)`
- `computeInfusionCohorts(cdm, name, conceptSet, routeConceptIds, collapseGap)`
- `summariseUtilization(cohort, group, strata, estimates, variables)`
- `tableUtilization(result, type, header)`
- `plotUtilization(result, metric, plotType)`

---

## 2. `packages/CohortCosts`

### Exported Functions
- `addCosts(x, indexDate, censorDate, window, costField, domains, nameStyle, name)`
- `summariseCosts(cohort, group, strata, costColumns, estimates)`
- `tableCosts(result, type, header, estimateName)`
- `plotCosts(result, costColumn, plotType)`

### Package Data Assets
- `data/costs_spain.*`: Spanish national health unit cost tariffs.
- `data/ine_indices_sanidad.*`: National health inflation indices.

---

## 3. `packages/CohortEconomics`

### Exported Functions
- `init(cdm, targetCohort, comparatorCohort, outcomeCohort)`
- `summarise_baseline(study, strata, estimates)`
- `extract_hcru(study, baseline_window, followup_window, ...)`
- `extractHcru` (camelCase alias)
- `fit_ps(study, formula, ...)`
- `adjust_ps(study, method, ...)`
- `assess_balance(study, ...)`
- `compile_trajectories(study, cycle_length, ...)`
- `simulate_economics(study, time_horizon, discount_rate, n_samples, ...)`
- `run_cea(study, wtp_threshold, ...)`
- `plot_ceac(study)`
- `plot_plane(study)`
- `table_summary(study)`

---

## 4. Root Metapackage (`hermes`)

### Behavior
- Loading `library(hermes)` dynamically executes `requireNamespace()` and attaches `CohortUtilisation`, `CohortCosts`, and `CohortEconomics`.
- Re-exports core analytical verbs for seamless user scripts.
