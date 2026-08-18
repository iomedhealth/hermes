# Feature Specification: HCRU Domain Extraction and Financial Linkage

**Feature Branch**: `005-hcru-domain-extraction`

**Created**: Fri Aug 14 2026

**Status**: Draft

**Input**: User description: "The current implementation only queries the cost table without joining the patient cohorts, lacking temporal windowing, and omitting the core HEOR utilization domains. Requirements & Implementation Steps: 1. Cohort Joining & Temporal Windowing (target/comparator/outcome cohorts, baseline/follow-up windows). 2. Utilization Domain Extraction (Inpatient/ICU, Outpatient/Emergency with provider specialty, Pharmacotherapy, Diagnostics/Procedures, Post-Acute). 3. Financial Linkage (OMOP COST table by domain and event ID). 4. S3 class preservation (flat list with new_hermes_hcru)."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Cohort-Linked Temporal Utilization & Cost Extraction across Core Domains (Priority: P1)

As an HEOR researcher, I need healthcare resource utilization (HCRU) and direct medical costs to be extracted specifically for patients in my study cohorts across predefined baseline and follow-up temporal windows, so that comparative economic analyses reflect actual study participants and relevant observation periods.

**Why this priority**: Without cohort membership filtering and temporal alignment, cost and utilization metrics include non-study patients and unanchored historical events, corrupting health economic evaluations.

**Independent Test**: Execute utilization and cost extraction on a study object containing target and comparator cohorts within a standardized observational database; verify that all returned metrics belong exclusively to cohort members and fall strictly within the configured baseline and follow-up windows.

**Acceptance Scenarios**:

1. **Given** a study object with defined target and comparator patient cohorts, **When** resource utilization extraction is executed with baseline window `[-365, -1]` and follow-up window `[0, 365]`, **Then** clinical events from inpatient, outpatient, pharmacy, procedure, and post-acute domains are extracted only for cohort members during these respective windows.
2. **Given** extracted utilization events with linked financial records, **When** costs are summarized, **Then** patient-level financial metrics (`total_paid`, `total_charge`, or designated cost columns) are aggregated per patient and window without duplicate counting.

---

### User Story 2 - Stratified Outpatient, Provider Specialty, and Inpatient Metrics (Priority: P2)

As a health economist, I need granular stratification of inpatient stays (admissions, length of stay, readmissions) and outpatient care (general practitioner vs. medical specialist vs. emergency department) so that resource utilization can be accurately modeled by service setting.

**Why this priority**: Economic models require distinct cost and utilization parameters for primary care, specialist consultations, emergency visits, and inpatient hospitalizations to estimate budget impact and cost drivers.

**Independent Test**: Run extraction on a cohort with known outpatient and inpatient encounters involving varied provider specialties; verify that counts and lengths of stay are properly separated into general practice, specialist, emergency, and inpatient categories.

**Acceptance Scenarios**:

1. **Given** inpatient visits in the observation window, **When** inpatient utilization is extracted, **Then** the total number of admissions, cumulative length of stay (days), and readmission indicators are calculated per patient.
2. **Given** outpatient and emergency visits linked to provider information, **When** outpatient utilization is processed, **Then** visits are stratified into emergency department visits, general practice visits, and specialist visits based on provider specialty classification.

---

### User Story 3 - Comprehensive Pharmacotherapy, Diagnostics, and Post-Acute Care Extraction (Priority: P3)

As an outcomes researcher, I need patient-level summaries of prescription fills, medication days supply, diagnostic tests, surgical/medical procedures, and skilled nursing or hospice care, so that the full spectrum of direct medical utilization is captured for CEA.

**Why this priority**: Pharmacy, diagnostic testing, procedures, and post-acute care represent major cost drivers in chronic disease management and post-event recovery pathways.

**Independent Test**: Evaluate a study cohort with medication exposures, procedural events, laboratory measurements, and skilled nursing facility stays; verify that total fills, days supply, procedure counts, diagnostic measurement counts, and post-acute stays are correctly aggregated per patient.

**Acceptance Scenarios**:

1. **Given** drug exposure records in the cohort observation window, **When** pharmacotherapy extraction is performed, **Then** total prescription fill counts and cumulative days supply are summarized for each patient.
2. **Given** procedures, laboratory measurements, and post-acute stays in the observation window, **When** domain extraction is performed, **Then** procedure counts, measurement counts, and post-acute stays are summarized per patient and joined with domain-specific cost entries.

---

### Edge Cases

