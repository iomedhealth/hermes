# API Contract: Window Normalization and Infinite Bounds Support

## 1. `validateWindow` Specification

```r
validateWindow(window, call = parent.frame())
```

### Supported Window Inputs & Normalized Outputs

| Input Expression | Normalized Bound Vector `c(start, end)` | Auto-Generated Suffix `wName` |
|---|---|---|
| `c(-365, -1)` | `c(-365, -1)` | `"m365_to_m1"` |
| `c(0, 365)` | `c(0, 365)` | `"0_to_365"` |
| `c(0, Inf)` | `c(0, Inf)` | `"0_to_inf"` |
| `c(0, NA)` | `c(0, Inf)` | `"0_to_inf"` |
| `c(-Inf, 0)` | `c(-Inf, 0)` | `"minf_to_0"` |
| `c(NA, 0)` | `c(-Inf, 0)` | `"minf_to_0"` |
| `c(-Inf, Inf)` | `c(-Inf, Inf)` | `"minf_to_inf"` |
| `list(followup = c(0, Inf))` | `list(followup = c(0, Inf))` | `"followup"` |
| `list(allFollowup = c(0, NA))` | `list(all_followup = c(0, Inf))` | `"all_followup"` |

---

## 2. Generated Column Suffix Pattern

All auto-generated column suffixes conform to:
$$\text{col\_name} = \text{paste0}(\text{domain\_prefix}, \text{"\_"}, \text{tolower}(wName))$$

Examples:
- `inpatient_admissions_0_to_inf`
- `inpatient_los_days_0_to_inf`
- `emergency_visits_0_to_inf`
- `gp_visits_0_to_inf`
- `rx_fills_0_to_inf`
- `cost_total_0_to_inf`
