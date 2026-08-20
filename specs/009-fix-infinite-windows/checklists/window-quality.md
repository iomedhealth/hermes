# Requirements Quality Checklist: Open-Ended & Infinite Window Support

**Purpose**: Validate specification completeness, clarity, and consistency for open-ended and infinite observation windows across all cohort enrichers.
**Created**: Thu Aug 20 2026
**Feature**: [spec.md](../spec.md)

> **Ownership Note**: This checklist is a reviewer-owned requirements-quality review artifact. Items are generated unchecked `[ ]`. A checked item `[x]` indicates that the reviewer has verified that the requirement is well-specified, complete, and unambiguous.

---

## 1. Requirement Completeness

- [ ] CHK001 - Are all supported interval syntax forms (`c(start, end)`, `list(c(start, end))`, `list(name = c(start, end))`) explicitly documented? [Completeness, Spec §FR-001]
- [ ] CHK002 - Are requirements specified for normalizing `NA` values in both start and end positions of window vectors? [Completeness, Spec §FR-001]
- [ ] CHK003 - Are all seven cohort enricher functions (`addInpatients`, `addEmergencyCare`, `addOutpatientVisits`, `addPrescriptions`, `addProcedures`, `addCosts`, `addVisits`) explicitly listed with infinite window requirements? [Completeness, Spec §FR-003-FR-009]
- [ ] CHK004 - Are output column naming requirements defined for both named and unnamed window lists? [Completeness, Spec §FR-002]

---

## 2. Requirement Clarity & Unambiguity

- [ ] CHK005 - Is the exact naming pattern for negative infinite start bounds (`"minf"`) and positive infinite end bounds (`"inf"`) specified without ambiguity? [Clarity, Spec §FR-002]
- [ ] CHK006 - Is the behavior when `censorDate` is provided alongside `w_end = Inf` explicitly defined with precedence rules? [Clarity, Spec §User Story 3]
- [ ] CHK007 - Is the distinction between R's numeric `Inf` and string/symbolic inputs clarified? [Clarity, Spec §Edge Cases]

---

## 3. Requirement Consistency

- [ ] CHK008 - Do column naming conventions across `addInpatients`, `addEmergencyCare`, `addOutpatientVisits`, `addPrescriptions`, `addProcedures`, `addCosts`, and `addVisits` use identical lowercase `snake_case` suffix formatting? [Consistency, Spec §FR-002]
- [ ] CHK009 - Is `c(0, NA)` specified to behave identically to `c(0, Inf)` across all enrichers? [Consistency, Spec §FR-001]
- [ ] CHK010 - Do the validation requirements in `validateWindow` align with downstream `dbplyr` date filtering logic? [Consistency, Spec §FR-001, FR-003]

---

## 4. Scenario & Edge Case Coverage

- [ ] CHK011 - Are requirements specified for invalid inverted intervals such as `c(Inf, 0)` or `c(100, -100)`? [Edge Case, Spec §Edge Cases]
- [ ] CHK012 - Are requirements defined for bilateral infinite windows (`c(-Inf, Inf)` and `c(NA, NA)`) representing lifetime observation? [Coverage, Spec §Edge Cases]
- [ ] CHK013 - Are requirements specified for zero-utilization subjects when evaluating infinite windows? [Coverage, Spec §Edge Cases]
- [ ] CHK014 - Is the behavior of adherence score (`pdc`) calculation under infinite follow-up windows defined? [Edge Case, Spec §User Story 3]

---

## 5. Measurability & Verifiability

- [ ] CHK015 - Can the requirement for 100% lowercase database column names be objectively verified without platform ambiguity? [Measurability, Spec §SC-002]
- [ ] CHK016 - Are success criteria quantified with measurable zero-failure and zero-warning targets? [Measurability, Spec §SC-001, SC-004]

---

## Notes

- Generated for requirements-quality validation of feature `009-fix-infinite-windows`.
