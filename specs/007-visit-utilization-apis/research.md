# Technical Research & Design Decisions: Visit Utilization APIs

## 1. Function Naming & Alias Architecture

### Decision
Rename `addHospitalizations()` to `addInpatients()`, export both `addInpatients` and `addHospitalizations` (as well as `addInpatient`), export `addEmergencyCare` (with alias `addEmergency` and `addEmergencyVisits`), and export `addVisits` (without `add_visits` snake_case alias).

### Rationale
- `addInpatients()` aligns cleanly with `addVisits()`, `addOutpatientVisits()`, `addPrescriptions()`, `addProcedures()`, and `addCosts()`.
- Retaining `addHospitalizations()` as an exported alias prevents breaking changes in existing user code or vignettes.
- `addEmergencyCare()` is explicit and prevents confusion with generic outpatient visits.
- Omitting `add_visits` conforms strictly to the DARWIN EU rule that public package interfaces use `lowerCamelCase`.

### Alternatives Considered
- *Deprecated warning on `addHospitalizations()`*: Rejected for now to avoid noisy logs during routine script executions.
- *Single monster function without modular verbs*: Rejected because modular verbs (`addInpatients`, `addEmergencyCare`, `addOutpatientVisits`) enable fine-grained execution and specific window parameterizations.

---

## 2. Emergency Care Identification: Dual-Criteria Detection

### Decision
An encounter is classified as an emergency care act if:
$$\text{visit\_concept\_id} \in \text{emergencyVisitConceptIds} \quad \lor \quad \text{specialty\_concept\_id} \in \text{emergencySpecialtyConceptIds}$$

- Default `emergencyVisitConceptIds`: `c(9203L, 262L, 581478L)`
  - `9203`: Emergency Room Visit
  - `262`: Emergency Room and Inpatient Visit
  - `581478`: Emergency Room Visit
- Default `emergencySpecialtyConceptIds`: `c(38004510L)`
  - `38004510`: Emergency Medicine provider specialty

### Rationale
Real-world OMOP datasets often classify emergency department visits either through encounter concepts or through provider taxonomies (where an acute visit is billed with a general outpatient concept but attended by an Emergency Medicine specialist). Evaluating both sources ensures 100% sensitivity for emergency care acts.

---

## 3. Specialty Stratification Pattern Across All Settings

### Decision
Standardize the `specialties` argument across `addInpatients()`, `addOutpatientVisits()`, `addEmergencyCare()`, and `addVisits()` as a named list of integer vectors:
```r
specialties = list(
  cardiology = c(38004453L, 38004481L),
  oncology = c(38004507L, 38004006L),
  neurology = 38004479L
)
```

Generated columns:
- `addInpatients()`: `{s_name}_inpatient_admissions_{window_name}`
- `addOutpatientVisits()`: `{s_name}_visits_{window_name}`
- `addEmergencyCare()`: `{s_name}_emergency_visits_{window_name}`
- `addVisits()`: produces all relevant specialty columns for active settings.

---

## 4. `addVisits()` Orchestration Strategy

### Decision
`addVisits()` is implemented by coordinating the modular verbs (`addInpatients`, `addOutpatientVisits`, and `addEmergencyCare`) sequentially or within a combined query pipeline, passing down user-configured windows, specialty mappings, and concept IDs.

### Rationale
- Reuses validated logic from individual domain enrichers.
- Provides a clean, single-call interface for common baseline and follow-up table generation.
- Guarantees identical metric definitions between individual calls and composite calls.
