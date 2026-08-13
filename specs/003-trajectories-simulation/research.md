# Research & Technical Decisions: Stage 4 (Trajectories) and Stage 5 (Economic Simulation)

## 1. Trajectory State Extraction & Transition Matrix Calculation (Stage 4)

### Decision
Use `Cohort2Trajectory` / `TrajectoryMarkovAnalysis` concepts to aggregate longitudinal patient timelines into discrete, 30-day state cycles, computing transition probability matrices for Target vs. Comparator interventions.

### Rationale
- Transition matrices define discrete-time Markov health states: Initial/Treatment State, Outcome State, and Censored/Post-Outcome State.
- Computing 30-day transition probabilities from actual patient entry dates and outcome occurrence dates provides realistic cohort dynamics while avoiding hardcoded matrices.

### Fallback Matrix Derivation Pattern
If `Cohort2Trajectory` functions encounter sparse transitions, HERMES derives 30-day state transitions by evaluating whether matched cohort patients in `ps_obj$matched_pop` experience outcome events from `outcome_cohort`:
- $P(\text{Target/Comparator} \to \text{Outcome}) = \frac{\text{Patients with Outcome within 30 days}}{\text{Total Matched Patients}}$
- $P(\text{Target/Comparator} \to \text{Target/Comparator}) = 1 - P(\text{Target/Comparator} \to \text{Outcome})$
- $P(\text{Outcome} \to \text{Outcome}) = 1.0$ (or absorbing state)

---

## 2. Health-State Cost Grouping & Uncertainty Estimation (Stage 4)

### Decision
Group extracted costs from `ps_obj$hcru_obj$costs` by trajectory health states and compute parametric summary statistics:
- `mean_cost`: `mean(total_paid)`
- `se_cost`: `sd(total_paid) / sqrt(n)` (defaulting to 0 when $n \le 1$)

### Rationale
- Standard probabilistic economic modeling requires both point estimates (mean) and variance/standard error metrics to define prior cost distributions (Gamma/Lognormal) for PSA sampling.

---

## 3. Probabilistic Sensitivity Analysis (PSA) Markov Engine (Stage 5)

### Decision
Replace `rnorm()` mocks with a true PSA Markov simulation engine (using `hesim` or a standard parametric Markov cohort sampler):
- Transition probabilities sampled via Dirichlet / Beta distributions derived from transition counts/probabilities.
- State costs sampled via Gamma distributions matching state `mean_cost` and `se_cost`.
- Health state utilities (QALY weights) sampled via Beta distributions (e.g. Target/Baseline state mean = 0.85, Outcome state mean = 0.70).
- Discounting applied over the specified time horizon (default 10 years, 3% annual discount rate).

### Output Structure
The engine produces a `hesim_ce` list containing two data frames:
1. `costs`: `sample`, `strategy_id`, `costs`
2. `qalys`: `sample`, `strategy_id`, `qalys`

This structure directly feeds into Stage 6 (`run_cea()`), enabling `stats::xtabs()` matrix conversion without data transformation errors.

---

## 4. Test Fixture Financial Data Injection (User Story 3)

### Decision
Update `helper-eunomia.R` (and test setup scripts) to populate the `cost` table in the Eunomia DuckDB instance with synthetic financial events tied to condition occurrence dates for Target (Colon Polyp), Comparator (Diverticular Disease), and Outcome (GI Bleed) cohorts.

### Rationale
- Running tests against DuckDB without mocked internal return values ensures end-to-end integration integrity across Stage 1 through Stage 6.
