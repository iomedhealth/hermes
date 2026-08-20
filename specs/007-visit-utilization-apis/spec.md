# Feature Specification: Inpatient, Emergency Care, and Unified Visit Utilization APIs

**Feature Branch**: `007-visit-utilization-apis`

**Created**: Thu Aug 20 2026

**Status**: Draft

**Input**: User requirement: "Change the name of the hospitalization function into addInpatients (Ad Impatience), also add another function called addVisits, and finally another one called addEmergencyCare. All the functions should be able to be stratified by specialty the same way addOutpatientVisits works. In the addVisits function it should take into account all three: inpatients, outpatients, and emergency care, and also be able to stratify by specialty. To find all emergency care acts, check both visits with emergency room concept IDs and visits by specialists whose provider specialty is emergency care."

## Clarifications

### Session 2026-08-20
- Q: Should `add_visits` snake_case alias be provided? → A: No, omit `add_visits` alias and adhere strictly to DARWIN EU `lowerCamelCase` naming (`addVisits`).
- Q: Should code examples and R variable names also use camelCase? → A: Yes, all code examples, object names, and documentation keys must strictly adhere to `lowerCamelCase` (e.g., `cohortInp`, `cohortEr`, `cohortAllVisits`, `summaryRes`, `pediatricEmergency`, `traumaSurgery`).

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Inpatient Care Cohort Enrichment with Specialty Stratification (Priority: P1) 🎯 MVP

As an HEOR researcher, I need to enrich study cohorts with inpatient care metrics using `addInpatients()` (with `addHospitalizations()` maintained as a backward-compatible alias), including admissions, length of stay, ICU utilization, 30-day/90-day readmissions, and optional provider specialty stratification, so that inpatient resource utilization can be accurately characterized across observational study windows without dropping non-hospitalized patients.

**Why this priority**: Inpatient care represents the largest financial component in health economics studies and requires clear, standardized terminology (`addInpatients`) alongside granular specialty breakdown.

**Independent Test**: Execute `addInpatients()` on a study cohort in an OMOP database across baseline and follow-up windows with specific clinical specialties provided (e.g., Cardiology, Oncology). Verify that the cohort retains 100% of subjects with 0-filled counts for non-admitted individuals and correctly appends admissions, LOS, ICU stays, readmissions, and specialty-stratified inpatient admission counts.

**Acceptance Scenarios**:

1. **Given** an active study cohort, **When** `addInpatients()` is invoked with `window = list(baseline = c(-365, -1), followup = c(0, 365))`, **Then** the cohort table is returned with `inpatient_admissions_*`, `inpatient_los_days_*`, `icu_admissions_*`, and `icu_los_days_*` columns appended for each window.
2. **Given** existing code calling `addHospitalizations()` or `addInpatient()`, **When** invoked with standard arguments, **Then** it behaves identically to `addInpatients()`, returning the enriched cohort without deprecation errors.
3. **Given** a named list of clinical specialties (e.g., `specialties = list(cardiology = 38004453L, oncology = 38004507L)`), **When** `addInpatients()` is called with `stratifySpecialty = TRUE`, **Then** granular columns such as `cardiology_inpatient_admissions_*` and `oncology_inpatient_admissions_*` are appended and 0-filled.

---

### User Story 2 - Comprehensive Emergency Care Identification & Enrichment (Priority: P1) 🎯 MVP

As an epidemiologist, I need to extract emergency care utilization via `addEmergencyCare()` by capturing **both** encounters with emergency room visit concept IDs and encounters delivered by emergency medicine specialist providers, with optional specialty stratification, so that emergency resource utilization is comprehensively captured even when setting codes or provider specialties vary across source datasets.

**Why this priority**: Emergency care is often recorded heterogeneously in electronic health records—sometimes via encounter visit concept IDs (e.g., Emergency Room Visit, ER and Inpatient Visit) and other times via provider specialty taxonomy (Emergency Medicine). Relying on visit concept IDs alone misses significant emergency care delivered in acute care environments.

**Independent Test**: Run `addEmergencyCare()` on a cohort where some emergency visits are designated by standard emergency visit concept IDs and others are designated by regular outpatient/inpatient visit concepts but attended by providers with emergency specialty codes. Verify that both types of encounters are accurately counted under `emergency_visits_*`.

**Acceptance Scenarios**:

