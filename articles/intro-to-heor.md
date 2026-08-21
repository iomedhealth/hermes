# Introduction to HEOR for OMOP Users

## Welcome to HERMES

If you are reading this, you are likely familiar with the Observational
Medical Outcomes Partnership (OMOP) Common Data Model (CDM) and the
OHDSI ecosystem. You know how to define cohorts, run incidence rate
analyses, and perhaps perform population-level effect estimation.

**HERMES** (Health Economic Resource Modeling & Evaluation System)
bridges the gap between the OMOP world and **Health Economics and
Outcomes Research (HEOR)**. This guide will help translate the concepts
you already know into the framework of Cost-Effectiveness Analysis
(CEA).

## What is HEOR and CEA?

When a new drug or intervention enters the market, regulatory bodies
(like the FDA or EMA) care about *safety and efficacy*. However,
healthcare payers (governments, insurance companies, Health Technology
Assessment (HTA) bodies like NICE in the UK) ask a different question:
**“Is this new treatment worth the extra money?”**

**Cost-Effectiveness Analysis (CEA)** is the formal mathematical process
used to answer that question. It compares the relative costs and
outcomes (effects) of different courses of action.

### The Key Metrics: ICER and QALY

To compare apples to apples across different diseases, health economists
use standardized metrics:

1.  **QALY (Quality-Adjusted Life-Year)**: A measure of disease burden,
    including both the quality and the quantity of life lived. One QALY
    equates to one year in perfect health.
2.  **ICER (Incremental Cost-Effectiveness Ratio)**: The core output of
    a CEA. It represents the additional cost per additional unit of
    health gained (usually per QALY).

``` math
 ICER = \frac{Cost_{Target} - Cost_{Comparator}}{Effect_{Target} - Effect_{Comparator}} 
```

If a new drug costs \$50,000 more than the standard of care but provides
1 additional QALY, the ICER is \$50,000/QALY. Payers have a
“Willingness-to-Pay” (WTP) threshold (e.g., \$100,000/QALY). If the ICER
is below the threshold, the drug is considered cost-effective.

## The Rosetta Stone: OMOP to HEOR

How do we build these economic models using observational data in the
OMOP CDM? We map OHDSI concepts to HEOR concepts.

