# API Contract: DARWIN EU-Aligned Cohort Utilization Functions

## 1. Episode Cohort Constructors (`CohortConstructor` Style)

### 1.1 `computeHospitalizationCohorts`

```r
computeHospitalizationCohorts(
  cdm,
  name,
  visitConceptIds = c(9201L, 8717L, 581379L),
  icuConceptIds = c(32037L),
  readmissionWindow = 30L
)
```
- **Arguments**:
  - `cdm`: A `cdm_reference` object.
  - `name`: Character string for the new cohort table name in the CDM write schema.
  - `visitConceptIds`: Integer vector of OMOP visit concept IDs for general inpatient stays.
  - `icuConceptIds`: Integer vector of OMOP visit concept IDs for ICU stays.
  - `readmissionWindow`: Integer scalar; days gap between discharge and next admission to flag readmission.
- **Returns**: An `omopgenerics::cohort_table` object stored in `cdm[[name]]`.

---

### 1.2 `computeInfusionCohorts`

```r
computeInfusionCohorts(
  cdm,
  name,
  conceptSet = NULL,
  routeConceptIds = c(4171047L, 4171048L),
  collapseGap = 0L
)
```
- **Arguments**:
  - `cdm`: A `cdm_reference` object.
  - `name`: Character string for the new cohort table name in the CDM write schema.
  - `conceptSet`: Optional concept set / codelist of specific infused drugs.
  - `routeConceptIds`: Integer vector of OMOP route concept IDs (e.g. IV, parenteral).
  - `collapseGap`: Integer scalar; days gap allowed when collapsing consecutive administration records.
- **Returns**: An `omopgenerics::cohort_table` object stored in `cdm[[name]]`.

---

## 2. Cohort Enrichers (`PatientProfiles` Style)

### 2.1 `addHospitalizations`

```r
addHospitalizations(
  x,
  indexDate = "cohort_start_date",
  censorDate = NULL,
  window = list(c(-365, -1), c(0, 365)),
  visitConceptIds = c(9201L, 8717L, 581379L),
  icuConceptIds = c(32037L),
  readmissions = FALSE,
  nameStyle = "{domain}_{metric}_{window_name}",
  name = NULL
)
```
- **Arguments**:
  - `x`: A cohort table reference.
  - `indexDate`: Character string; date column in `x` to anchor windows (default `"cohort_start_date"`).
  - `censorDate`: Optional character string; date column in `x` to censor observation.
  - `window`: Named or unnamed list of numeric pairs specifying day intervals relative to `indexDate`.
  - `visitConceptIds`: Integer vector of OMOP inpatient visit concept IDs.
  - `icuConceptIds`: Integer vector of OMOP ICU visit concept IDs.
  - `readmissions`: Logical; whether to compute 30-day and 90-day readmission counts.
  - `nameStyle`: Character string; glue pattern for naming added columns.
  - `name`: Optional character string; table name in write schema (if NULL, creates temporary table).
- **Returns**: The input cohort table `x` enriched with inpatient metrics.

---

### 2.2 `addOutpatientVisits`

```r
addOutpatientVisits(
  x,
  indexDate = "cohort_start_date",
  censorDate = NULL,
  window = list(c(-365, -1), c(0, 365)),
  stratifySpecialty = TRUE,
  gpSpecialtyConceptIds = c(38004446L),
  nameStyle = "{setting}_visits_{window_name}",
  name = NULL
)
```
- **Arguments**:
  - `x`: A cohort table reference.
  - `indexDate`: Character string; index date column.
  - `censorDate`: Optional censoring date column.
  - `window`: List of numeric pairs for temporal windows.
  - `stratifySpecialty`: Logical; whether to partition outpatient visits by GP vs. Specialist vs. ED.
  - `gpSpecialtyConceptIds`: Integer vector of OMOP provider specialty concept IDs for General Practice.
  - `nameStyle`: Character string glue pattern.
  - `name`: Optional table name in write schema.
- **Returns**: The input cohort table `x` enriched with outpatient visit counts.

---

### 2.3 `addPrescriptions`

