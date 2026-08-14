# Assess Covariate Balance (Stage 3: Causal Adjustment)

`assess_balance()` calculates the Standardized Mean Differences (SMD)
for covariates before and after propensity score matching.

In HEOR, this is a critical diagnostic step. A well-specified propensity
score model should balance the baseline covariates between the treatment
and comparator arms, resulting in SMDs close to zero (typically \< 0.1).

## Usage

``` r
assess_balance(ps_obj, ...)
```

## Arguments

- ps_obj:

  A `hermes_ps` object returned by [`adjust_ps()`](adjust_ps.md).

- ...:

  Additional arguments.

## Value

A `hermes_ps` object updated with an `smd_summary` attribute.
