# Feature Specification: Modular DARWIN EU Package Suite & Metapackage

**Feature Branch**: `008-modular-metapackage-suite`

**Created**: Thu Aug 20 2026

**Status**: Draft

**Input**: User requirement: "Split the library into 3 modular DARWIN EU domain packages: Healthcare Resource Utilization (`CohortUtilisation`), Direct Medical Costs (`CohortCosts`), and Health Economics / CEA (`CohortEconomics`), unified under a root metapackage (`hermes`) in a monorepo structure with shared documentation."

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Standalone Healthcare Resource Utilization (`CohortUtilisation`) (Priority: P1) 🎯 MVP

As an epidemiologist or real-world data analyst, I need a lightweight, standalone `CohortUtilisation` package that extracts inpatient stays, emergency care, outpatient visits, medication fills, and diagnostic procedures from OMOP CDM data without pulling in heavy economic simulation or Bayesian CEA dependencies, so that routine utilization studies can be performed quickly and with minimal system requirements.

**Why this priority**: HCRU extraction is the core operational prerequisite for descriptive observational studies and is often performed independently of decision-analytic CEA modeling.

**Independent Test**: Install `CohortUtilisation` as a standalone R package in an isolated environment without CEA libraries; execute all `add*` visit, prescription, and procedure enrichers on a study cohort and generate standardized summary tables. Verify that all functions run with 100% test coverage.

**Acceptance Scenarios**:

1. **Given** an OMOP CDM study cohort, **When** `CohortUtilisation` is loaded, **Then** functions `addInpatients()`, `addEmergencyCare()`, `addOutpatientVisits()`, `addVisits()`, `addPrescriptions()`, `addProcedures()`, `computeHospitalizationCohorts()`, `computeInfusionCohorts()`, and `summariseUtilization()` are available and execute without loading simulation packages.
2. **Given** an analytical script, **When** `CohortUtilisation` is installed via `subdir = "packages/CohortUtilisation"`, **Then** installation succeeds with only core OMOP dependencies (`omopgenerics`, `CDMConnector`, `PatientProfiles`, `CohortConstructor`, `CohortCharacteristics`, `visOmopResults`).

---

### User Story 2 - Standalone Medical Costs & Tariff Tracking (`CohortCosts`) (Priority: P1) 🎯 MVP

As an HEOR data specialist, I need a dedicated `CohortCosts` package that links polymorphic OMOP `COST` records to clinical events and integrates regional/national unit cost tariffs and inflation indexing, so that patient-level direct medical expenditures and health-state cost distributions can be analyzed independently.

**Why this priority**: Medical costing requires domain-specific cost linkage and external tariff integrations (e.g. Spanish and European health tariffs) that are distinct from both encounter counting and decision-analytic simulation.

**Independent Test**: Install `CohortCosts` independently; link OMOP `cost` table records to cohort events using `addCosts()`, summarize expenditures across clinical domains using `summariseCosts()`, and access embedded cost tariff datasets.

**Acceptance Scenarios**:

1. **Given** a study cohort and CDM `cost` table, **When** `CohortCosts` is loaded, **Then** `addCosts()`, `summariseCosts()`, `tableCosts()`, and `plotCosts()` are accessible.
2. **Given** a research script requiring official unit costs, **When** `CohortCosts` is used, **Then** embedded cost datasets (e.g., Spanish national health tariffs and healthcare price indices) are accessible as package data.

---

### User Story 3 - Standalone Health Economics, Trajectories & Decision Analysis (`CohortEconomics`) (Priority: P1) 🎯 MVP

As a health economist, I need a specialized `CohortEconomics` package containing propensity score matching, longitudinal health-state trajectory compilation, Markov microsimulations, and Cost-Effectiveness Analysis (CEA) decision post-processing, so that advanced economic modeling can be executed cleanly on pre-extracted utilization and cost data.

**Why this priority**: Decision-analytic modeling forms the final analytical layer of HEOR, combining longitudinal patient trajectories with decision post-processing (ICER, NMB, CEAC curves).

**Independent Test**: Load `CohortEconomics` and execute `fit_ps()`, `adjust_ps()`, `compile_trajectories()`, `simulate_economics()`, and `run_cea()` on an initialized study object; verify that Markov transition matrices and publication-ready CEA plane/CEAC plots are generated.

**Acceptance Scenarios**:

1. **Given** baseline and longitudinal study cohorts, **When** `CohortEconomics` is loaded, **Then** `fit_ps()`, `adjust_ps()`, `compile_trajectories()`, `simulate_economics()`, and `run_cea()` execute end-to-end.
2. **Given** a simulated economic model, **When** `plot_ceac()` and `plot_plane()` are called, **Then** ggplot2 visualization objects are returned.

---

### User Story 4 - Seamless Metapackage Experience (`hermes`) (Priority: P2)

As an R researcher, I need an umbrella metapackage `hermes` at the root of the repository that installs and attaches all three domain packages in a single command, so that I can access the full end-to-end analytical pipeline without having to install and load three separate libraries manually.

**Why this priority**: Metapackages provide the easiest user onboarding experience while preserving modular sub-package architecture under the hood.

**Independent Test**: Execute `library(hermes)`; verify that an informative startup banner is displayed, and all functions from `CohortUtilisation`, `CohortCosts`, and `CohortEconomics` become immediately available in the global environment.

**Acceptance Scenarios**:

1. **Given** a user running `remotes::install_github("iomedhealth/hermes")` without specifying `subdir`, **Then** the root metapackage and all 3 sub-packages are installed in one step.
2. **Given** a user running `library(hermes)`, **Then** `CohortUtilisation`, `CohortCosts`, and `CohortEconomics` are attached with an informative tidyverse-style summary banner.

