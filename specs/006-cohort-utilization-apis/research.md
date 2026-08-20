# Technical Research & Architecture Decisions: Cohort Utilization APIs

## 1. API Naming and Paradigm Alignment

### Decision
Adopt the 3-layer architecture from DARWIN EU / OHDSI packages:
1. **`CohortConstructor` Paradigm:** Discrete care episode creation (`computeHospitalizationCohorts()`, `computeInfusionCohorts()`).
2. **`PatientProfiles` Paradigm:** In-database cohort column enrichment (`addHospitalizations()`, `addOutpatientVisits()`, `addPrescriptions()`, `addProcedures()`, `addCosts()`).
3. **`CohortCharacteristics` Paradigm:** Analytical aggregation and standardized reporting (`summariseUtilization()`, `summariseCosts()`, `tableUtilization()`, `tableCosts()`).

### Rationale
- The previous monolithic `extract_hcru()` function combined all domain extractions and financial linkage into a single in-memory collection step. While functional, it broke composability and did not conform to the pipeable `add*` workflow expected by DARWIN EU users.
- Eliminating the repetitive `*Hcru` suffix makes functions read like natural English (`addHospitalizations()`, `addOutpatientVisits()`, `addPrescriptions()`, `addProcedures()`, `addCosts()`) while preserving domain clarity.

### Alternatives Considered
- `addInpatientHcru()`, `addOutpatientHcru()`: Rejected due to clunky, repetitive naming.
- Single generic `addUtilization(domain = "inpatient")`: Rejected because domain-specific arguments (e.g. `gpSpecialtyConceptIds` for outpatient, `daysSupply` for pharmacy, `readmissions` for inpatient) become messy in a single function signature.

---

## 2. In-Database Windowed Intersections (`dbplyr` Architecture)

### Decision
Perform all window calculations, joins, and aggregations inside the database using `dbplyr` queries and write the resulting tables to the scratch/write schema using `omopgenerics::uniqueTableName()` and `dplyr::compute()`.

### Rationale
- Real-world OMOP databases contain millions of visit, drug, and procedure records. Pulling unaggregated records into R memory causes Out-Of-Memory (OOM) errors and severe latency.
- `dbplyr` translates `mutate`, `filter`, and `summarise` operations into native SQL (DuckDB, PostgreSQL, SQL Server, etc.), minimizing data transfer over the wire.

### Alternatives Considered
- Collecting raw event records to client memory (as done in initial prototypes): Rejected for production scalability.

---

## 3. Window Representation & Column Naming Templates (`nameStyle`)

### Decision
Support window lists formatted as:
```r
window = list(baseline = c(-365, -1), followup = c(0, 365))
```
and column naming via `glue`-compatible `nameStyle` parameters (e.g., `{metric}_{window_name}` or `{setting}_visits_{window_name}`). If an unnamed list is supplied (e.g., `list(c(-365, -1))`), window names default to `m365_to_m1`.

### Rationale
- Directly mirrors `PatientProfiles::addTableIntersectCount()` and `PatientProfiles::addDemographics()`, providing zero learning curve for OHDSI package users.

---

## 4. Concept Set Filtering for Granular Domains

### Decision
- **Inpatient & ICU:** Default visit concepts `c(9201L, 8717L, 581379L)` for general inpatient; `32037L` for Intensive Care Unit (ICU).
- **Outpatient Specialties:** Default `visit_concept_id %in% c(9202L, 581477L)`. General Practice identified when `provider.specialty_concept_id == 38004446L` or `is.na(specialty_concept_id)`. Specialist visits identified when non-GP specialty is present. Emergency visits identified by `visit_concept_id == 9203L`.
- **Infusions:** Identified by route concepts (e.g., Intravenous `4171047L`, Parenteral `4171048L`) in `drug_exposure` or procedure administration codes.
- **Diagnostics vs. Procedures:** Separate counts for `measurement` records (lab tests, vital signs) and `procedure_occurrence` records (surgical, therapeutic, and imaging procedures).

---

## 5. Analytical Summarisation (`summarised_result` S3 Class)

### Decision
All summarisation functions (`summariseUtilization()`, `summariseCosts()`) return standard `omopgenerics::summarised_result` tibbles with columns:
`cdm_name`, `group_name`, `group_level`, `strata_name`, `strata_level`, `variable_name`, `estimate_name`, `estimate_value`, `additional_name`, `additional_level`.

### Rationale
- Allows direct feeding into `visOmopResults::visOmopTable()`, `visOmopResults::boxPlot()`, and `visOmopResults::barPlot()`.
- Facilitates multi-database network studies and automated shiny dashboard rendering without format conversions.

---

## 6. Maximal Reuse & Mimicry of Core Packages

### Decision
Directly delegate standard cohort construction, table intersections, and summarisation to upstream packages:
- **`CohortConstructor`**: Reuse `collapseCohorts()` and `conceptCohort()` for interval manipulation and episode construction.
- **`PatientProfiles`**: Reuse `addTableIntersectCount()`, `addConceptIntersectCount()`, and `addDemographics()` directly for generic table queries.
- **`CohortCharacteristics` & `visOmopResults`**: Reuse `summariseCharacteristics()` and `visOmopTable()` for standard reporting.
- **Custom Compound Operations**: For specialized operations not supported by single high-level upstream functions (e.g. multi-table provider specialty joins and polymorphic OMOP `cost` table joins), implement them following the exact internal `dbplyr` conventions of `PatientProfiles`:
  1. Validate arguments using `omopgenerics::validateCohortArgument()`, `omopgenerics::validateCdmArgument()`, `omopgenerics::assertCharacter()`, `omopgenerics::assertNumeric()`.
  2. Use `omopgenerics::tmpPrefix()` and `omopgenerics::uniqueTableName()` for intermediate scratch tables.
  3. Clean up intermediate scratch tables using `omopgenerics::dropSourceTable()`.
  4. Ensure 0-count fill semantics using left joins against the cohort scaffolding.