1. **Given** an active study cohort, **When** `addEmergencyCare()` is executed with default parameters, **Then** encounters matching `emergencyVisitConceptIds` (e.g., 9203, 262, 581478) **OR** providers matching `emergencySpecialtyConceptIds` (e.g., 38004510) are aggregated into `emergency_visits_*` columns per window.
2. **Given** an alias invocation using `addEmergency()` or `addEmergencyVisits()`, **Then** it delegates directly to `addEmergencyCare()`.
3. **Given** a named list of granular provider specialties passed via `specialties`, **When** `addEmergencyCare()` is run, **Then** specialty-stratified emergency counts (`{s_name}_emergency_visits_*`) are generated for each defined window.

---

### User Story 3 - Unified Multi-Setting Visit Utilization Enrichment (Priority: P2)

As an HEOR analyst, I need a composite `addVisits()` function that enriches study cohorts across all three primary care settings—Inpatient, Outpatient, and Emergency care—in a single streamlined pipeline with unified specialty stratification, so that full care utilization profiles can be constructed with minimal boilerplate.

**Why this priority**: Clinical and economic studies frequently require full-spectrum resource utilization tables. Providing a unified verb simplifies analytical scripts, reduces intermediate database round-trips, and standardizes column naming across care settings.

**Independent Test**: Call `addVisits(settings = c("inpatient", "outpatient", "emergency"), stratifySpecialty = TRUE, specialties = list(...))` on a study cohort; verify that the resulting table contains comprehensive metric columns across all requested settings and specialties for all defined temporal windows.

**Acceptance Scenarios**:

1. **Given** a study cohort, **When** `addVisits()` is executed with default settings (`settings = c("inpatient", "outpatient", "emergency")`), **Then** columns for inpatient admissions, ICU stays, GP visits, specialist visits, other outpatient visits, and emergency visits are populated across all windows.
2. **Given** a subset of settings specified (e.g., `settings = c("outpatient", "emergency")`), **When** `addVisits()` is run, **Then** only metrics corresponding to the selected settings are appended.
3. **Given** `specialties` provided to `addVisits()`, **When** executed, **Then** granular specialty columns are populated for each active setting.

---

## Edge Cases

- **Dual-Tagged Encounters (ER and Inpatient)**: Stays that carry emergency room visit concepts (e.g., concept ID 262 - Emergency Room and Inpatient Visit) or ICU stays must be appropriately counted in both emergency care metrics (as acute care acts) and inpatient admissions/LOS when both functions or `addVisits()` are evaluated.
- **Provider Specialty vs. Visit Concept Discrepancies**: If a visit has an outpatient visit concept (e.g. 9202) but the provider is an emergency specialist (specialty concept 38004510), `addEmergencyCare()` MUST count this as an emergency care act, fulfilling the requirement for comprehensive identification.
- **Missing Provider or Specialty IDs**: When visits have missing `provider_id` or `specialty_concept_id` (`NA` or 0), they must fall back to general/unclassified counts within their respective visit domains rather than causing query failures or dropped rows.
- **Zero-Utilization Retention**: Patients in the cohort with zero utilization across all three settings must be preserved in the cohort table with integer counts populated as `0L` and numeric durations populated as `0.0`.
- **Customizable Observation Windows**: Functions must support arbitrary window definitions (e.g., `list(baseline = c(-365, -1), acute = c(0, 30), post_acute = c(31, 365))`) and name output columns consistently using specified templates (`nameStyle`).

---

## Requirements *(mandatory)*

### Functional Requirements

#### 1. Inpatient Care (`addInpatients`)
- **FR-001**: System MUST provide `addInpatients(x, indexDate, censorDate, window, visitConceptIds, icuConceptIds, icuSpecialtyConceptIds, stratifySpecialty, specialties, readmissions, nameStyle, name)` to enrich cohort tables with inpatient metrics.
- **FR-002**: `addInpatients` MUST support `stratifySpecialty` and `specialties` (a named list of OMOP specialty concept IDs) to count inpatient admissions attended by designated medical specialists (`{s_name}_inpatient_admissions_{window}`).
- **FR-003**: System MUST provide `addHospitalizations` and `addInpatient` as backward-compatible aliases for `addInpatients`.

