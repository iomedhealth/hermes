# Plot Cost-Effectiveness Acceptability Curve (CEAC)

Generates a CEAC plot based on the CEA results. The CEAC shows the
probability that an intervention is cost-effective across a range of
Willingness-to-Pay (WTP) thresholds. It is a standard way to represent
parametric uncertainty in HEOR.

![](figures/ceac.png)

## Usage

``` r
plot_ceac(study)
```

## Arguments

- study:

  A `hermes_cea` object.

## Value

A `ggplot2` object representing the CEAC.