- What happens when a patient in the cohort has zero recorded events in one or more utilization domains during the temporal window? The system MUST retain the patient with zero-valued counts and zero costs rather than dropping them from the analysis.
- What happens when the underlying cost table does not contain records for a particular domain or event? The system MUST retain the utilization counts and populate cost fields as zero (or missing with graceful imputation/fallback flag) without failing the entire extraction pipeline.
- What happens when visit end date precedes or equals visit start date (e.g., same-day discharge)? The system MUST compute length of stay with a minimum duration of 0 (or 1 for same-day visit conventions) and avoid negative durations.
- What happens when provider records are missing or unlinked for outpatient visits? The system MUST categorize the visit under unclassified/general outpatient rather than discarding the visit encounter.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST extract subject identifiers and cohort index dates from target, comparator, and optional outcome cohort tables associated with the study.
- **FR-002**: System MUST restrict all clinical event queries across all utilization domains to patients present in the combined study cohorts via inner join semantics.
- **FR-003**: System MUST accept configurable baseline window (defaulting to `[-365, -1]` relative to index date) and follow-up window (defaulting to `[0, 365]` relative to index date) parameters.
- **FR-004**: System MUST filter clinical events in each domain to ensure event dates fall within the specified baseline or follow-up relative timeframes.
- **FR-005**: System MUST extract Inpatient Care & ICU utilization from visit records (matching inpatient and ICU visit concept identifiers) and compute total admissions and total length of stay per patient.
- **FR-006**: System MUST compute 30-day and 90-day hospital readmission indicators when inpatient visit domain options are enabled.
- **FR-007**: System MUST extract Outpatient & Emergency Care utilization from visit records (matching outpatient and emergency concept identifiers), join provider information, and stratify visit counts per patient across Emergency Department, General Practice, and Medical Specialist encounters.
- **FR-008**: System MUST extract Pharmacotherapy utilization from drug exposure records, computing total prescription fill counts and cumulative days supply per patient, with optional support for adherence/persistence metrics.
- **FR-009**: System MUST extract Diagnostics, Procedures, and Post-Acute Care utilization from procedure occurrence, measurement, and visit occurrence tables (identifying skilled nursing facility and hospice concepts), aggregating event counts per patient.
- **FR-010**: System MUST link extracted domain events to the cost table by matching the event primary identifier to `cost_event_id` and aligning the `cost_domain_id` to the corresponding clinical domain (`Visit`, `Drug`, `Procedure`).
- **FR-011**: System MUST aggregate financial measures (`total_paid`, `total_charge`, or user-specified cost fields) per patient across each utilization domain and temporal window.
- **FR-012**: System MUST return the enriched utilization and cost summaries appended to the study structure while maintaining a flat list layout and preserving the `hermes_hcru` class hierarchy.

### Key Entities

- **Study Cohort Population**: The unified set of subject identifiers, treatment indicators, and cohort start/index dates defining the target, comparator, and outcome populations under evaluation.
- **Temporal Windows**: Relative observation intervals (baseline and follow-up) centered on each patient's cohort start date used to segment utilization and costs.
- **Utilization Domains**: Standardized clinical service categories encompassing Inpatient/ICU Care, Outpatient/Emergency Care, Pharmacotherapy, Procedures & Diagnostics, and Post-Acute Care.
- **Domain Utilization Summary**: Patient-level aggregated counts, durations (LOS, days supply), and encounter stratifications per domain and temporal window.
- **Financial Cost Summary**: Patient-level direct medical expenditures (`total_paid`, `total_charge`) linked to clinical domain events and health states.
- **hermes_hcru Object**: The core analytical structure holding baseline summaries, patient-level domain utilization, and financial cost distributions.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of extracted utilization events and financial costs are verified to belong strictly to subjects in the active study cohorts and within the specified temporal windows.
- **SC-002**: Utilization summaries across all 5 core domains (inpatient, outpatient/specialty, pharmacy, diagnostics/procedures, post-acute) are generated per patient without excluding cohort members with zero utilization.
- **SC-003**: Inpatient length of stay, provider specialty stratification (GP vs. Specialist vs. ED), and pharmacy days supply are calculated with 0% dropped records during table joins.
- **SC-004**: Financial cost linkage correctly correlates event primary keys with cost table entries across all active domains without creating duplicate rows or altering the total patient cohort size.
- **SC-005**: Output object conforms to the `hermes_hcru` S3 specification, maintaining a flat list representation suitable for seamless progression into Stage 3 propensity score modeling and Stage 4 trajectory compilation.

## Assumptions

- Observational database follows OMOP CDM v5.3+ conventions with standard concept identifiers for visit types, provider specialties, drug exposures, procedures, and measurements.
- Financial cost information is recorded in the standard OMOP `cost` table linked via `cost_event_id` and `cost_domain_id`.
- The database connection and cohort tables are initialized via standard HERMES study workflows (`init()`).
