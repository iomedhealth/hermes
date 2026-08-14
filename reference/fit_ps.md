# Fit Propensity Score Model (Stage 3: Causal Adjustment)

`fit_ps()` estimates the probability (propensity score) of a patient
being assigned to the target cohort versus the comparator cohort, based
on their baseline covariates (e.g., age, sex).

Because observational data lacks randomization, direct comparison
between treatments is often biased by confounding variables. Propensity
scores are used in HEOR to emulate a randomized controlled trial by
matching or weighting patients who have similar baseline
characteristics. This function currently uses regularized logistic
regression via the `Cyclops` package.

## Usage

``` r
fit_ps(hcru_obj, ...)
```

## Arguments

- hcru_obj:

  A `hermes_hcru` object containing the cohort data.

- ...:

  Additional arguments passed to the underlying model fitting functions.

## Value

A `hermes_ps` object containing the propensity score model and covariate
data.
