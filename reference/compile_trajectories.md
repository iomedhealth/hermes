# Compile State Trajectories and Costs (Stage 4: Trajectory Compilation)

`compile_trajectories()` aggregates the longitudinal patient timelines
from the matched cohorts into discrete health states and calculates
transition probabilities.

To run a Markov model for economic simulation, we need to know the
probability of a patient moving from one state (e.g., 'Baseline') to
another (e.g., 'Outcome'). This function calculates those probabilities
empirically from the OMOP data. It also aggregates the total costs
incurred by patients while residing in each specific health state.

## Usage

``` r
compile_trajectories(ps_obj)
```

## Arguments

- ps_obj:

  A `hermes_ps` object containing the matched population and cost data.

## Value

A `hermes_trajectories` object containing transition matrices and
state-specific cost summaries.
