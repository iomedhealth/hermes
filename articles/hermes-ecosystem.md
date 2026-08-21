# The HERMES Ecosystem: Modular Architecture & Package Suite

## The HERMES Ecosystem

**HERMES** (Health Economic Resource Modeling & Evaluation System) is an
R package ecosystem developed by [IOMED](https://iomed.health) for
Real-World Evidence (RWE) and Health Economics and Outcomes Research
(HEOR) on observational healthcare data structured in the **OMOP Common
Data Model (CDM)**.

Starting in version 0.5.0, HERMES adopts a **modular monorepo
architecture** composed of three standalone domain packages under the
DARWIN EU standard, unified by the root `hermes` umbrella metapackage.

------------------------------------------------------------------------

### 1. Why a Modular Suite?

In real-world HEOR workflows, analytical tasks often fall into two
distinct paradigms:

1.  **Healthcare Resource Utilization & Direct Costing**:
    Epidemiologists and data scientists need to enrich OMOP cohorts with
    inpatient admissions, emergency care, outpatient visits,
    prescriptions, procedures, and claims costs in-database using
    lightweight dependencies.
2.  **Health Economics Modeling & Decision Simulation**: Health
    economists need causal propensity score matching, longitudinal
    health-state transitions, Markov microsimulations, and Bayesian
    Cost-Effectiveness Analysis (CEA) using specialized statistical
    packages (`Cyclops`, `BCEA`, `CohortMethod`).

Decoupling these domains allows users to install only the dependencies
required for their specific workflow while maintaining a single, unified
interface through the `hermes` metapackage.

``` text
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                                   OMOP CDM DATABASE                                    │
│  (visit_occurrence, provider, drug_exposure, procedure_occurrence, measurement, cost)  │
└────────────────────────────────────────────────────────────────────────────────────────┘
                                            │
                                            ▼
                    ┌───────────────────────────────────────────────┐
                    │               hermes Metapackage              │
                    │      (Unified entry point & re-exports)       │
                    └───────────────────────┬───────────────────────┘
                                            │
        ┌───────────────────────────────────┼───────────────────────────────────┐
        ▼                                   ▼                                   ▼
┌───────────────────────────┐   ┌───────────────────────────┐   ┌───────────────────────────┐
│     CohortUtilisation     │   │        CohortCosts        │   │      CohortEconomics      │
│  ───────────────────────  │   │  ───────────────────────  │   │  ───────────────────────  │
│  • Inpatient / ICU stays  │   │  • OMOP COST linkage      │   │  • Propensity Scores (PS) │
│  • Emergency care         │   │  • Domain expenditures    │   │  • State trajectories     │
│  • Outpatient visits      │   │  • Standardised summaries │   │  • Markov simulations     │
│  • Prescription adherence │   │  • Cost tables & plots    │   │  • CEA (ICER, CEAC, NMB)  │
│  • Diagnostic procedures  │   │                           │   │                           │
│  • Episode constructors   │   │                           │   │                           │
└───────────────────────────┘   └───────────────────────────┘   └───────────────────────────┘
```

------------------------------------------------------------------------

### 2. Technology Stack

| Layer | Technologies & Dependencies | Description |
|:---|:---|:---|
| **Language & Core** | `R (>= 4.1.0)`, `rlang`, `cli`, `glue` | Base R execution engine and tidy evaluation framework. |
| **OMOP / DARWIN EU** | `omopgenerics (>= 0.3.0)`, `CDMConnector (>= 1.4.0)`, `PatientProfiles`, `CohortConstructor`, `CohortCharacteristics`, `visOmopResults` | Database-agnostic cohort manipulation, patient profiling, and standardized result schemas. |
| **Database & SQL Engine** | `duckdb`, `dbplyr (>= 2.4.0)`, `DBI`, `dplyr (>= 1.1.0)` | High-performance in-database SQL translation and in-memory analytical querying. |
| **Causal & HEOR Engines** | `Cyclops`, `CohortMethod`, `hesim`, `BCEA`, `stats` | High-dimensional regularized logistic regression, Markov microsimulations, and Bayesian CEA. |
| **Reporting & Formatting** | `ggplot2`, `gt`, `flextable`, `tibble` | Publication-ready summary tables, cost-effectiveness acceptability curves, and planes. |
| **Tooling & Maintenance** | `testthat (>= 3.0.0)`, `pkgdown`, `knitr`, `rmarkdown`, `styler`, `lintr` | Monorepo package checking, continuous integration, and automated documentation. |

------------------------------------------------------------------------

### 3. Package 1: `CohortUtilisation`

**`CohortUtilisation`** is a standalone, lightweight package designed to
extract and quantify Healthcare Resource Utilization (HCRU) from OMOP
CDM databases without requiring economic modeling dependencies.

It implements a **3-layer architecture** aligned with DARWIN EU
standards (`CohortConstructor`, `PatientProfiles`,
`CohortCharacteristics`):

- **Layer 1: Care Episode Constructors** (`CohortConstructor` style):
  - [`computeHospitalizationCohorts()`](https://rdrr.io/pkg/CohortUtilisation/man/compute_hospitalization_cohorts.html):
    Collapses contiguous/overlapping inpatient stays and derives 30-day
    readmissions.
  - [`computeInfusionCohorts()`](https://rdrr.io/pkg/CohortUtilisation/man/computeInfusionCohorts.html):
    Identifies parenteral and intravenous therapy episodes.
- **Layer 2: In-Database Cohort Enrichers** (`PatientProfiles` style):
  - [`addInpatients()`](https://rdrr.io/pkg/CohortUtilisation/man/addInpatients.html)
    /
    [`addHospitalizations()`](https://rdrr.io/pkg/CohortUtilisation/man/addInpatients.html):
    Inpatient admissions, length of stay (LOS), ICU utilization, 30d/90d
    readmissions, and specialty breakdown.
  - [`addEmergencyCare()`](https://rdrr.io/pkg/CohortUtilisation/man/addEmergencyCare.html)
    /
    [`addEmergency()`](https://rdrr.io/pkg/CohortUtilisation/man/addEmergencyCare.html):
    Emergency encounters captured via visit concepts and Emergency
    Medicine provider specialties.
  - [`addOutpatientVisits()`](https://rdrr.io/pkg/CohortUtilisation/man/addOutpatientVisits.html):
    Primary care (GP), specialist, and other outpatient visits.
  - [`addVisits()`](https://rdrr.io/pkg/CohortUtilisation/man/addVisits.html):
    Composite multi-setting enricher covering Inpatient, Outpatient, and
    Emergency care in one call.
  - [`addPrescriptions()`](https://rdrr.io/pkg/CohortUtilisation/man/addPrescriptions.html):
    Medication fills, cumulative days supply, and Proportion of Days
    Covered (PDC).
  - [`addProcedures()`](https://rdrr.io/pkg/CohortUtilisation/man/addProcedures.html):
    Diagnostic measurements, laboratory tests, and clinical procedures.
- **Layer 3: Analytics & Reporting** (`CohortCharacteristics` style):
  - [`summariseUtilization()`](https://rdrr.io/pkg/CohortUtilisation/man/summariseUtilization.html):
    Aggregates metrics into standardized `summarised_result` objects.
  - [`tableUtilization()`](https://rdrr.io/pkg/CohortUtilisation/man/tableUtilization.html):
    Formats publication-ready tables with `gt`, `flextable`, or
    `tibble`.
  - [`plotUtilization()`](https://rdrr.io/pkg/CohortUtilisation/man/plotUtilization.html):
    Renders ggplot2 visualizations of utilization distributions.

#### Example: Cohort Enrichment

``` r

library(hermes)
library(dplyr)

# Load synthetic mock CDM
cdm <- mockHERMES()

# Enrich cohort across baseline [-365, -1] and 1-year follow-up [0, 365]
cdm$target_enriched <- cdm$target_cohort |>
  addVisits(
    window = list(baseline = c(-365, -1), followup = c(0, 365)),
    settings = c("inpatient", "outpatient", "emergency"),
    stratifySpecialty = TRUE,
    readmissions = TRUE
  ) |>
  addPrescriptions(
    window = list(followup = c(0, 365)),
    daysSupply = TRUE,
    pdc = TRUE,
    name = "target_enriched"
  )

# View enriched columns
colnames(cdm$target_enriched)
#>  [1] "cohort_definition_id"             "subject_id"                      
#>  [3] "cohort_start_date"                "cohort_end_date"                 
#>  [5] "inpatient_admissions_baseline"    "inpatient_los_days_baseline"     
#>  [7] "icu_admissions_baseline"          "icu_los_days_baseline"           
#>  [9] "readmissions_30d_baseline"        "readmissions_90d_baseline"       
#> [11] "inpatient_admissions_followup"    "inpatient_los_days_followup"     
#> [13] "icu_admissions_followup"          "icu_los_days_followup"           
#> [15] "readmissions_30d_followup"        "readmissions_90d_followup"       
#> [17] "gp_visits_baseline"               "specialist_visits_baseline"      
#> [19] "other_outpatient_visits_baseline" "gp_visits_followup"              
#> [21] "specialist_visits_followup"       "other_outpatient_visits_followup"
#> [23] "emergency_visits_baseline"        "emergency_visits_followup"       
#> [25] "rx_fills_followup"                "days_supply_followup"            
#> [27] "infusions_followup"               "pdc_followup"
```

------------------------------------------------------------------------

### 4. Package 2: `CohortCosts`

**`CohortCosts`** handles direct medical cost extraction by linking
polymorphic OMOP `COST` table records across clinical events
(`Condition`, `Visit`, `Drug`, `Procedure`, `Measurement`).

Key capabilities:

- **In-Database Cost Enrichment
  ([`addCosts()`](https://rdrr.io/pkg/CohortCosts/man/addCosts.html))**:
  - Appends windowed expenditure columns by domain (`cost_inpatient_*`,
    `cost_outpatient_*`, `cost_drug_*`, `cost_procedure_*`,
    `cost_total_*`).
  - Gracefully handles missing/empty cost tables with automatic
    zero-filling.
- **Cost Summarisation & Visualization**:
  - [`summariseCosts()`](https://rdrr.io/pkg/CohortCosts/man/summariseCosts.html):
    Aggregates patient expenditures into `summarised_result` tables.
  - [`tableCosts()`](https://rdrr.io/pkg/CohortCosts/man/tableCosts.html):
    Generates publication tables formatted with `gt` or `flextable`.
  - [`plotCosts()`](https://rdrr.io/pkg/CohortCosts/man/plotCosts.html):
    Produces grouped barplots and boxplots of cost distributions.

#### Example: Direct Medical Costing

``` r

# Add direct medical costs across follow-up
cdm$target_costed <- cdm$target_enriched |>
  addCosts(
    window = list(followup = c(0, 365)),
    costField = "total_paid",
    name = "target_costed"
  )

# Summarise expenditures
cost_summary <- summariseCosts(cdm$target_costed)

# Render formatted table
tableCosts(cost_summary, type = "tibble")
#> # A tibble: 17 × 4
#>    `Variable name`       `Variable level` `Estimate name` [header_name]Data so…¹
#>    <chr>                 <chr>            <chr>           <chr>                 
#>  1 number records        –                N               2                     
#>  2 number subjects       –                N               2                     
#>  3 cost_inpatient_follo… –                Mean (SD)       1,000.00 (1,414.21)   
#>  4 cost_inpatient_follo… –                Median (IQR)    1,000.00 (500.00 - 1,…
#>  5 cost_inpatient_follo… –                Min - Max       0.00 - 2,000.00       
#>  6 cost_outpatient_foll… –                Mean (SD)       0.00 (0.00)           
#>  7 cost_outpatient_foll… –                Median (IQR)    0.00 (0.00 - 0.00)    
#>  8 cost_outpatient_foll… –                Min - Max       0.00 - 0.00           
#>  9 cost_drug_followup    –                Mean (SD)       40.00 (56.57)         
#> 10 cost_drug_followup    –                Median (IQR)    40.00 (20.00 - 60.00) 
#> 11 cost_drug_followup    –                Min - Max       0.00 - 80.00          
#> 12 cost_procedure_follo… –                Mean (SD)       150.00 (212.13)       
#> 13 cost_procedure_follo… –                Median (IQR)    150.00 (75.00 - 225.0…
#> 14 cost_procedure_follo… –                Min - Max       0.00 - 300.00         
#> 15 cost_total_followup   –                Mean (SD)       1,765.00 (2,496.09)   
#> 16 cost_total_followup   –                Median (IQR)    1,765.00 (882.50 - 2,…
#> 17 cost_total_followup   –                Min - Max       0.00 - 3,530.00       
#> # ℹ abbreviated name:
#> #   ¹​`[header_name]Data source\n[header_level]An OMOP CDM database\n[header_name]Cohort name\n[header_level]cohort_1`
```

------------------------------------------------------------------------

### 5. Package 3: `CohortEconomics`

**`CohortEconomics`** is the core Health Economics and Outcomes Research
(HEOR) modeling package. It implements the complete **6-stage analytical
pipeline** from cohort definition to decision analysis:

``` mermaid
graph TD
    A[(OMOP CDM)] --> S1[Stage 1: Cohort Generation]
    S1 --> S2[Stage 2: Baseline & HCRU Characterization]
    S2 --> S3[Stage 3: Causal PS Adjustment]
    S3 --> S4[Stage 4: Trajectory Compilation]
    S4 --> S5[Stage 5: Economic Simulation]
    S5 --> S6[Stage 6: Decision Analysis CEA]
    
    S6 --> P1[CEAC Plot]
    S6 --> P2[CE Plane Plot]
    S6 --> P3[Summary Table]
```

1.  **Stage 1: Cohort Generation & Initialization**
    ([`init()`](https://rdrr.io/pkg/CohortEconomics/man/init.html)):
    Sets up target treatment, comparator, and clinical outcome cohorts.
2.  **Stage 2: Descriptive Baseline & HCRU Extraction**
    ([`summarise_baseline()`](https://rdrr.io/pkg/CohortEconomics/man/summarise_baseline.html),
    [`extract_hcru()`](https://rdrr.io/pkg/CohortEconomics/man/extract_hcru.html)):
    Computes demographics, baseline characteristics, and care
    utilization with health-state tagging.
3.  **Stage 3: Causal Propensity Score (PS) Adjustment**
    ([`fit_ps()`](https://rdrr.io/pkg/CohortEconomics/man/fit_ps.html),
    [`adjust_ps()`](https://rdrr.io/pkg/CohortEconomics/man/adjust_ps.html),
    [`assess_balance()`](https://rdrr.io/pkg/CohortEconomics/man/assess_balance.html)):
    Fits regularized logistic regression via `Cyclops` to perform
    caliper matching and evaluate covariate balance (SMD).
4.  **Stage 4: Trajectory Compilation & State-Cost Extraction**
    ([`compile_trajectories()`](https://rdrr.io/pkg/CohortEconomics/man/compile_trajectories.html)):
    Converts longitudinal patient timelines into Markov health-state
    transition matrices and state-specific cost distributions.
5.  **Stage 5: Economic Simulation**
    ([`simulate_economics()`](https://rdrr.io/pkg/CohortEconomics/man/simulate_economics.html)):
    Runs probabilistic sensitivity analysis (PSA) simulating lifetime
    costs and Quality-Adjusted Life-Years (QALYs).
6.  **Stage 6: Decision Analysis & Post-Processing**
    ([`run_cea()`](https://rdrr.io/pkg/CohortEconomics/man/run_cea.html),
    [`plot_ceac()`](https://rdrr.io/pkg/CohortEconomics/man/plot_ceac.html),
    [`plot_plane()`](https://rdrr.io/pkg/CohortEconomics/man/plot_plane.html),
    [`table_summary()`](https://rdrr.io/pkg/CohortEconomics/man/table_summary.html)):
    Calculates Incremental Cost-Effectiveness Ratios (ICER) and Net
    Monetary Benefit (NMB) via `BCEA`.

#### Example: End-to-End HEOR Pipeline

``` r

# 1-6. Run the complete pipeline
study <- init(
  cdm = cdm,
  target_cohort = "target_cohort",
  comparator_cohort = "comparator_cohort",
  outcome_cohort = "outcome_cohort"
) |>
  summarise_baseline() |>
  extract_hcru() |>
  fit_ps() |>
  adjust_ps() |>
  compile_trajectories() |>
  simulate_economics(time_horizon = 5, n_samples = 25) |>
  run_cea()

# Decision analytic summary
table_summary(study)
#> 
#> Cost-effectiveness analysis summary 
#> 
#> Reference intervention:  intervention 1
#> Comparator intervention: intervention 2
#> 
#> intervention 1 dominates for all k in [0 - 50000] 
#> 
#> 
#> Analysis for willingness to pay parameter k = 25000
#> 
#>                Expected net benefit
#> intervention 1               -66970
#> intervention 2               -66970
#> 
#>                                               EIB CEAC   ICER
#> intervention 1 vs intervention 2 0.00000000039169 0.08 125685
#> 
#> Optimal intervention (max expected net benefit) for k = 25000: intervention 1
#>                         
#> EVPI -0.0000000000023283
```

------------------------------------------------------------------------

### 6. The `hermes` Umbrella Metapackage

The root **`hermes`** package unifies `CohortUtilisation`,
`CohortCosts`, and `CohortEconomics` into a single, cohesive developer
experience:

- **One-Step Installation**: `pak::pkg_install("iomedhealth/hermes")`
  installs all subpackages and dependencies.
- **Unified Attachment**:
  [`library(hermes)`](https://iomedhealth.github.io/hermes/) attaches
  all three packages and re-exports all analytical functions.
- **Built-in Mock Data**:
  [`mockHERMES()`](https://iomedhealth.github.io/hermes/reference/mockHERMES.md)
  provides a self-contained in-memory DuckDB OMOP CDM database for
  testing and demonstrations.

------------------------------------------------------------------------

### 7. Package Summary Matrix

| Package | Primary Scope | Key Verbs | Target Persona |
|:---|:---|:---|:---|
| **`CohortUtilisation`** | In-database HCRU extraction across care settings | [`addInpatients()`](https://rdrr.io/pkg/CohortUtilisation/man/addInpatients.html), [`addEmergencyCare()`](https://rdrr.io/pkg/CohortUtilisation/man/addEmergencyCare.html), [`addOutpatientVisits()`](https://rdrr.io/pkg/CohortUtilisation/man/addOutpatientVisits.html), [`addVisits()`](https://rdrr.io/pkg/CohortUtilisation/man/addVisits.html), [`addPrescriptions()`](https://rdrr.io/pkg/CohortUtilisation/man/addPrescriptions.html), [`addProcedures()`](https://rdrr.io/pkg/CohortUtilisation/man/addProcedures.html), [`computeHospitalizationCohorts()`](https://rdrr.io/pkg/CohortUtilisation/man/compute_hospitalization_cohorts.html), [`summariseUtilization()`](https://rdrr.io/pkg/CohortUtilisation/man/summariseUtilization.html), [`tableUtilization()`](https://rdrr.io/pkg/CohortUtilisation/man/tableUtilization.html) | Epidemiologists, Data Analysts |
| **`CohortCosts`** | Direct medical costs & OMOP COST table linkage | [`addCosts()`](https://rdrr.io/pkg/CohortCosts/man/addCosts.html), [`summariseCosts()`](https://rdrr.io/pkg/CohortCosts/man/summariseCosts.html), [`tableCosts()`](https://rdrr.io/pkg/CohortCosts/man/tableCosts.html), [`plotCosts()`](https://rdrr.io/pkg/CohortCosts/man/plotCosts.html) | Health Economists, Financial Analysts |
| **`CohortEconomics`** | Propensity scores, trajectories, simulation & CEA | [`init()`](https://rdrr.io/pkg/CohortEconomics/man/init.html), [`summarise_baseline()`](https://rdrr.io/pkg/CohortEconomics/man/summarise_baseline.html), [`extract_hcru()`](https://rdrr.io/pkg/CohortEconomics/man/extract_hcru.html), [`fit_ps()`](https://rdrr.io/pkg/CohortEconomics/man/fit_ps.html), [`adjust_ps()`](https://rdrr.io/pkg/CohortEconomics/man/adjust_ps.html), [`compile_trajectories()`](https://rdrr.io/pkg/CohortEconomics/man/compile_trajectories.html), [`simulate_economics()`](https://rdrr.io/pkg/CohortEconomics/man/simulate_economics.html), [`run_cea()`](https://rdrr.io/pkg/CohortEconomics/man/run_cea.html), [`plot_ceac()`](https://rdrr.io/pkg/CohortEconomics/man/plot_ceac.html), [`plot_plane()`](https://rdrr.io/pkg/CohortEconomics/man/plot_plane.html) | Health Economists, HTA Researchers |
| **`hermes`** | Umbrella metapackage & unified developer interface | All verbs re-exported + [`mockHERMES()`](https://iomedhealth.github.io/hermes/reference/mockHERMES.md) | All RWE / HEOR Practitioners |
