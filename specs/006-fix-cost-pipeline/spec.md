# Feature Specification: Spanish Ground-Source Healthcare Cost Pipeline Remediation

**Feature Branch**: `006-fix-cost-pipeline`

**Created**: Wed Aug 19 2026

**Status**: Draft

**Input**: User description: "1. Fix Parsing & Encoding: Detect encoding via chardet/cchardet (or fallback iso-8859-1 for DOGC/BOIB); Implement line buffering / bounding-box row grouping in extract_pdf_catalog to assemble multi-line descriptions; Add negative filtering for gazette headers/footers (PÁG, BOLETÍN, DECRETO, LEY, EJERCICIO, tax brackets). 2. Correct Code Standardization: Fix the 6-column vs 5-column precedence in HTML table parsing; Restrict ICD-10-PCS regex to valid PCS structure (alphanumeric with standard section/body codes, rejecting dictionary words and regional alphabetic codes); Prefix regional identifiers strictly when matching authentic regional procedure nomenclature (e.g. CMA001, V03PVC001, LQ02166). 3. Refine Clinical Settings & OMOP Mappings: If code_std starts with APR-GRD:, default setting to 'Inpatient' and unit_type to 'per_episode' (unless explicitly identified as CMA); Expand clinical keyword mappings for Diagnostics, Procedures, and Primary Care. 4. Fix Deflation Index Series: Ensure strict match on 'Nacional. Sanidad. Índice.' (ECOICOP 06); Support sub-indices for Hospital Services (06.3) and Outpatient/Medical Services (06.2). 5. Align Airflow Tasks: Pass deflators via XCom from Task 2 into Task 3; Correct file_format definitions in registries.yml. 6. Store INE Table 50913 series as canonical data artifacts (CSV, Parquet, JSON) and use them across extraction and HEOR simulation."

## Clarifications

### Session 2026-08-19
- Q: How should the official INE Healthcare CPI series (Table 50913) be persisted as dataset artifacts and consumed by downstream HEOR workflows? → A: Canonical Storage & Offline-First (Option A): Parse and export INE Table 50913 to `data/ine_indices_sanidad.csv`, `data/ine_indices_sanidad.parquet`, and `data/ine_indices_sanidad.json` (containing Subgroup 06 Sanidad, 06.2 Ambulatorio, and 06.3 Hospitalario), load from local file by default with API refresh fallback, and export in Airflow DAG.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Clean, Multi-Line Ground-Source Tariff Ingestion without Character Corruption (Priority: P1)

As an HEOR data engineer and health economist, I need all 22 official Spanish regional and national healthcare gazettes to be ingested with exact character encodings, intact multi-line service descriptions, and zero non-medical legal noise (such as page numbers, tax brackets, or decree preambles), so that baseline reference costs accurately reflect real-world clinical tariffs.

**Why this priority**: Tariff corruption, dropped accents, broken descriptions, and false positive legal text (e.g. 600,000 € tax brackets or 22,000 € page numbers) invalidate downstream health technology assessments and cost-effectiveness models.

**Independent Test**: Run the ingestion pipeline across all regional gazettes (including Latin-1 sources like DOGC and BOIB) and verify that descriptions preserve Spanish/Catalan diacritics, long multi-line procedure descriptions are unified into single records, and no legislative boilerplate or page numbers are extracted as tariffs.

**Acceptance Scenarios**:

1. **Given** gazettes in legacy ISO-8859-1 or UTF-8 formats (such as Balearic or Catalan official gazettes), **When** text extraction runs, **Then** all special characters and accented vowels (`á, é, í, ó, ú, ñ, ç, à, è, ò, ï, ü`) are preserved without question marks or character drops.
2. **Given** clinical tariff tables in PDF format where procedure descriptions span multiple consecutive lines, **When** table rows are parsed, **Then** wrapped lines are joined into a single coherent description rather than creating isolated fragment rows starting with conjunctions or prepositions.
3. **Given** official gazette pages containing running headers, footers, publication dates, decree titles, page numbers, and non-sanitary tax brackets, **When** extraction filtering is applied, **Then** all non-healthcare rows are discarded before cost catalog compilation.

---

### User Story 2 - Accurate Clinical Code Standardization & Multi-Column Layout Parsing (Priority: P1)

