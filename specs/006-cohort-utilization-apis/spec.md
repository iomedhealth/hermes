# Feature Specification: DARWIN EU-Aligned Cohort Utilization & Cost APIs

**Feature Branch**: `006-cohort-utilization-apis`

**Created**: Wed Aug 19 2026

**Status**: Draft

**Input**: User requirement: "Create an API specification following OHDSI/DARWIN EU package conventions (CohortConstructor, PatientProfiles, CohortCharacteristics) to enhance study cohorts with healthcare resource utilization (HCRU) metrics and direct medical costs across Inpatient, Outpatient, Pharmacy, Diagnostics/Procedures, and Financial domains using intuitive, camelCase functions without the awkward '*Hcru' suffix."

## Clarifications

### Session 2026-08-19
- Q: How should the new HERMES functions integrate with `CohortConstructor`, `PatientProfiles`, and `CohortCharacteristics` under the hood? → A: Option B (Hybrid Architecture: Directly delegate standard table/concept intersects, episode collapsing, and summarisation to `PatientProfiles`, `CohortConstructor`, and `CohortCharacteristics`, while implementing compound provider joins and cost linkages using their exact internal `dbplyr` conventions).

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - In-Database Cohort Enrichment across Clinical Utilization & Cost Domains (Priority: P1) 🎯 MVP

As an HEOR researcher, I need to enrich existing study cohort tables with granular healthcare resource utilization (hospital admissions, outpatient encounters, prescription fills, diagnostic procedures) and direct medical costs across configurable baseline and follow-up temporal windows, so that patient-level observational data can be directly analyzed or piped into downstream propensity score and trajectory models without dropping zero-utilization subjects.

**Why this priority**: Cohort enrichment with windowed utilization metrics is the central building block for all downstream descriptive tables, comparative effectiveness analyses, and health state cost extraction in health economics studies.

**Independent Test**: Provide an OMOP CDM with study cohorts and clinical records. Pipe a cohort table through `addHospitalizations()`, `addOutpatientVisits()`, `addPrescriptions()`, `addProcedures()`, and `addCosts()` over baseline `[-365, -1]` and follow-up `[0, 365]` windows. Verify that the output cohort contains the expected columns, preserves all cohort members (with 0s for non-utilizers), and produces accurate patient-level metrics.

**Acceptance Scenarios**:

1. **Given** an active study cohort, **When** `addHospitalizations()` is called with `window = list(baseline = c(-365, -1), followup = c(0, 365))`, **Then** the resulting cohort includes `inpatient_admissions_baseline`, `inpatient_los_days_baseline`, `inpatient_admissions_followup`, `inpatient_los_days_followup`, and `icu_admissions_followup` columns.
2. **Given** an active study cohort, **When** `addOutpatientVisits()` is executed with specialty stratification enabled, **Then** the cohort is enriched with `gp_visits_*`, `specialist_visits_*`, and `emergency_visits_*` count columns for each defined window.
3. **Given** an active study cohort, **When** `addPrescriptions()` is executed with `daysSupply = TRUE` and `pdc = TRUE`, **Then** prescription fill counts, cumulative days supply, and Proportion of Days Covered (0.0 to 1.0) are calculated per patient and window.
4. **Given** an active study cohort, **When** `addProcedures()` is executed with diagnostic and lab options enabled, **Then** distinct count columns for lab measurements, imaging scans, and surgical/medical procedures are appended per window.
5. **Given** an active study cohort, **When** `addCosts()` is executed, **Then** direct medical expenditures linked from the OMOP `cost` table are summarized per patient and window, stratified by clinical domain (`cost_inpatient_*`, `cost_outpatient_*`, `cost_drug_*`, `cost_procedure_*`, `cost_total_*`).

---

### User Story 2 - Discrete Care Episode Cohort Generation (Priority: P2)

As a clinical epidemiologist, I need to construct discrete care episode cohorts (such as collapsed inpatient stays with 30-day readmissions and infusion administration episodes) as standalone OMOP cohort tables in the database write schema, so that time-to-event and episode-level survival analyses can be performed.

**Why this priority**: Episode-level modeling requires contiguous and overlapping events to be collapsed into bounded episodes with explicit entry dates, exit dates, and washout periods.

**Independent Test**: Execute `computeHospitalizationCohorts()` and `computeInfusionCohorts()` on a database with known overlapping visits and drug exposures; verify that the resulting tables conform to OMOP cohort table standards with correct start/end intervals and cohort definition IDs.

**Acceptance Scenarios**:

1. **Given** raw inpatient records with overlapping or back-to-back stay dates, **When** `computeHospitalizationCohorts()` is run, **Then** contiguous stays are consolidated into discrete hospitalization episodes, and subsequent admissions within the specified washout window are flagged under readmission cohort IDs.
2. **Given** drug exposure records with parenteral/intravenous route concepts, **When** `computeInfusionCohorts()` is executed, **Then** a registered cohort table of distinct infusion episodes is generated.

---

### User Story 3 - Standardized Analytical Summarisation & Reporting (Priority: P3)

As a health economist, I need to aggregate enriched cohort utilization and cost metrics into standardized summary tables stratified by cohort definition, age groups, or sex, and render publication-ready tables and plots, so that study results can be easily reviewed and included in HEOR reports and manuscripts.

**Why this priority**: Standardized summary objects enable seamless integration with the DARWIN EU reporting ecosystem (`visOmopResults`) and streamline decision-analytic model parameterization.

**Independent Test**: Execute `summariseUtilization()` and `summariseCosts()` on an enriched cohort; verify that the output adheres to the `omopgenerics::summarised_result` standard and formats into publication-ready GT or flextables via `tableUtilization()`.

**Acceptance Scenarios**:

1. **Given** an enriched cohort table, **When** `summariseUtilization()` is called with strata and estimate vectors (mean, SD, median, IQR, min, max), **Then** a valid `summarised_result` object is returned containing all utilization variables.
2. **Given** an enriched cohort table with cost columns, **When** `summariseCosts()` is called, **Then** cost distributions are summarized across defined strata.
3. **Given** a `summarised_result` object from utilization or cost summarisation, **When** `tableUtilization()` is called, **Then** a formatted visual table is produced with customizable headers and layout.

---

## Edge Cases

- **Zero-Utilization Patients**: Patients in the study cohort who have no recorded visits, prescriptions, procedures, or costs in the observation window MUST remain in the cohort with counts and durations populated as `0` (or `NA` where mathematically appropriate, e.g. PDC when window length is 0), never dropped from the dataset.
- **Missing or Unlinked Provider Specialty**: When an outpatient visit lacks a linked provider or specialty concept ID, the encounter MUST be counted under general/unclassified outpatient visits rather than discarded.
- **Negative or Missing Visit Durations**: If a visit record has a missing end date or an end date preceding the start date (same-day discharge or data anomaly), duration calculations MUST enforce a lower bound of 0 days (or 1 day for same-day stay conventions) and prevent negative values.
- **Missing Cost Records**: If the OMOP `cost` table contains no records for a patient or domain, financial enrichers MUST populate cost fields as `0.0` without raising unhandled errors.
- **Arbitrary Temporal Windows**: Functions MUST support arbitrary relative window lists (e.g. `list(c(-180, -1), c(0, 30), c(31, 365))`) and name output columns predictably using user-defined naming templates (`nameStyle`).

---

## Requirements *(mandatory)*

### Functional Requirements

#### Layer 1: Episode Cohort Constructors (`CohortConstructor` Style)
- **FR-001**: System MUST provide `computeHospitalizationCohorts(cdm, name, visitConceptIds, icuConceptIds, readmissionWindow)` to construct standalone inpatient and readmission cohort tables in the database write schema.
- **FR-002**: System MUST provide `computeInfusionCohorts(cdm, name, conceptSet, routeConceptIds, collapseGap)` to extract infusion and parenteral drug administration episodes into a registered cohort table.

#### Layer 2: Cohort Enrichers (`PatientProfiles` Style)
- **FR-003**: System MUST provide `addHospitalizations(x, indexDate, censorDate, window, visitConceptIds, icuConceptIds, readmissions, nameStyle, name)` to enrich cohort tables with inpatient admissions, cumulative length of stay, ICU admissions, ICU duration, and 30d/90d readmission counts.
- **FR-004**: System MUST provide `addOutpatientVisits(x, indexDate, censorDate, window, stratifySpecialty, gpSpecialtyConceptIds, nameStyle, name)` to enrich cohort tables with General Practitioner (GP), Specialist, Emergency Room (ED), and other outpatient encounter counts.
- **FR-005**: System MUST provide `addPrescriptions(x, indexDate, censorDate, window, conceptSet, infusionRouteConceptIds, daysSupply, pdc, nameStyle, name)` to enrich cohort tables with prescription fill counts, cumulative days supply, PDC adherence scores, and infusion episode counts.
- **FR-006**: System MUST provide `addProcedures(x, indexDate, censorDate, window, labConceptSet, imagingConceptSet, procedureConceptSet, nameStyle, name)` to enrich cohort tables with diagnostic laboratory test counts, imaging/CT scan counts, and surgical/medical procedure counts.
- **FR-007**: System MUST provide `addCosts(x, indexDate, censorDate, window, costField, domains, nameStyle, name)` to link OMOP `cost` records polymorphic to clinical events and append domain-specific and total direct medical costs.
- **FR-008**: All cohort enricher functions MUST accept an existing cohort table `x`, operate primarily inside the database using `dbplyr` queries, and return the modified cohort table with added columns.
- **FR-009**: All cohort enricher functions MUST support customizable column naming via a `nameStyle` parameter with glue-style placeholder tokens (e.g., `{metric}`, `{domain}`, `{window_name}`, `{setting}`).
- **FR-010**: All cohort enricher functions MUST accept multi-window specifications as a named or unnamed list of 2-element integer vectors (e.g. `list(baseline = c(-365, -1), followup = c(0, 365))`).