| OMOP / OHDSI Concept | HEOR / CEA Concept | HERMES Stage | Package Responsible |
|:---|:---|:---|:---|
| **Target Cohort** (e.g., new users of Drug A) | **Treatment Arm** (The new intervention being evaluated) | Stage 1 | `CohortEconomics` ([`init()`](https://rdrr.io/pkg/CohortEconomics/man/init.html)) |
| **Comparator Cohort** (e.g., new users of Drug B) | **Standard of Care Arm** (The baseline intervention) | Stage 1 | `CohortEconomics` ([`init()`](https://rdrr.io/pkg/CohortEconomics/man/init.html)) |
| **Demographics & Covariates** (Age, sex, comorbidities) | **Patient Characteristics & Confounders** | Stage 2 & 3 | `CohortEconomics` ([`summarise_baseline()`](https://rdrr.io/pkg/CohortEconomics/man/summarise_baseline.html), [`fit_ps()`](https://rdrr.io/pkg/CohortEconomics/man/fit_ps.html)) |
| **Care Encounters & Prescriptions** (Visits, drugs, procedures) | **Healthcare Resource Utilization (HCRU)** | Stage 2 | `CohortUtilisation` ([`addVisits()`](https://rdrr.io/pkg/CohortUtilisation/man/addVisits.html), [`addPrescriptions()`](https://rdrr.io/pkg/CohortUtilisation/man/addPrescriptions.html), [`addProcedures()`](https://rdrr.io/pkg/CohortUtilisation/man/addProcedures.html)) |
| **COST Table** (Total paid, charge, allowed) | **Direct Medical Costs & Tariffs** | Stage 2 & 4 | `CohortCosts` ([`addCosts()`](https://rdrr.io/pkg/CohortCosts/man/addCosts.html)) / `CohortEconomics` ([`extract_hcru()`](https://rdrr.io/pkg/CohortEconomics/man/extract_hcru.html)) |
| **Outcome Cohorts** (e.g., stroke, disease progression) | **Health States / Clinical Events** | Stage 4 | `CohortEconomics` ([`compile_trajectories()`](https://rdrr.io/pkg/CohortEconomics/man/compile_trajectories.html)) |
| **Longitudinal Transitions** (Markov model matrices) | **State-Transition Simulation** | Stage 5 | `CohortEconomics` ([`simulate_economics()`](https://rdrr.io/pkg/CohortEconomics/man/simulate_economics.html)) |
| **Incremental Costs & Effects** (PSA iterations) | **Decision Analysis (ICER, CEAC, NMB)** | Stage 6 | `CohortEconomics` ([`run_cea()`](https://rdrr.io/pkg/CohortEconomics/man/run_cea.html), [`plot_ceac()`](https://rdrr.io/pkg/CohortEconomics/man/plot_ceac.html)) |

## The HERMES 6-Stage Pipeline

To get from raw OMOP data to a finalized ICER and decision-analytic
plots, HERMES enforces a strict 6-stage pipeline:

### 1. Cohort Generation (`init()`)

You define your `target_cohort`, `comparator_cohort`, and
`outcome_cohort` using standard OHDSI tools (like Atlas, Capr, or
CohortConstructor) and instantiate them in the database.

### 2. Descriptive Baseline & HCRU Characterization (`summarise_baseline()`, `extract_hcru()`)

HERMES profiles the cohorts, extracting demographics and calculating
unadjusted care utilization (hospitalizations, outpatient visits) and
direct medical costs by directly querying the OMOP `COST` table.

### 3. Causal Propensity Score (PS) Adjustment (`fit_ps()`, `adjust_ps()`, `assess_balance()`)

Observational data is biased. Patients prescribed the new expensive drug
might be sicker (or healthier) than those on the standard of care.
HERMES uses high-dimensional regularized logistic regression (via
`Cyclops`) to calculate Propensity Scores and match/weight the cohorts,
creating a pseudo-randomized population.

### 4. Trajectory Compilation & State-Cost Extraction (`compile_trajectories()`)

Patient timelines are sliced into discrete time cycles (e.g., months).
HERMES tracks how patients transition between different health states
(e.g., from “Healthy” to “Outcome Event” to “Dead”) and extracts the
specific costs accrued while in those states.

### 5. Economic Simulation (`simulate_economics()`)

Using the transition probabilities and cost distributions derived in
Stage 4, HERMES simulates a decision-analytic Markov model. This
projects the long-term costs and QALYs over a lifetime horizon with
probabilistic sensitivity analysis (PSA).

### 6. Decision Analysis & Post-Processing (`run_cea()`, `plot_ceac()`, `plot_plane()`)

Finally, HERMES calculates the ICER and Net Monetary Benefit (NMB),
generating standardized visualizations like the Cost-Effectiveness Plane
and the Cost-Effectiveness Acceptability Curve (CEAC), powered by
`BCEA`.

## Next Steps

- **[The HERMES Ecosystem & Modular
  Suite](https://iomedhealth.github.io/omopHeor/articles/hermes-ecosystem.md)**:
  Overview of the 3 standalone packages and architecture.
- **[Cohort Utilization & Cost
  Enrichment](https://iomedhealth.github.io/omopHeor/articles/cohort-utilization.md)**:
  Deep dive into the 3-layer in-database cohort enrichers.
- **[HCRU Extraction
  Logic](https://iomedhealth.github.io/omopHeor/articles/hcru_logic.md)**:
  Technical rules for OMOP `COST` table linkage and zero-fill fallbacks.