As an outcomes researcher, I need clinical procedures and casemix categories to be standardized strictly to their canonical coding systems (APR-GRD, ICD-9-CM, ICD-10-PCS, National Drug Code, or verified Regional Code) with zero false-positive code tagging, so that patient trajectories and OMOP CDM concepts link to authentic reference tariffs.

**Why this priority**: Misclassifying plain Spanish words or regional acronyms as international ICD-10-PCS codes or corrupting APR-GRD severities with relative weights breaks semantic interoperability with observational databases.

**Independent Test**: Validate the extracted catalog against reference clinical terminology grammars; confirm that 100% of APR-GRD entries follow standardized `APR-GRD:<code[-severity]>` syntax, ICD-10-PCS codes strictly follow authentic 7-character procedural syntax, and regional identifiers represent specific medical acts rather than gazette section headings.

**Acceptance Scenarios**:

1. **Given** multi-column HTML tariff tables with 6 columns (e.g., Balearic tables with `[GRD, Severity, Weight, Description, Price, SAP]`), **When** the table parser evaluates rows, **Then** the 6-column format takes precedence over generic 5-column formats, correctly extracting the APR-GRD number, severity, SAP code, and tariff without decimal weight cross-contamination.
2. **Given** service entries with 7-letter words or regional abbreviations (e.g., `DRENAJE`, `ESCUELA`, `VENDAJE`, `PRUEBAS`, `PD00002`), **When** code standardization runs, **Then** standard dictionary words and regional test codes are NOT tagged as `ICD-10-PCS`.
3. **Given** regional tariff catalogs containing section identifiers (e.g., `B.1`, `B.2`, `DOG`) alongside authentic procedure codes (e.g., `CMA001`, `V03PVC001`, `LQ02166`), **When** standardization executes, **Then** only true procedure codes are assigned `REGIONAL:` prefixes while section headings are ignored.

---

### User Story 3 - Context-Aware Clinical Setting & OMOP Domain Assignment (Priority: P2)

As a health economist, I need each cost item to be assigned its true clinical setting (`Inpatient`, `ICU`, `Outpatient`, `Emergency`, `Diagnostics`, `Procedures`, `Primary Care`) and OMOP domain (`Visit`, `Procedure`, `Measurement`, `Drug`), so that economic simulations can distinguish between major hospitalizations, outpatient visits, and diagnostic testing.

**Why this priority**: Defaulting 85% of tariffs to generic outpatient visits causes major surgical admissions (e.g., craniotomy, organ transplantation) to be analyzed as simple consultations, distorting unit cost weights in HEOR models.

**Independent Test**: Group the final catalog by clinical setting and OMOP domain; verify that APR-GRD casemix categories default to Inpatient/per_episode, surgical and diagnostic procedures map to Procedure/Measurement, and primary care consultations are accurately identified.

**Acceptance Scenarios**:

1. **Given** any tariff record standardized with an `APR-GRD:` code, **When** setting inference executes, **Then** the item is assigned to `Inpatient` setting, `Visit` domain, and `per_episode` unit type (unless explicitly designated as major ambulatory surgery `CMA`, which maps to `Procedures` / `Procedure` / `per_procedure`).
2. **Given** laboratory tests, diagnostic imaging, pathology, and genetic determinations, **When** clinical inference executes, **Then** the item is assigned to `Diagnostics` setting, `Measurement` domain, and `per_test` unit type.
3. **Given** primary care consultations, home visits, and health center continuous care services, **When** setting inference executes, **Then** the item is categorized under `Primary Care` setting and `per_visit` unit type.

---

### User Story 4 - HEOR-Grade Healthcare Deflation, Canonical Series Storage & Escalation Modeling (Priority: P2)

As an HEOR modeler, I need historical tariffs from 2013–2024 to be deflated and projected to target year 2026 using the official Healthcare Consumer Price Index (ECOICOP 06 Sanidad) and its specific sub-indices, with all historical index tables persisted as structured data files (`data/ine_indices_sanidad.csv`, `data/ine_indices_sanidad.parquet`, `data/ine_indices_sanidad.json`), so that cost projections maintain health economic validity and full auditability.

**Why this priority**: General CPI inflation includes energy and food spikes, creating a 16+ percentage point distortion over medical tariffs that inflates health system costs artificially.

