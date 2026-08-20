# API Contract: Inpatient, Emergency Care, and Unified Visit Enrichers

This contract formalizes the R function signatures, argument types, defaults, and return behaviors for `addInpatients`, `addEmergencyCare`, `addVisits`, and their aliases.

---

## 1. `addInpatients` (and alias `addHospitalizations`, `addInpatient`)

```r
addInpatients(
  x,
  indexDate = "cohort_start_date",
  censorDate = NULL,
  window = list(c(-365, -1), c(0, 365)),
  visitConceptIds = c(9201L, 8717L, 581379L),
  icuConceptIds = 32037L,
  icuSpecialtyConceptIds = c(38004500L),
  stratifySpecialty = FALSE,
  specialties = NULL,
  readmissions = FALSE,
  nameStyle = "{domain}_{metric}_{window_name}",
  name = NULL
)
```

### Arguments
| Argument | Type | Default | Description |
|---|---|---|---|
| `x` | `cohort_table` / `cdm_table` | *required* | Input cohort table. |
| `indexDate` | `character(1)` | `"cohort_start_date"` | Column anchoring observation window. |
| `censorDate` | `character(1)` or `NULL` | `NULL` | Optional censoring date column in `x`. |
| `window` | `list` of numeric vectors | `list(c(-365, -1), c(0, 365))` | Named/unnamed relative time windows. |
| `visitConceptIds` | `integer` vector | `c(9201L, 8717L, 581379L)` | Inpatient stay OMOP concept IDs. |
| `icuConceptIds` | `integer` vector | `32037L` | ICU stay OMOP concept IDs. |
| `icuSpecialtyConceptIds` | `integer` vector | `c(38004500L)` | Provider specialty concept IDs for ICU. |
| `stratifySpecialty` | `logical(1)` | `FALSE` | Enable specialty breakdown. |
| `specialties` | `list` of integer vectors | `NULL` | Named list of specialty concept IDs. |
| `readmissions` | `logical(1)` | `FALSE` | Whether to compute 30d/90d readmissions. |
| `nameStyle` | `character(1)` | `"{domain}_{metric}_{window_name}"` | Column naming pattern. |
| `name` | `character(1)` or `NULL` | `NULL` | Target database table name. |

### Output Columns
- `inpatient_admissions_{window_name}`: Integer count of general inpatient admissions.
- `inpatient_los_days_{window_name}`: Cumulative days spent in inpatient stays.
- `icu_admissions_{window_name}`: Integer count of ICU admissions.
- `icu_los_days_{window_name}`: Cumulative days spent in ICU stays.
- `readmissions_30d_{window_name}` / `readmissions_90d_{window_name}` (if `readmissions = TRUE`).
- `{s_name}_inpatient_admissions_{window_name}` (if `specialties` provided).

---

## 2. `addEmergencyCare` (and alias `addEmergency`, `addEmergencyVisits`)

```r
addEmergencyCare(
  x,
  indexDate = "cohort_start_date",
  censorDate = NULL,
  window = list(c(-365, -1), c(0, 365)),
  emergencyVisitConceptIds = c(9203L, 262L, 581478L),
  emergencySpecialtyConceptIds = c(38004510L),
  stratifySpecialty = FALSE,
  specialties = NULL,
  nameStyle = "emergency_visits_{window_name}",
  name = NULL
)
```

### Arguments
| Argument | Type | Default | Description |
|---|---|---|---|
| `x` | `cohort_table` / `cdm_table` | *required* | Input cohort table. |
| `indexDate` | `character(1)` | `"cohort_start_date"` | Column anchoring observation window. |
| `censorDate` | `character(1)` or `NULL` | `NULL` | Optional censoring date column in `x`. |
| `window` | `list` of numeric vectors | `list(c(-365, -1), c(0, 365))` | Named/unnamed relative time windows. |
| `emergencyVisitConceptIds` | `integer` vector | `c(9203L, 262L, 581478L)` | Emergency room visit concept IDs. |
| `emergencySpecialtyConceptIds` | `integer` vector | `c(38004510L)` | Emergency medicine provider specialty IDs. |
| `stratifySpecialty` | `logical(1)` | `FALSE` | Enable specialty breakdown. |
| `specialties` | `list` of integer vectors | `NULL` | Named list of specialty concept IDs. |
| `nameStyle` | `character(1)` | `"emergency_visits_{window_name}"` | Column naming pattern. |
| `name` | `character(1)` or `NULL` | `NULL` | Target database table name. |

### Output Columns
- `emergency_visits_{window_name}`: Count of emergency encounters (matched by visit concept ID OR emergency provider specialty).
- `{s_name}_emergency_visits_{window_name}`: Count of emergency encounters attended by specific medical specialists.

---

## 3. `addVisits`

```r
addVisits(
  x,
  indexDate = "cohort_start_date",
  censorDate = NULL,
  window = list(c(-365, -1), c(0, 365)),
  settings = c("inpatient", "outpatient", "emergency"),
  stratifySpecialty = TRUE,
  gpSpecialtyConceptIds = c(38004446L),
  icuSpecialtyConceptIds = c(38004500L),
  emergencySpecialtyConceptIds = c(38004510L),
  specialties = NULL,
  inpatientVisitConceptIds = c(9201L, 8717L, 581379L),
  outpatientVisitConceptIds = c(9202L, 581477L),
  emergencyVisitConceptIds = c(9203L, 262L, 581478L),
  icuConceptIds = 32037L,
  readmissions = FALSE,
  name = NULL
)
```

### Arguments
| Argument | Type | Default | Description |
|---|---|---|---|
| `x` | `cohort_table` / `cdm_table` | *required* | Input cohort table. |
| `settings` | `character` vector | `c("inpatient", "outpatient", "emergency")` | Care settings to enrich. |
| `stratifySpecialty` | `logical(1)` | `TRUE` | Enable specialty stratification across settings. |
| `specialties` | `list` of integer vectors | `NULL` | Granular specialty list mapped across domains. |
| `readmissions` | `logical(1)` | `FALSE` | Compute readmission metrics for inpatient stays. |

### Output Columns
Appends columns corresponding to all selected `settings` in a single unified table.
