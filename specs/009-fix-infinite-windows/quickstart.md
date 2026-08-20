# Quickstart: Infinite & Open-Ended Windows

```r
library(HERMES)
library(dplyr)

cdm <- hermesTestCdm()

# 1. Whole follow-up window using c(0, Inf)
cohortInp <- cdm$target_cohort |>
  addInpatients(window = c(0, Inf))

# Returns columns:
# - inpatient_admissions_0_to_inf
# - inpatient_los_days_0_to_inf
# - icu_admissions_0_to_inf
# - icu_los_days_0_to_inf

# 2. Named full follow-up window using c(0, NA)
cohortVisits <- cdm$target_cohort |>
  addVisits(
    window = list(
      baseline = c(-365, -1),
      allFollowup = c(0, NA)
    )
  )

# 3. Lifetime history using c(-Inf, Inf)
cohortCosts <- cdm$target_cohort |>
  addCosts(window = c(-Inf, Inf))
```
