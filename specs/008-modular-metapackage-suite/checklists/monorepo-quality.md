# Requirements Quality Checklist: Modular Package Suite & Metapackage Architecture

**Purpose**: Validate specification completeness, clarity, consistency, and coverage for the 3-domain package split and root metapackage monorepo.
**Created**: Thu Aug 20 2026
**Feature**: [spec.md](../spec.md)

> **Reviewer Note**: Checkbox markers (`[ ]`) represent reviewer-evaluated criteria for requirements quality. An item is marked `[x]` only when the reviewer confirms the requirement is thoroughly, unambiguously, and testably documented in the specification.

---

## 1. Requirement Completeness

- [ ] CHK001 - Are the exact directory paths for all sub-packages explicitly defined? [Completeness, Spec §FR-001]
- [ ] CHK002 - Is the complete list of exported functions cataloged for `CohortUtilisation`? [Completeness, Spec §FR-003]
- [ ] CHK003 - Is the complete list of exported functions and data tables cataloged for `CohortCosts`? [Completeness, Spec §FR-005, §FR-006]
- [ ] CHK004 - Is the complete list of exported analytical functions cataloged for `CohortEconomics`? [Completeness, Spec §FR-007]
- [ ] CHK005 - Are package dependency lists (Imports, Suggests, Depends) explicitly specified for each sub-package? [Completeness, Spec §FR-004, §FR-008]

---

## 2. Requirement Clarity & Unambiguity

- [ ] CHK006 - Is the behavior of `library(hermes)` explicitly quantified (e.g., startup banner message and attached namespaces)? [Clarity, Spec §FR-009, §FR-010]
- [ ] CHK007 - Is the distinction between root installation (`install_github("iomedhealth/hermes")`) and granular installation (`subdir = ...`) unambiguously defined? [Clarity, Spec §SC-001, §SC-002]
- [ ] CHK008 - Are naming convention boundaries between R package names (PascalCase) and public functions (lowerCamelCase) explicitly documented? [Clarity, Spec §FR-011, §SC-005]

---

## 3. Requirement Consistency

- [ ] CHK009 - Do the function contracts in `contracts/monorepo-suite-contracts.md` perfectly align with the function lists in `spec.md`? [Consistency, Spec §FR-003, §FR-005, §FR-007]
- [ ] CHK010 - Are database table column naming rules (`snake_case`) consistently enforced across all three domain modules? [Consistency, Spec §FR-012]
- [ ] CHK011 - Does the S3 class hierarchy (`hermes_study`, `hermes_hcru`, `summarised_result`) remain consistent across package boundaries? [Consistency, Spec §Key Entities]

---

## 4. Scenario & Edge Case Coverage

- [ ] CHK012 - Are requirements specified for users installing `CohortUtilisation` in environments lacking Bayesian/simulation dependencies? [Coverage, Spec §US1, §FR-004]
- [ ] CHK013 - Are requirements defined for cross-package namespace collision handling during metapackage attachment? [Coverage, Spec §Edge Cases, §SC-004]
- [ ] CHK014 - Is isolated testing and continuous integration (CI) workflow defined for each sub-package? [Coverage, Spec §SC-003]
- [ ] CHK015 - Are unified documentation website structure and cross-package vignette requirements specified? [Coverage, Spec §US5]

---

## 5. Acceptance Criteria Measurability

- [ ] CHK016 - Can the success criterion for single-command installation be objectively validated without implementation assumptions? [Measurability, Spec §SC-001]
- [ ] CHK017 - Can isolated test pass rates for each sub-package be verified independently? [Measurability, Spec §SC-003]
- [ ] CHK018 - Can style and naming compliance be verified objectively with automated linting tools? [Measurability, Spec §SC-005]

---

## Notes

- Evaluates requirements quality for `008-modular-metapackage-suite`.
- Items remain unchecked until reviewer evaluation.
