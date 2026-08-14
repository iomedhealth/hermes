# Summary Table

Returns a statistical summary table of the CEA results, detailing
incremental costs, incremental QALYs, and the ICER.

**Example Output:**

    Cost-effectiveness analysis summary

    Reference intervention: Strategy 1
    Comparator intervention: Strategy 2

    Optimal decision: Strategy 2

                     Strategy 1  Strategy 2
    Expected Costs   15000       18000
    Expected QALYs   12.5        13.1

    ICER: 5000 / QALY

## Usage

``` r
table_summary(study)
```

## Arguments

- study:

  A `hermes_cea` object
