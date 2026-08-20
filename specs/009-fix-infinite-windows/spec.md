# Feature Specification: Open-Ended & Infinite Window Support for Cohort Enrichers

**Feature Branch**: `009-fix-infinite-windows`

**Created**: Thu Aug 20 2026

**Status**: Draft

**Input**: User requirement: "Fix bug in addHospitalizations / addInpatients where passing window = c(0, Inf) or window = list(c(0, Inf)) to observe hospitalizations across the full patient follow-up fails due to column name case conflicts (inpatient_admissions_0_to_Inf vs SQL lowercase) and NA/Inf date boundary handling."

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Full Follow-Up and Open-Ended Observation Windows (Priority: P1) 🎯 MVP

As an HEOR researcher, I need to compute healthcare resource utilization and direct medical costs over the entire patient follow-up or prior observation period using open-ended interval bounds such as `window = c(0, Inf)`, `window = list(c(0, Inf))`, or `window = list(c(0, NA))` across all `add*` cohort enrichers, so that whole-follow-up utilization metrics can be calculated without guessing arbitrary high day counts.

**Why this priority**: Real-world cohort studies routinely characterize utilization from cohort entry to end of follow-up / death / disenrolment rather than bounding at 365 days.

**Independent Test**: Execute `addInpatients()`, `addEmergencyCare()`, `addOutpatientVisits()`, `addPrescriptions()`, `addProcedures()`, `addCosts()`, and `addVisits()` with `window = c(0, Inf)` on a study cohort; verify that all events occurring on or after index date (and before censoring date if supplied) are aggregated into valid columns (`*_0_to_inf`), without SQL table registration errors or column name mismatches.

**Acceptance Scenarios**:

1. **Given** an active study cohort, **When** `addInpatients(window = c(0, Inf))` is called, **Then** all inpatient stays from `cohort_start_date` onward are counted under `inpatient_admissions_0_to_inf` and `inpatient_los_days_0_to_inf`.
2. **Given** an unnamed open-ended window with `NA` (e.g., `window = c(0, NA)` or `window = c(NA, 0)`), **When** evaluated, **Then** `validateWindow` normalizes `NA` to `Inf` / `-Inf` and generates lowercase column suffixes (`0_to_inf`, `minf_to_0`).
3. **Given** a named open-ended window (e.g., `window = list(all_followup = c(0, Inf))`), **When** evaluated, **Then** output columns use the lowercase user-specified name (e.g., `inpatient_admissions_all_followup`).

---

### User Story 2 - SQL-Safe Lowercase Column Naming Across All Window Formats (Priority: P1) 🎯 MVP

As an HEOR package maintainer, I need all auto-generated window column suffixes to adhere strictly to `snake_case` in all lowercase characters (e.g., `0_to_inf`, `minf_to_m1`, `m365_to_m1`), so that underlying SQL database engines (DuckDB, Postgres, Redshift, Snowflake) that normalize unquoted table identifiers to lowercase do not cause `dplyr::select` column mismatch errors when tables are inserted into the CDM.

**Why this priority**: Database engines case-fold unquoted identifiers, causing `CDMConnector` and `omopgenerics` table insertion to throw `Can't select columns that don't exist` when R data frames contain uppercase characters like `Inf` in column names.

**Independent Test**: Pass a matrix of window configurations (`c(-365, -1)`, `c(0, 365)`, `c(0, Inf)`, `c(-Inf, 0)`, `c(-Inf, Inf)`) without explicit names; verify that all generated table column names are 100% lowercase `snake_case` and successfully register into the database schema.

**Acceptance Scenarios**:

1. **Given** an auto-generated window for `c(0, Inf)`, **Then** the generated suffix is `"0_to_inf"`.
2. **Given** an auto-generated window for `c(-Inf, 0)`, **Then** the generated suffix is `"minf_to_0"`.
3. **Given** an auto-generated window for `c(-Inf, Inf)`, **Then** the generated suffix is `"minf_to_inf"`.
4. **Given** user-supplied mixed-case window names (e.g., `list(AllFollowUp = c(0, Inf))`), **Then** names are converted to lowercase `snake_case` (`all_followup`).

---

### User Story 3 - Robust Date Arithmetic and Censoring with Infinite Bounds (Priority: P2)

As a statistical programmer, I need date filtering logic across all clinical domain enrichers to handle `Inf` and `-Inf` without generating `NA` dates or throwing arithmetic warnings, and correctly respect `censorDate` bounds when specified.

**Why this priority**: Adding `Inf` to `Date` objects in R can result in non-standard `Date` representations or `NA` when evaluated in arithmetic expressions, which must be guarded against.

**Independent Test**: Run enricher functions with `censorDate` supplied and `window = c(0, Inf)`; verify that events occurring after the censor date are excluded, while all valid events between index date and censor date are included.

**Acceptance Scenarios**:

1. **Given** a cohort with `censorDate = "cohort_end_date"`, **When** `window = c(0, Inf)` is evaluated, **Then** event filtering terminates at `cohort_end_date`.
2. **Given** `addPrescriptions(daysSupply = TRUE, pdc = TRUE, window = c(0, 365))`, **When** evaluated, **Then** `pdc` continues to calculate normally, while for `window = c(0, Inf)` `pdc` computes against patient follow-up duration or defaults gracefully.

---

## Edge Cases

- **User writing `INF` or `inf` as string vs numeric**: `c(0, Inf)` is standard numeric in R. If a user passes strings or `NA`, `validateWindow` must gracefully parse/normalize without crashing.
- **Start bound greater than end bound**: Intervals like `c(Inf, 0)` or `c(100, -100)` must be rejected with informative error messages.
- **Both bounds infinite**: `window = c(-Inf, Inf)` or `window = c(NA, NA)` must represent lifetime observation from database history start to end of records.
- **Zero-utilization patients with infinite windows**: Patients with 0 events during entire follow-up must remain in the cohort table with `0L` / `0.0` column values.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `validateWindow` in `R/utilities.R` MUST accept numeric vectors containing `Inf`, `-Inf`, and `NA` (where `NA` is normalized to `-Inf` for start and `Inf` for end).
- **FR-002**: `validateWindow` MUST generate 100% lowercase `snake_case` window names (e.g., `"0_to_inf"`, `"minf_to_0"`, `"minf_to_inf"`), ensuring database column naming compatibility.
- **FR-003**: `addInpatients` (and `addHospitalizations`, `addInpatient`) MUST correctly filter events when `w_start = -Inf` and/or `w_end = Inf` without `Date + Inf` arithmetic failure.
- **FR-004**: `addEmergencyCare` (and `addEmergency`, `addEmergencyVisits`) MUST support infinite and `NA` window bounds.
- **FR-005**: `addOutpatientVisits` MUST support infinite and `NA` window bounds.
- **FR-006**: `addPrescriptions` MUST support infinite and `NA` window bounds.
- **FR-007**: `addProcedures` MUST support infinite and `NA` window bounds.
- **FR-008**: `addCosts` MUST support infinite and `NA` window bounds.
- **FR-009**: `addVisits` MUST pass down infinite and `NA` window bounds to all constituent domain enrichers.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of `add*` enricher functions execute without errors or warnings when passed `window = c(0, Inf)` or `window = list(c(0, Inf))` on any supported database backend.
- **SC-002**: 100% of auto-generated table column names are lowercase `snake_case`, preventing `dplyr::select` column mismatch errors during `insertTable`.
- **SC-003**: Censoring via `censorDate` is accurately respected when combined with infinite window bounds.
- **SC-004**: All existing and new test suites pass with 0 failures and 0 warnings.
