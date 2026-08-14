# Simulate Economic Outcomes (Stage 5: Economic Simulation)

`simulate_economics()` runs a Probabilistic Sensitivity Analysis (PSA)
using a Markov state-transition model.

CEA rarely relies on single deterministic values due to inherent
uncertainty in clinical data. This function runs thousands of
simulations (samples). In each sample, it draws transition
probabilities, costs, and health utility values from statistical
distributions (Dirichlet, Gamma, Beta). It then projects these values
over a specified time horizon to estimate the total long-term costs and
Quality-Adjusted Life-Years (QALYs) for both the target and comparator
strategies.

## Usage

``` r
simulate_economics(
  traj_obj,
  time_horizon = 10,
  discount_rate = 0.03,
  n_samples = 100
)
```

## Arguments

- traj_obj:

  A `hermes_trajectories` object containing transition and cost data.

- time_horizon:

  Numeric. The time horizon for the simulation in years (e.g., 10 for a
  10-year model, or ~80 for a lifetime horizon). Default is 10.

- discount_rate:

  Numeric. The annual discount rate applied to future costs and QALYs to
  reflect time preference. Default is 0.03 (3%).

- n_samples:

  Integer. The number of probabilistic iterations (PSA samples) to run.
  Default is 100.

## Value

A `hermes_sim` object containing the simulated total costs and QALYs
across all samples.