**Independent Test**: Verify that the inflation pipeline queries and matches specifically the ECOICOP 06 Healthcare index (and supports hospital services 06.3 and medical outpatient services 06.2), exports the structured index tables to disk, and confirms that each historical year is adjusted by its exact historical index.

**Acceptance Scenarios**:

1. **Given** official price index series from the National Statistics Institute, **When** deflator series are computed, **Then** the pipeline strictly extracts the `Sanidad` (Subgroup 06) series and rejects the general CPI (`Índice General`).
2. **Given** healthcare items belonging to hospital care versus outpatient care, **When** deflation multipliers are applied, **Then** items utilize their respective healthcare sub-indices (06.3 for hospitalizations, 06.2 for medical and outpatient services, 06.1 for medical goods).
3. **Given** parsed INE index series, **When** deflation processing completes, **Then** canonical index series are persisted to `data/ine_indices_sanidad.csv`, `data/ine_indices_sanidad.parquet`, and `data/ine_indices_sanidad.json` for offline-first reproducibility and HEOR simulation reuse.
4. **Given** tariffs from varied historical baseline years (2013, 2014, 2017, 2018, 2022, 2023, 2024), **When** escalation to target year 2026 is computed, **Then** each item is inflated using its year-specific index ratio with full historical fidelity.

---

### User Story 5 - Robust Orchestration & Registry Synchronization (Priority: P3)

As an MLOps / data platform engineer, I need the cost extraction workflow to coordinate seamlessly between ingestion, deflator computation, extraction, and validation tasks with correct registry definitions and automated data passing.

**Why this priority**: Disconnected tasks and incorrect source format definitions prevent automated monthly execution and lead to skipped or failed catalog extractions.

**Independent Test**: Execute the automated workflow end-to-end; verify that task outputs pass seamlessly between pipeline stages and that all registry entries specify accurate formats and active source locations.

**Acceptance Scenarios**:

1. **Given** the deflation computation task, **When** execution succeeds, **Then** the resulting index series dictionary is passed directly to the extraction and export task without redundant external network re-fetches.
2. **Given** the registry specification of official sources, **When** catalog ingestion is triggered, **Then** all 22 sources possess valid file format declarations and correct endpoint mappings.

---

### Edge Cases

- What happens if a regional gazette website is temporarily unreachable or changes its URL? The system MUST utilize the cached raw source if available, log a clear warning, and not fail the remaining 21 sources.
- What happens if an HTML table contains unmerged multi-row header cells (`colspan`/`rowspan`)? The system MUST detect header rows and avoid treating subheaders as tariff values or procedure descriptions.
- What happens if a tariff description contains multiple price options (e.g. per session vs total cycle)? The system MUST parse the distinct price rows and assign appropriate unit types (`per_session` vs `per_episode`).
- What happens if the statistical institute has not yet released the complete annual index for the target projection year? The system MUST compute a projected escalation rate based on the latest available 12-month moving average of the healthcare series.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST dynamically detect character encoding (supporting UTF-8, ISO-8859-1, Windows-1252) when reading HTML, CSV, and text inputs, ensuring diacritics and special characters are preserved without data corruption.
- **FR-002**: System MUST implement multi-line text stream buffering in PDF extraction to group wrapped procedure descriptions before assigning price and code attributes.
- **FR-003**: System MUST apply negative filtering to discard gazette headers, footers, date lines, publication numbers, decree text, legislative preambles, and non-sanitary tax rate brackets.
- **FR-004**: System MUST enforce strict table layout precedence during HTML table parsing, ensuring specific 6-column layouts (Baleares APR-GRD) are evaluated prior to generic 5-column or 3-column formats.
- **FR-005**: System MUST validate `ICD-10-PCS` code assignments against authentic procedural grammar (7 alphanumeric characters with valid section, body system, and operation identifiers) and reject non-medical Spanish dictionary words or regional acronyms.
- **FR-006**: System MUST assign `REGIONAL:` code prefixes exclusively to authentic regional procedure codes (e.g. `CMA001`, `V03PVC001`, `LQ02166`) and exclude table section numbering or gazette acronyms.
- **FR-007**: System MUST classify all `APR-GRD` casemix records into `Inpatient` setting, `Visit` OMOP domain, and `per_episode` unit type by default, except when explicitly flagged as Major Ambulatory Surgery (`CMA`), which maps to `Procedures` / `Procedure` / `per_procedure`.
- **FR-008**: System MUST expand clinical keyword rules to classify diagnostic imaging, laboratory tests, and pathology into `Diagnostics` / `Measurement` / `per_test`, and primary care encounters into `Primary Care` / `Visit` / `per_visit`.
- **FR-009**: System MUST retrieve and apply the official Healthcare CPI index series (ECOICOP 06 Sanidad) for tariff deflation, strictly rejecting the general CPI series.
- **FR-010**: System MUST support granular deflator series for Hospital Services (ECOICOP 06.3) and Outpatient/Medical Services (ECOICOP 06.2).
- **FR-011**: System MUST parse and persist canonical INE index tables to `data/ine_indices_sanidad.csv`, `data/ine_indices_sanidad.parquet`, and `data/ine_indices_sanidad.json`.
- **FR-012**: System MUST compute year-specific escalation factors for each source baseline year to target year 2026 without using a generic single-year fallback.
- **FR-013**: System MUST pass computed deflators across pipeline orchestration tasks via inter-task messaging and synchronize `registries.yml` metadata with valid file formats.
- **FR-014**: System MUST assert zero missing values across mandatory attributes (`cost_id`, `description`, `setting`, `unit_type`, `cost_original`, `cost_updated`, `ccaa`, `omop_domain`) and export canonical catalogs in CSV, Parquet, and JSON formats.