```r
addPrescriptions(
  x,
  indexDate = "cohort_start_date",
  censorDate = NULL,
  window = list(c(-365, -1), c(0, 365)),
  conceptSet = NULL,
  infusionRouteConceptIds = c(4171047L, 4171048L),
  daysSupply = TRUE,
  pdc = FALSE,
  nameStyle = "{metric}_{window_name}",
  name = NULL
)
```
- **Arguments**:
  - `x`: A cohort table reference.
  - `indexDate`: Character string; index date column.
  - `censorDate`: Optional censoring date column.
  - `window`: List of numeric pairs for temporal windows.
  - `conceptSet`: Optional codelist to restrict drug exposures.
  - `infusionRouteConceptIds`: Integer vector of route concept IDs to isolate infusions.
  - `daysSupply`: Logical; whether to aggregate cumulative days supply.
  - `pdc`: Logical; whether to compute Proportion of Days Covered (PDC).
  - `nameStyle`: Character string glue pattern.
  - `name`: Optional table name in write schema.
- **Returns**: The input cohort table `x` enriched with prescription metrics.

---

### 2.4 `addProcedures`

```r
addProcedures(
  x,
  indexDate = "cohort_start_date",
  censorDate = NULL,
  window = list(c(-365, -1), c(0, 365)),
  labConceptSet = NULL,
  imagingConceptSet = NULL,
  procedureConceptSet = NULL,
  nameStyle = "{metric}_count_{window_name}",
  name = NULL
)
```
- **Arguments**:
  - `x`: A cohort table reference.
  - `indexDate`: Character string; index date column.
  - `censorDate`: Optional censoring date column.
  - `window`: List of numeric pairs for temporal windows.
  - `labConceptSet`: Optional codelist for laboratory tests in `measurement`.
  - `imagingConceptSet`: Optional codelist for imaging scans in `procedure_occurrence`.
  - `procedureConceptSet`: Optional codelist for procedures in `procedure_occurrence`.
  - `nameStyle`: Character string glue pattern.
  - `name`: Optional table name in write schema.
- **Returns**: The input cohort table `x` enriched with diagnostic and procedure counts.

---

### 2.5 `addCosts`

```r
addCosts(
  x,
  indexDate = "cohort_start_date",
  censorDate = NULL,
  window = list(c(-365, -1), c(0, 365)),
  costField = "total_paid",
  domains = c("Inpatient", "Outpatient", "Drug", "Procedure"),
  nameStyle = "cost_{domain}_{window_name}",
  name = NULL
)
```
- **Arguments**:
  - `x`: A cohort table reference.
  - `indexDate`: Character string; index date column.
  - `censorDate`: Optional censoring date column.
  - `window`: List of numeric pairs for temporal windows.
  - `costField`: Character string; cost column in `cost` table (`"total_paid"`, `"total_charge"`, `"paid_by_payer"`, etc.).
  - `domains`: Character vector of OMOP clinical domains to include.
  - `nameStyle`: Character string glue pattern.
  - `name`: Optional table name in write schema.
- **Returns**: The input cohort table `x` enriched with domain-specific and total direct costs.

---

## 3. Analytics & Reporting (`CohortCharacteristics` Style)

### 3.1 `summariseUtilization`

```r
summariseUtilization(
  cohort,
  strata = list(),
  estimates = c("mean", "sd", "median", "q25", "q75", "min", "max", "count", "percentage")
)
```
- **Arguments**:
  - `cohort`: An enriched cohort table containing utilization columns.
  - `strata`: List of character vectors specifying stratification variables (e.g., `list("sex", c("age_group", "sex"))`).
  - `estimates`: Character vector of summary estimators to calculate.
- **Returns**: An `omopgenerics::summarised_result` tibble.

---

### 3.2 `summariseCosts`

```r
summariseCosts(
  cohort,
  strata = list(),
  costColumns = NULL,
  estimates = c("mean", "sd", "median", "q25", "q75", "min", "max")
)
```
- **Arguments**:
  - `cohort`: An enriched cohort table containing cost columns.
  - `strata`: List of character vectors specifying stratification variables.
  - `costColumns`: Character vector of cost columns to summarise (default: all columns starting with `cost_`).
  - `estimates`: Character vector of summary estimators.
- **Returns**: An `omopgenerics::summarised_result` tibble.

---

### 3.3 `tableUtilization` & `tableCosts`

```r
tableUtilization(
  result,
  type = "gt",
  header = c("strata", "estimate")
)

tableCosts(
  result,
  type = "gt",
  header = c("strata", "estimate")
)
```
- **Arguments**:
  - `result`: A `summarised_result` object.
  - `type`: Output table type (`"gt"`, `"flextable"`, `"tibble"`).
  - `header`: Columns to place in table header.
- **Returns**: A formatted GT table, flextable, or tibble.
