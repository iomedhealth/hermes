# Tasks: HCRU Domain Extraction and Financial Linkage

**Input**: Design documents from `specs/005-hcru-domain-extraction/` (`spec.md`, `plan.md`, `data-model.md`, `research.md`, `contracts/extract-hcru-api.md`)

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: Enforcing Test-Driven Development (TDD). Tests MUST be updated/written first before modifying package implementation R files.

## Format: `- [ ] [TaskID] [P?] [Story?] Description with file path`

- **Checkbox**: `- [ ]`
- **Task ID**: T001, T002, T003...
- **[P]**: Parallelizable task
- **[Story?]**: [US1], [US2], [US3] for user story tasks
- Exact file paths in description

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Provide synthetic CDM data fixtures across all OMOP clinical and financial tables (`visit_occurrence`, `provider`, `drug_exposure`, `procedure_occurrence`, `measurement`, `cost`).

- [X] T001 Enhance synthetic OMOP test CDM generator to include `visit_occurrence`, `provider`, `drug_exposure`, `procedure_occurrence`, `measurement`, and multi-domain `cost` tables in `tests/testthat/helper-eunomia.R`
- [X] T002 [P] Update stage 2 test fixtures with multi-patient target, comparator, and outcome cohort definitions in `tests/testthat/helper-stage2.R`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core cohort resolution, temporal window calculation, and scaffolding utilities shared across all utilization domains.

- [X] T003 Implement study cohort extraction and temporal window boundary helpers (`baseline` vs. `followup`) in `R/hcru.R`
- [X] T004 [P] Implement zero-utilization cohort patient scaffolding helper to preserve subjects with zero events across all domain summaries in `R/hcru.R`

---

## Phase 3: User Story 1 - Cohort-Linked Temporal Utilization & Cost Extraction across Core Domains (Priority: P1) 🎯 MVP

**Goal**: Restrict utilization and direct medical costs exclusively to study cohort members across configurable baseline (`[-365, -1]`) and follow-up (`[0, 365]`) windows, link OMOP `cost` records polymorphic to clinical domain events, tag costs by health state (`State_Baseline`, `State_Outcome`), and return an enriched `hermes_hcru` object.

**Independent Test**: Execute `extract_hcru()` on a study object with target/comparator cohorts; verify all returned costs and domain metrics belong strictly to cohort members within baseline/follow-up windows, with zero-utilization cohort members retained.

### Tests for User Story 1 (TDD)

- [X] T005 [US1] Write unit tests for cohort-filtered temporal window extraction and multi-domain financial linkage in `tests/testthat/test-stage2-hcru.R`

### Implementation for User Story 1

- [X] T006 [US1] Update `extract_hcru()` function signature with `baseline_window`, `followup_window`, and `cost_field` arguments and input validation in `R/hcru.R`
- [X] T007 [US1] Implement cohort filtering and temporal window event mapping across clinical tables in `R/hcru.R`
- [X] T008 [US1] Implement multi-domain financial linkage matching `cost_domain_id` and `cost_event_id` with `health_state` tagging in `R/hcru.R`
- [X] T009 [US1] Assemble patient-level cost data frame (`study$costs`) and baseline/follow-up combined summary table (`study$hcru$patient_summary`) in `R/hcru.R`

**Checkpoint**: User Story 1 complete and independently testable via `devtools::test(filter = 'stage2')`.

---

## Phase 4: User Story 2 - Stratified Outpatient, Provider Specialty, and Inpatient Metrics (Priority: P2)

**Goal**: Provide granular extraction and stratification of inpatient admissions, ICU stays, cumulative LOS, optional 30/90-day hospital readmissions, and outpatient/emergency encounters stratified by ED, General Practice (GP), and Medical Specialist.

**Independent Test**: Execute `extract_hcru()` on a study with inpatient, ICU, emergency, GP, and specialist visits; verify counts, lengths of stay, and readmission flags are correctly partitioned into `study$hcru$inpatient` and `study$hcru$outpatient`.

### Tests for User Story 2 (TDD)

- [X] T010 [US2] Write unit tests for inpatient LOS, ICU stays, 30/90-day readmissions, and provider specialty outpatient stratification in `tests/testthat/test-stage2-hcru.R`

### Implementation for User Story 2

- [X] T011 [US2] Implement Inpatient and ICU care extraction (admissions, length of stay, optional 30-day/90-day readmission calculation) from `visit_occurrence` in `R/hcru.R`
- [X] T012 [US2] Implement Outpatient and Emergency care extraction with `provider` table join and stratification (ED, GP, Specialist, Other Outpatient) in `R/hcru.R`
- [X] T013 [US2] Integrate `inpatient` and `outpatient` domain tibbles into `study$hcru` and wide `patient_summary` in `R/hcru.R`