### Key Entities

- **Cost Record**: Standardized unit cost entry containing unique identifier, cleaned description, clinical setting, medical specialty, unit type, original tariff, baseline year, updated tariff, target year, autonomous community (CCAA), legal source, source URL, standardized clinical code (`code_std`), and OMOP domain.
- **Standardized Clinical Code (`code_std`)**: Canonical code identifier with prefix (`APR-GRD:`, `ICD-9-CM:`, `ICD-10-PCS:`, `CN:`, `SAP:`, `REGIONAL:`).
- **Clinical Setting**: Operational healthcare environment (`Inpatient`, `ICU`, `Outpatient`, `Emergency`, `Diagnostics`, `Procedures`, `Primary Care`).
- **OMOP Domain**: Standard OMOP CDM domain category (`Visit`, `Procedure`, `Measurement`, `Drug`).
- **Deflator Series & Index Dataset**: Historical and projected price index tables derived from official INE Table 50913 (ECOICOP 06 Sanidad, 06.2 Ambulatorio, 06.3 Hospitalario) exported to `data/ine_indices_sanidad.*`.
- **Ground Registry**: Metadata configuration defining official source gazettes, legal titles, publication dates, formats, and download locations across all 17 Autonomous Communities, INGESA, and National Casemix.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 0% character encoding corruption or dropped diacritics across all 17 Autonomous Communities and national sources.
- **SC-002**: 0% false-positive dictionary words or regional codes categorized under `ICD-10-PCS`.
- **SC-003**: 100% of Balearic APR-GRD records extracted with correct GRD numbers, severity levels, and SAP codes without decimal weight contamination.
- **SC-004**: 0 non-sanitary legislative boilerplate rows, page numbers, or tax brackets present in the final canonical catalog.
- **SC-005**: 100% of inpatient APR-GRD casemix records accurately mapped to `Inpatient` setting and `per_episode` unit type, reducing overall outpatient fallback from >85% to under 40%.
- **SC-006**: 100% of historical cost records deflated and updated using the official Healthcare CPI series (ECOICOP 06 Sanidad), eliminating general CPI inflation bias.
- **SC-007**: Official INE Healthcare index tables exported to `data/ine_indices_sanidad.csv`, `data/ine_indices_sanidad.parquet`, and `data/ine_indices_sanidad.json` with 0 nulls.
- **SC-008**: 100% pipeline validation pass rate with zero null values and unique `cost_id`s exported across CSV, Parquet (Snappy), and JSON formats.

## Assumptions

- Official gazette structures remain public and accessible as published by their respective regional governments and the Spanish Ministry of Health.
- The National Statistics Institute (INE) continues publishing monthly ECOICOP 06 Sanidad sub-series (Table 50913).
- Inpatient APR-GRDs represent comprehensive admission episodes unless designated as ambulatory surgery (CMA) in official regional decree annexes.
