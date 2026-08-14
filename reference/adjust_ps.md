# Adjust Propensity Scores (Stage 3: Causal Adjustment)

`adjust_ps()` applies a matching algorithm based on the propensity
scores calculated by [`fit_ps()`](fit_ps.md).

By default, it performs greedy nearest-neighbor caliper matching. This
pairs patients in the target cohort with similar patients in the
comparator cohort, discarding unmatched patients. The resulting matched
population is less biased and suitable for generating the transition
probabilities and costs used in the economic simulation.

## Usage

``` r
adjust_ps(ps_obj, caliper = 0.2, ...)
```

## Arguments

- ps_obj:

  A `hermes_ps` object returned by [`fit_ps()`](fit_ps.md).

- caliper:

  A numeric value specifying the maximum allowed distance between
  matched propensity scores. Default is 0.2.

- ...:

  Additional arguments passed to the matching function.

## Value

A `hermes_ps` object updated with a `matched_pop` attribute containing
the matched cohort.