---

### User Story 5 - Unified Shared Documentation Website (`pkgdown`) (Priority: P2)

As a researcher or developer, I need a single, unified documentation website that comprehensively covers all three domain modules in a structured, cross-referenced catalog, so that I can learn and reference the entire HEOR pipeline in one place.

**Why this priority**: A unified documentation site prevents fragmented learning across multiple separate documentation portals.

**Independent Test**: Build `pkgdown` site from repository root; verify that functions from `CohortUtilisation`, `CohortCosts`, `CohortEconomics`, and `hermes` are organized into clean domain sections and vignettes render without errors.

**Acceptance Scenarios**:

1. **Given** root `_pkgdown.yml`, **When** the documentation site is built, **Then** reference sections are categorized into HCRU, Costs, and Health Economics.
2. **Given** end-to-end vignettes, **When** viewed on the docs site, **Then** workflow articles demonstrate seamless interoperation across all 3 modules.

---

## Edge Cases

- **Root vs. Subdirectory Installation**: Users installing without `subdir` must get the full metapackage suite, while users specifying `subdir = "packages/CohortUtilisation"` must receive only the lightweight HCRU package without failure.
- **Cross-Package Class Compatibility**: S3 class structures (`hermes_study`, `hermes_hcru`, `hermes_sim`) and `summarised_result` outputs must remain 100% interoperable across the package boundaries.
- **Namespace Collisions**: Functions across the 3 packages must have distinct, unambiguous names adhering strictly to DARWIN EU `lowerCamelCase` conventions.
- **Independent CI Testing**: Each sub-package must be testable in isolation via `R CMD check` and `testthat` without requiring sibling package code beyond declared dependencies.

---

## Requirements *(mandatory)*

### Functional Requirements

#### 1. Repository & Monorepo Structure
- **FR-001**: The repository MUST maintain a modular monorepo layout with domain packages housed under `packages/CohortUtilisation`, `packages/CohortCosts`, and `packages/CohortEconomics`.
- **FR-002**: The root directory MUST house the `hermes` umbrella metapackage with a root `DESCRIPTION` declaring dependencies on the sub-packages.

#### 2. `CohortUtilisation` Package
- **FR-003**: `CohortUtilisation` MUST contain all healthcare resource utilization verbs (`addInpatients`, `addHospitalizations`, `addEmergencyCare`, `addOutpatientVisits`, `addVisits`, `addPrescriptions`, `addProcedures`, `computeHospitalizationCohorts`, `computeInfusionCohorts`, `summariseUtilization`, `tableUtilization`, `plotUtilization`).
- **FR-004**: `CohortUtilisation` MUST NOT depend on heavy CEA simulation engines (`hesim`, `heemod`, `BCEA`, `Cyclops`).

#### 3. `CohortCosts` Package
- **FR-005**: `CohortCosts` MUST contain all direct medical cost linkage and reporting verbs (`addCosts`, `summariseCosts`, `tableCosts`, `plotCosts`).
- **FR-006**: `CohortCosts` MUST house embedded unit cost tariff datasets, inflation indexing models, and external scraping assets.

#### 4. `CohortEconomics` Package
- **FR-007**: `CohortEconomics` MUST contain causal propensity score adjustment, longitudinal trajectories, Markov microsimulations, and CEA decision analysis (`init`, `baseline`, `fit_ps`, `adjust_ps`, `assess_balance`, `compile_trajectories`, `simulate_economics`, `run_cea`, `plot_ceac`, `plot_plane`, `table_summary`).
- **FR-008**: `CohortEconomics` MUST import `CohortUtilisation` and `CohortCosts` for seamless end-to-end pipeline execution.

#### 5. Metapackage & Loading Experience
- **FR-009**: The root `hermes` metapackage MUST attach `CohortUtilisation`, `CohortCosts`, and `CohortEconomics` when `library(hermes)` is called.
- **FR-010**: The metapackage MUST output an informative startup message detailing the attached package versions.

#### 6. Coding & Style Conventions
- **FR-011**: All public functions and parameters across all packages MUST adhere to DARWIN EU `lowerCamelCase` conventions.
- **FR-012**: All database table column names MUST adhere to `snake_case` conventions.

---

### Key Entities

- **`hermes` Metapackage**: Root package orchestrating installation and namespace attachment for the full suite.
- **`CohortUtilisation` Package**: Domain package for patient-level HCRU extraction, episode collapsing, and utilization metrics.
- **`CohortCosts` Package**: Domain package for direct medical expenditures, OMOP `COST` linkage, and tariff integration.
- **`CohortEconomics` Package**: Domain package for causal modeling, Markov simulations, PSA, and Cost-Effectiveness Analysis.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Running `remotes::install_github("iomedhealth/hermes")` successfully installs all 3 domain packages and the metapackage in a single command.
- **SC-002**: Running `remotes::install_github("iomedhealth/hermes", subdir = "packages/CohortUtilisation")` successfully installs `CohortUtilisation` in isolation with 0 CEA dependencies.
- **SC-003**: 100% of unit tests pass independently across all 3 sub-packages (`CohortUtilisation`, `CohortCosts`, `CohortEconomics`).
- **SC-004**: Running `library(hermes)` makes all public functions from all three domains available with zero namespace conflicts.
- **SC-005**: All package names adhere to DARWIN EU PascalCase standard (`CohortUtilisation`, `CohortCosts`, `CohortEconomics`) and public functions adhere to `lowerCamelCase`.

---

## Assumptions

- The development environment supports standard R monorepo subdirectory builds via `devtools`, `remotes`, and `pak`.
- GitHub Actions CI matrix builds are configured to check each package directory independently.
