# Run Cost-Effectiveness Analysis (Stage 6: Decision Analysis)

`run_cea()` calculates the core metrics of a Cost-Effectiveness Analysis
based on the outputs of the economic simulation.

It wraps the `BCEA` (Bayesian Cost-Effectiveness Analysis) package to
process the matrix of simulated costs and effects (QALYs). The resulting
object can be used to compute the Incremental Cost-Effectiveness Ratio
(ICER) and Net Monetary Benefit (NMB), and to generate standard HEOR
plots.

## Usage

``` r
run_cea(hermes_sim)
```

## Arguments

- hermes_sim:

  A `hermes_sim` object output by
  [`simulate_economics()`](simulate_economics.md).

## Value

A `hermes_cea` object containing the full BCEA results.
