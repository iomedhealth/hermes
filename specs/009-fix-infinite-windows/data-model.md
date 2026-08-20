# Data Model: Window Normalization & Infinite Bounds

## 1. Window Structures & Normalization Rules

### 1.1 Input Window Vector
A 2-element numeric or NA vector: `c(start, end)`.

| Input Pattern | Evaluated `start` | Evaluated `end` | Generated Column Suffix |
|---|---|---|---|
| `c(-365, -1)` | `-365` | `-1` | `"m365_to_m1"` |
| `c(0, 365)` | `0` | `365` | `"0_to_365"` |
| `c(0, Inf)` | `0` | `Inf` | `"0_to_inf"` |
| `c(0, NA)` | `0` | `Inf` | `"0_to_inf"` |
| `c(-Inf, 0)` | `-Inf` | `0` | `"minf_to_0"` |
| `c(NA, 0)` | `-Inf` | `0` | `"minf_to_0"` |
| `c(-Inf, Inf)` | `-Inf` | `Inf` | `"minf_to_inf"` |
| `c(NA, NA)` | `-Inf` | `Inf` | `"minf_to_inf"` |

---

## 2. Enriched Output Column Names

All auto-generated column names conform to:
- `inpatient_admissions_0_to_inf`
- `inpatient_los_days_0_to_inf`
- `icu_admissions_0_to_inf`
- `emergency_visits_0_to_inf`
- `gp_visits_0_to_inf`
- `specialist_visits_0_to_inf`
- `rx_fills_0_to_inf`
- `days_supply_0_to_inf`
- `cost_total_0_to_inf`