#### Layer 3: Analytics & Reporting (`CohortCharacteristics` Style)
- **FR-011**: System MUST provide `summariseUtilization(cohort, strata, estimates)` to compute summary statistics on all utilization metrics and return an `omopgenerics::summarised_result` object.
- **FR-012**: System MUST provide `summariseCosts(cohort, strata, costColumns, estimates)` to compute summary statistics on direct medical costs and return an `omopgenerics::summarised_result` object.
- **FR-013**: System MUST provide `tableUtilization(result, type, header)` and `tableCosts(result, type, header)` to render publication-ready formatted tables (GT, flextable, or tibble).
- **FR-014**: System MUST provide `plotUtilization(result, metric, plotType)` and `plotCosts(result, costColumn, plotType)` to produce visual distribution and trend plots.

#### General Conventions & Package Integration
- **FR-015**: All public R functions and function arguments MUST adhere to DARWIN EU `lowerCamelCase` naming conventions.
- **FR-016**: All database table column names generated in cohort tables MUST adhere to `snake_case` naming conventions.
- **FR-017**: Implementation MUST reuse `PatientProfiles` (`addTableIntersect*`, `addConceptIntersect*`, `addDemographics`), `CohortConstructor` (`conceptCohort`, `collapseCohorts`), and `CohortCharacteristics` / `visOmopResults` (`summariseCharacteristics`, `tableCharacteristics`, `visOmopTable`) wherever applicable, and follow their internal `dbplyr` validation and temporary table lifecycle patterns for custom joins.

---

### Key Entities

- **Study Cohort Table (`x`)**: An `omopgenerics::cohort_table` object containing `cohort_definition_id`, `subject_id`, `cohort_start_date`, and `cohort_end_date`.
- **Enriched Cohort Table**: A database table retaining all original cohort rows while appending domain-specific integer and numeric metric columns across defined observation windows.
- **Care Episode Cohort Table**: A standalone cohort table in the database write schema representing discrete, non-overlapping hospitalization or infusion episodes with cohort metadata.
- **Standardised Result Object**: An analytical summary tibble structured according to `omopgenerics::summarised_result` specifications (`cdm_name`, `group_name`, `group_level`, `strata_name`, `strata_level`, `variable_name`, `estimate_name`, `estimate_value`).

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of study cohort members are preserved in the enriched table across all domains without row loss or unintended row duplication.
- **SC-002**: All 12 core utilization and cost metrics (Admissions, ICU, LOS, Readmissions, GP Visits, Specialist Visits, ER Visits, Prescriptions, Infusions, Days Supply, Lab Tests, Imaging / CT, Procedures, Costs) can be extracted and appended via pipe-friendly verbs.
- **SC-003**: Inpatient stay collapsing and 30-day/90-day readmission flags correctly correlate adjacent discharge and admission dates with 0% misclassification.
- **SC-004**: Provider specialty stratification accurately classifies visits into GP, Specialist, and Emergency categories with graceful fallback for unmapped specialties.
- **SC-005**: Summarisation functions output valid `summarised_result` objects that pass `omopgenerics::validateResultArgument()` and seamlessly render via `visOmopResults`.
- **SC-006**: 100% of exported functions and function arguments adhere strictly to DARWIN EU `lowerCamelCase` conventions and pass package linting with `lintr::object_name_linter(styles = "camelCase")`.

---

## Assumptions

- The target database is an OMOP Common Data Model (v5.3 or v5.4) accessible via `CDMConnector` and `omopgenerics`.
- Clinical event tables (`visit_occurrence`, `drug_exposure`, `procedure_occurrence`, `measurement`, `provider`, `cost`) conform to standard OMOP vocabulary concept identifiers.
- Users have write permissions on the designated CDM write/scratch schema for temporary and permanent cohort table materialization.
