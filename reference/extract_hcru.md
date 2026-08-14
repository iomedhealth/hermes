# Extract Healthcare Resource Utilization (HCRU) from the OMOP COST table (Stage 2: HCRU)

`extract_hcru()` queries the OMOP CDM `cost` table to extract direct
medical costs and resource utilization associated with the patients in
the study cohorts.

In Cost-Effectiveness Analysis (CEA), Healthcare Resource Utilization
(HCRU) forms the numerator of the Incremental Cost-Effectiveness Ratio
(ICER). This function safely handles edge cases (like missing tables or
masked financial values) and tags costs with the patient's health state
at the time the cost was incurred (e.g., before or after the outcome
event).

**Example Output Structure:**

    # A tibble: 5 × 5
      subject_id total_paid total_charge condition_concept_id health_state
           <int>      <dbl>        <dbl>                <int> <chr>
    1        101       150.         300.               317009 State_Baseline
    2        101       450.         900.               317009 State_Outcome
    3        102      1200.        2400.               432904 State_Baseline

## Usage

``` r
extract_hcru(study)
```

## Arguments

- study:

  A `hermes_study` or `hermes_hcru` object.

## Value

A `hermes_hcru` object enriched with raw, patient-level cost data.

## See also

See [`vignette("hcru_logic")`](../articles/hcru_logic.md) for the
complete ASCII flow diagram of the extraction logic.