#### 2. Emergency Care (`addEmergencyCare`)
- **FR-004**: System MUST provide `addEmergencyCare(x, indexDate, censorDate, window, emergencyVisitConceptIds, emergencySpecialtyConceptIds, stratifySpecialty, specialties, nameStyle, name)` to enrich cohort tables with emergency care utilization.
- **FR-005**: `addEmergencyCare` MUST identify emergency care encounters by matching **either** `visit_concept_id %in% emergencyVisitConceptIds` **OR** `provider.specialty_concept_id %in% emergencySpecialtyConceptIds`.
- **FR-006**: Default `emergencyVisitConceptIds` MUST include standard OMOP emergency visit concepts (`c(9203L, 262L, 581478L)`), and default `emergencySpecialtyConceptIds` MUST include OMOP Emergency Medicine concepts (`c(38004510L)`).
- **FR-007**: `addEmergencyCare` MUST support granular specialty stratification via `specialties` parameter, generating `{s_name}_emergency_visits_{window}`.
- **FR-008**: System MUST provide `addEmergency` and `addEmergencyVisits` as aliases for `addEmergencyCare`.

#### 3. Composite Visit Utilization (`addVisits`)
- **FR-009**: System MUST provide `addVisits(x, indexDate, censorDate, window, settings, stratifySpecialty, gpSpecialtyConceptIds, icuSpecialtyConceptIds, emergencySpecialtyConceptIds, specialties, inpatientVisitConceptIds, outpatientVisitConceptIds, emergencyVisitConceptIds, icuConceptIds, readmissions, name)` to coordinate multi-setting visit enrichment in a single execution.
- **FR-010**: `addVisits` MUST support selecting one or more care settings via `settings = c("inpatient", "outpatient", "emergency")`.
- **FR-011**: `addVisits` MUST pass down `stratifySpecialty` and `specialties` configurations to all selected domains to ensure unified specialty stratification across Inpatient, Outpatient, and Emergency care.
- **FR-012**: System MUST provide `addVisits` following strict DARWIN EU `lowerCamelCase` conventions without snake_case aliases.

#### 4. Outpatient Care (`addOutpatientVisits`)
- **FR-013**: `addOutpatientVisits` MUST remain fully functional, supporting specialty stratification (`gpSpecialtyConceptIds`, `specialties`) and cleanly integrating with `addVisits`.

#### 5. Integration and Conventions
- **FR-014**: All public functions and parameters MUST adhere to DARWIN EU `lowerCamelCase` conventions.
- **FR-015**: All generated database column names MUST adhere to `snake_case` conventions.
- **FR-016**: All functions MUST accept an existing cohort table `x`, execute database-side queries via `dbplyr`, and return the updated cohort table registered with `omopgenerics::newCohortTable()`.

---

### Key Entities

- **Study Cohort Table (`x`)**: An `omopgenerics::cohort_table` object containing `cohort_definition_id`, `subject_id`, `cohort_start_date`, and `cohort_end_date`.
- **Inpatient Care Metrics**: Columns representing general admissions (`inpatient_admissions_*`), cumulative length of stay (`inpatient_los_days_*`), ICU admissions (`icu_admissions_*`), ICU duration (`icu_los_days_*`), and optional 30d/90d readmissions.
- **Emergency Care Metrics**: Columns representing acute emergency room and emergency specialist encounters (`emergency_visits_*`), plus optional specialty-specific emergency counts.
- **Outpatient Care Metrics**: Columns representing primary care encounters (`gp_visits_*`), specialist encounters (`specialist_visits_*`), other outpatient encounters (`other_outpatient_visits_*`), and granular specialty breakdowns.
- **Specialty Mapping Specification**: A named list of integer vectors mapping clinical domain names (e.g., `cardiology`, `oncology`, `emergency_medicine`) to OMOP provider `specialty_concept_id` values.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of subjects in the input cohort table are preserved with zero row dropping and zero row duplication.
- **SC-002**: Emergency care acts are completely identified across both encounter concept identifiers and provider specialty identifiers with 0% missed emergency specialist encounters.
- **SC-003**: `addInpatients`, `addEmergencyCare`, `addOutpatientVisits`, and `addVisits` all support consistent specialty stratification using the `specialties` named list parameter.
- **SC-004**: Full backward compatibility is maintained for `addHospitalizations()`, ensuring zero breaking changes for existing pipelines.
- **SC-005**: All exported functions and aliases pass 100% of unit tests and adhere strictly to DARWIN EU camelCase styling standards.

---

## Assumptions

- The underlying CDM adheres to OMOP CDM v5.3 or v5.4 standards with `visit_occurrence`, `provider`, and `person` tables.
- Provider specialty concept IDs are stored in `cdm$provider$specialty_concept_id`.
- The user has write permissions in the active CDM write schema for table materialization.
