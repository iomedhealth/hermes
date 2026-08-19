# Requirements Quality Checklist: DARWIN EU-Aligned Cohort Utilization APIs

**Purpose**: Validate specification completeness, clarity, consistency, and alignment with DARWIN EU / OHDSI standards before task breakdown and implementation.
**Created**: Wed Aug 19 2026
**Feature**: [spec.md](../spec.md) | [contracts/cohort-utilization-api.md](../contracts/cohort-utilization-api.md)

> **Ownership Note**: This checklist is a reviewer-owned requirements-quality artifact ("Unit Tests for English"). `[x]` indicates that the reviewer confirmed the requirement quality criterion is satisfied in the specification documents.

---

## 1. Requirement Completeness

- [ ] CHK001 Are explicit parameter definitions and type signatures specified for all Layer 1 episode constructors? [Completeness, Spec §FR-001, §FR-002]
- [ ] CHK002 Are input validation rules specified when cohort table `x` does not contain required OMOP columns? [Completeness, Spec §FR-008]
- [ ] CHK003 Are the exact clinical concept ID sets specified for default Inpatient, ICU, Emergency, and GP visit filtering? [Completeness, Spec §FR-003, §FR-004]
- [ ] CHK004 Are requirements defined for handling both named and unnamed window parameter lists? [Completeness, Spec §FR-010]
- [ ] CHK005 Are requirements documented for all 5 direct medical cost domains in `addCosts()`? [Completeness, Spec §FR-007]
- [ ] CHK006 Are output structure and S3 class requirements specified for analytical summary functions? [Completeness, Spec §FR-011, §FR-012]
- [ ] CHK007 Are requirements specified for when the OMOP `cost` table is missing or empty in the database? [Completeness, Edge Case]
- [ ] CHK008 Are fallback rendering requirements defined if the `gt` or `flextable` packages are not installed? [Completeness, Spec §FR-013, Gap]

---

## 2. Requirement Clarity & Unambiguity

- [ ] CHK009 Is the definition of "inpatient stay collapsing" quantified with an exact days-gap threshold? [Clarity, Spec §FR-001]
- [ ] CHK010 Are the exact mathematical formulas for Proportion of Days Covered (PDC) and Length of Stay (LOS) explicitly specified? [Clarity, Spec §FR-003, §FR-005]
- [ ] CHK011 Is the distinction between General Practice and Specialist visits unambiguously defined based on provider specialty concept IDs? [Clarity, Spec §FR-004]
- [ ] CHK012 Are the available placeholder tokens in `nameStyle` (`{metric}`, `{domain}`, `{window_name}`, `{setting}`) cataloged with example outputs? [Clarity, Spec §FR-009]
- [ ] CHK013 Is the health state assignment logic (`State_Baseline` vs. `State_Outcome`) clear when an outcome date is missing? [Clarity, Data Model §1.3]

---

## 3. Requirement Consistency & DARWIN EU Alignment

- [ ] CHK014 Do all exported R function names strictly follow `lowerCamelCase` without `*Hcru` suffixes? [Consistency, Spec §FR-015]
- [ ] CHK015 Do all function argument names follow `lowerCamelCase` across all three architectural layers? [Consistency, Spec §FR-015]
- [ ] CHK016 Do all database table columns generated in cohort tables adhere to `snake_case`? [Consistency, Spec §FR-016]
- [ ] CHK017 Are function argument names and defaults consistent with `PatientProfiles` (`indexDate`, `censorDate`, `window`, `nameStyle`, `name`)? [Consistency, Spec §FR-008]
- [ ] CHK018 Does the analytical output of `summariseUtilization()` adhere to the standard 10-column `omopgenerics::summarised_result` schema? [Consistency, Spec §FR-011]

---

## 4. Edge Case & Boundary Coverage

- [ ] CHK019 Are requirements defined for subjects in the cohort who have zero events across all clinical domains? [Edge Case, Spec §Edge Cases]
- [ ] CHK020 Are duration calculation rules specified for same-day discharges where `visit_end_date == visit_start_date`? [Edge Case, Spec §Edge Cases]
- [ ] CHK021 Are requirements defined for handling events that fall outside the observation period of the patient? [Edge Case, Gap]
- [ ] CHK022 Are requirements specified for when `censorDate` occurs before the end of a specified follow-up window? [Edge Case, Spec §FR-008]
- [ ] CHK023 Are behavior requirements documented when `name` matches an existing table in the write schema (overwrite vs. error)? [Edge Case, Spec §FR-008]

---

## 5. Acceptance Criteria & Measurability

- [ ] CHK024 Can cohort row-count preservation (0% patient loss) be objectively measured across all enricher verbs? [Measurability, Spec §SC-001]
- [ ] CHK025 Can the 12 core utilization and cost metrics be individually verified against benchmark test datasets? [Measurability, Spec §SC-002]
- [ ] CHK026 Is the pass condition for `summarised_result` validation objectively verifiable via `omopgenerics::validateResultArgument()`? [Measurability, Spec §SC-005]
- [ ] CHK027 Can adherence to DARWIN EU naming conventions be automatically verified via `lintr`? [Measurability, Spec §SC-006]

---

## 6. Non-Functional & Database Performance Requirements

- [ ] CHK028 Are in-database execution requirements explicitly mandated via `dbplyr` without client-side data pulling? [Performance, Spec §FR-008, Plan §Summary]
- [ ] CHK029 Are temporary table cleanup requirements defined to avoid cluttering the CDM write schema? [Performance, Plan §Constraints]
- [ ] CHK030 Are cross-database SQL dialect compatibility requirements (DuckDB, Postgres, SQL Server, Oracle) addressed? [Portability, Plan §Technical Context]

---

## Notes

- 30 checklist items generated across 6 requirement quality dimensions.
- 100% of items include traceability markers (`[Spec §...]`, `[Clarity]`, `[Consistency]`, `[Edge Case]`, `[Performance]`, `[Gap]`).
- All items are formulated as requirements quality questions ("Unit Tests for English").
