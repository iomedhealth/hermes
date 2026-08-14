# Plot Cost-Effectiveness Plane

Generates a Cost-Effectiveness Plane scatter plot. The plot shows the
difference in effects (Incremental QALYs) on the x-axis and the
difference in costs (Incremental Costs) on the y-axis for each PSA
sample.

![](figures/ceplane.png)

## Usage

``` r
plot_plane(study)
```

## Arguments

- study:

  A `hermes_cea` object.

## Value

A `ggplot2` object representing the CE plane.
