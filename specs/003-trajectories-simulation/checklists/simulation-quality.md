# Requirements Quality Checklist: Stage 4 (Trajectories) and Stage 5 (Economic Simulation)

**Purpose**: Validate requirement quality, completeness, clarity, and consistency for Stage 4 Trajectories and Stage 5 Economic Simulation before implementation.
**Created**: 2026-08-13
**Feature**: [spec.md](../spec.md)

## Requirement Completeness

- [x] CHK001 - Are input requirements for `compile_trajectories()` fully specified regarding required fields in `ps_obj$matched_pop` and `ps_obj$hcru_obj$costs`? [Completeness, Spec §FR-002]
- [x] CHK002 - Are the expected health state names and identifiers explicitly specified for trajectory compilation? [Completeness, Spec §FR-001]
- [x] CHK003 - Are mathematical definitions for standard error of cost (`se_cost`) fully documented for states with `n <= 1` observation? [Completeness, Spec §FR-003]
- [x] CHK004 - Are prior probability distribution parameters (e.g., Dirichlet, Beta, Gamma) explicitly specified for all PSA parameters? [Completeness, Spec §FR-005]
- [x] CHK005 - Are structure requirements for the `hesim_ce` object (`costs` and `qalys` data frame schemas) documented in full detail? [Completeness, Spec §FR-006]

## Requirement Clarity

- [x] CHK006 - Is the 30-day discrete time step boundary condition quantified with precise calendar day calculation rules? [Clarity, Spec §FR-001]
- [x] CHK007 - Is the discount rate application formula explicitly defined for non-integer annual cycle lengths? [Clarity, Spec §FR-006]
- [x] CHK008 - Are default health state utility weights (QALY values) and their variance parameters quantified with specific numeric defaults? [Clarity, Spec §Edge Cases]
- [x] CHK009 - Is the handling of censored patient timelines unambiguously defined for state-to-state transition probability calculations? [Clarity, Spec §Edge Cases]

## Requirement Consistency

- [x] CHK010 - Do the `hesim_ce` output column names in Stage 5 align consistently with the expectations of `run_cea()` in Stage 6? [Consistency, Spec §FR-006]
- [x] CHK011 - Are the strategy identifiers (`strategy_id`) consistent between Stage 4 cost grouping and Stage 5 simulation parameters? [Consistency, Spec §FR-002]
- [x] CHK012 - Does the DuckDB cost table schema in test helpers match the OMOP `COST` table structure assumed by Stage 2 and Stage 4? [Consistency, Spec §FR-007]

## Acceptance Criteria & Measurability

- [x] CHK013 - Can the execution requirement for dynamic transition probability computation be objectively verified without relying on hardcoded matrices? [Measurability, Spec §SC-002]
- [x] CHK014 - Is the test performance requirement (<60 seconds on DuckDB Eunomia fixture) verifiable across test execution environments? [Measurability, Spec §SC-001]
- [x] CHK015 - Are acceptance criteria for PSA sample generation objectively testable regarding iteration counts and non-empty outputs? [Measurability, Spec §SC-003]

## Scenario & Edge Case Coverage

- [x] CHK016 - Are requirements specified for handling cohorts with zero occurrences of the outcome event during the observation period? [Coverage, Spec §Edge Cases]
- [x] CHK017 - Are requirements specified for handling health states with zero assigned cost records in the `COST` table? [Coverage, Gap]
- [x] CHK018 - Are requirements defined for patient attrition or early dropouts prior to the full time horizon? [Coverage, Spec §Edge Cases]
- [x] CHK019 - Are recovery or fallback requirements specified if PSA parameter sampling produces invalid non-positive matrix values? [Coverage, Gap]

## Dependencies & Non-Functional Requirements

- [x] CHK020 - Are architectural constraints (Base R pipe `|>`, `<-` assignment, `snake_case`) explicitly stated for all new functions? [Traceability, Spec §FR-008]
- [x] CHK021 - Are external R package dependency requirements (`hesim`, `Cohort2Trajectory`, `TrajectoryMarkovAnalysis`) clearly documented? [Dependency, Spec §Assumptions]
- [x] CHK022 - Are read-only access rules for OMOP database tables explicitly mandated for test fixtures and package functions? [Constraint, Spec §FR-007]