**Checkpoint**: User Story 2 complete and independently testable via `devtools::test(filter = 'stage2')`.

---

## Phase 5: User Story 3 - Comprehensive Pharmacotherapy, Diagnostics, and Post-Acute Care Extraction (Priority: P3)

**Goal**: Extract prescription fills, cumulative days supply, optional PDC adherence/persistence, procedural occurrences, diagnostic laboratory measurements, and post-acute SNF/Hospice care stays.

**Independent Test**: Execute `extract_hcru()` on a cohort with drug exposures, procedures, measurements, and post-acute stays; verify counts and days supply are correctly aggregated in `study$hcru$pharmacotherapy`, `study$hcru$procedures_diagnostics`, and `study$hcru$post_acute`.

### Tests for User Story 3 (TDD)

- [X] T014 [US3] Write unit tests for pharmacotherapy (fills, days supply, PDC), procedures, measurements, and post-acute stays in `tests/testthat/test-stage2-hcru.R`

### Implementation for User Story 3

- [X] T015 [US3] Implement pharmacotherapy utilization extraction (`drug_exposure` fills, `days_supply`, optional PDC) in `R/hcru.R`
- [X] T016 [US3] Implement diagnostics and procedures utilization extraction (`procedure_occurrence` and `measurement` event counts) in `R/hcru.R`
- [X] T017 [US3] Implement post-acute care utilization extraction (SNF and Hospice visits and LOS) from `visit_occurrence` in `R/hcru.R`
- [X] T018 [US3] Integrate `pharmacotherapy`, `procedures_diagnostics`, and `post_acute` domain tibbles into `study$hcru` and wide `patient_summary` in `R/hcru.R`

**Checkpoint**: User Story 3 complete and independently testable via `devtools::test(filter = 'stage2')`.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Ensure end-to-end pipeline compatibility across Stage 3 (PS), Stage 4 (Trajectories), Stage 5 (Simulation), and Stage 6 (CEA), and code quality compliance.

- [X] T019 Update end-to-end integration test `tests/testthat/test-e2e.R` verifying pipeline execution with multi-domain HCRU and cost extraction
- [X] T020 [P] Execute full test suite via `devtools::test()` ensuring 100% test pass rate in `tests/testthat/`
- [X] T021 [P] Run `styler::style_dir()` and `lintr::lint_dir()` to enforce HERMES style guidelines (Base pipe `|>`, `<-` assignment, `snake_case`)

---

## Dependencies & Execution Order

```text
Foundational (T001, T002, T003, T004)
   │
   ▼
Phase 3: User Story 1 (P1 - Core HCRU & Costs) 🎯 MVP
   ├── Tests: T005
   └── Implementation: T006 ──> T007 ──> T008 ──> T009
   │
   ▼
Phase 4: User Story 2 (P2 - Inpatient & Outpatient Stratification)
   ├── Tests: T010
   └── Implementation: T011 ──> T012 ──> T013
   │
   ▼
Phase 5: User Story 3 (P3 - Pharmacy, Procedures & Post-Acute)
   ├── Tests: T014
   └── Implementation: T015 ──> T016 ──> T017 ──> T018
   │
   ▼
Phase 6: Polish & Pipeline Integration (T019, T020, T021)
```

---

## Parallel Execution Opportunities

- **Phase 1 & 2**: T001, T002, and T004 can be prepared in parallel.
- **Phase 3 (US1)**: Test creation (T005) precedes implementation (T006-T009).
- **Phase 4 (US2)**: Inpatient (T011) and Outpatient (T012) queries can be drafted in parallel before integration (T013).
- **Phase 5 (US3)**: Pharmacy (T015), Procedures/Diagnostics (T016), and Post-Acute (T017) can be developed in parallel before integration (T018).
- **Phase 6**: Full test suite execution (T020) and style formatting (T021) can run in parallel after E2E updates (T019).

---

## Implementation Strategy

1. **MVP (Phases 1-3)**: Deliver working cohort-windowed financial linkage and basic domain aggregation (`study$costs` and `study$hcru$patient_summary`).
2. **Incremental Enhancements (Phases 4-5)**: Layer on granular setting stratification (Inpatient LOS, ICU, Readmissions, GP/Specialist/ED) followed by Pharmacy, Procedure, Measurement, and Post-Acute domains.
3. **Pipeline Verification (Phase 6)**: Confirm seamless integration across all 6 stages of the HERMES analytical pipeline.
