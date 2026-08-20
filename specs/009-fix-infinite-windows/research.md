# Technical Research & Design Decisions: Infinite & Open-Ended Windows

## 1. Database Identifier Case-Folding in CDM Table Registration

### Decision
Generate all auto-derived window names in 100% lowercase `snake_case` (e.g., `"0_to_inf"`, `"minf_to_0"`, `"minf_to_inf"`), and convert any user-supplied window names via `tolower()`.

### Rationale
Database engines (such as DuckDB, PostgreSQL, Amazon Redshift, and Snowflake) case-fold unquoted SQL column names to lowercase. When `omopgenerics::insertTable()` writes a table to the database, `CDMConnector` attempts to select the exact column names present on the original R data frame. If the R data frame used `"0_to_Inf"` (with uppercase `I`), `dplyr::select` fails with `Can't select columns that don't exist`. Enforcing all-lowercase suffixes eliminates this error across all backends.

---

## 2. `NA` and `Inf` Normalization Strategy

### Decision
In `validateWindow()`:
- If element 1 is `NA`, replace with `-Inf`.
- If element 2 is `NA`, replace with `Inf`.
- Accept both `c(0, Inf)` and `c(0, NA)` interchangeably as valid interval syntax.

### Rationale
This matches the established convention in `PatientProfiles::addIntersect()` and standard OHDSI/DARWIN EU workflows where `c(0, NA)` represents follow-up to end of records.

---

## 3. Safe Date Arithmetic in Window Queries

### Decision
When computing date boundaries:
- `win_start_dt = if (is.infinite(w_start)) as.Date("1800-01-01") else as.Date(.data[[indexDate]] + w_start)`
- `win_end_dt = if (is.infinite(w_end)) as.Date("2099-12-31") else as.Date(.data[[indexDate]] + w_end)`
- `actual_end_dt = if (!is.null(censorDate)) { if (is.infinite(w_end)) .data$cens_dt else pmin(.data$win_end_dt, .data$cens_dt, na.rm = TRUE) } else .data$win_end_dt`

### Rationale
Avoids arithmetic errors or warnings when adding `Inf` directly to `Date` objects in different R environments and guarantees safe evaluation in `difftime()` and `pmin()`.
