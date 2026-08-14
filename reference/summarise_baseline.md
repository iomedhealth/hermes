# Summarise baseline demographics and comorbidities (Stage 2: Baseline)

`summarise_baseline()` computes unadjusted baseline characteristics for
the cohorts defined in the `hermes_study` object.

In HEOR, understanding the baseline characteristics of the Treatment and
Standard of Care arms is crucial. If the populations are systematically
different (e.g., the target cohort is much older or sicker), direct cost
or outcome comparisons will be biased. This function leverages
`PatientProfiles` and `CohortCharacteristics` to generate these
standardized summaries.

**Example Output Structure:**

    # A tibble: 5 × 4
      variable_name variable_level estimate_name estimate_value
      <chr>         <chr>          <chr>         <chr>
    1 Number records NA             count         1000
    2 Age           NA             mean          65.2
    3 Age           NA             sd            10.1
    4 Sex           Female         count         450
    5 Sex           Female         percentage    45.0

## Usage

``` r
summarise_baseline(study)
```

## Arguments

- study:

  A `hermes_study` object, typically the output of [`init()`](init.md).

## Value

A `hermes_hcru` S3 object containing the original study data plus a new
`baseline_summary` attribute.
