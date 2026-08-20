# Cohort Utilization & Cost Enrichment

## Cohort Utilization & Cost Enrichment

In Health Economics and Outcomes Research (HEOR) and Real-World Evidence
(RWE), evaluating Healthcare Resource Utilization (HCRU) and direct
medical costs requires capturing granular patient encounters across
multiple care settings (inpatient, outpatient, pharmacy, diagnostics,
procedures, and financial claims).

Following the **DARWIN EU / OHDSI** package ecosystem standards
(`CohortConstructor`, `PatientProfiles`, `CohortCharacteristics`),
**HERMES** provides a pipe-friendly, 3-layer architecture for cohort
construction, in-database column enrichment, and standardized reporting.

------------------------------------------------------------------------

### 3-Layer Architecture Overview

``` text
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                                   OMOP CDM DATABASE                                    │
│  (visit_occurrence, provider, drug_exposure, procedure_occurrence, measurement, cost)  │
└────────────────────────────────────────────────────────────────────────────────────────┘
                                    │
       ┌────────────────────────────┼────────────────────────────┐
       ▼                            ▼                            ▼
 1. Episode Constructors     2. Cohort Enrichers          3. Summarisation & Reporting
 (CohortConstructor Style)   (PatientProfiles Style)      (CohortCharacteristics Style)
 ─────────────────────────   ───────────────────────      ────────────────────────────
 Standalone episode cohorts  Appends windowed metric      Standardised result objects
 in write schema:            columns in-database:         for publication tables:
 • computeHospitalization*   • addHospitalizations()      • summariseUtilization()
 • computeInfusionCohorts()  • addOutpatientVisits()      • summariseCosts()
                             • addPrescriptions()         • tableUtilization()
                             • addProcedures()            • tableCosts()
                             • addCosts()
```

------------------------------------------------------------------------

### 1. Setup & CDM Connection

We initialize an OMOP CDM reference (such as the mock HERMES test
database):

``` r

library(HERMES)
library(dplyr)
library(omopgenerics)

# Connect to OMOP CDM
cdm <- mockHERMES()
```

------------------------------------------------------------------------

### 2. Layer 1: Care Episode Cohort Constructors (`CohortConstructor` Style)

Care episode constructors collapse contiguous or overlapping raw
encounters into discrete hospitalization or infusion therapy episodes
and register them in the database write schema.

#### Hospitalization & Readmission Episodes

``` r

# Construct collapsed hospitalization episodes and 30-day readmissions
cdm$hosp_episodes <- computeHospitalizationCohorts(
  cdm = cdm,
  name = "hosp_episodes",
  visitConceptIds = c(9201L, 8717L, 581379L),
  icuConceptIds = 32037L,
  readmissionWindow = 30L
)

# Inspect cohort entries
cdm$hosp_episodes |>
  dplyr::collect()
#> # A tibble: 4 × 4
#>   cohort_definition_id subject_id cohort_start_date cohort_end_date
#>                  <int>      <int> <date>            <date>         
#> 1                    1          1 2010-02-01        2010-02-05     
#> 2                    1          2 2010-03-10        2010-03-15     
#> 3                    1          1 2010-02-20        2010-02-23     
#> 4                    2          1 2010-02-20        2010-02-23
```

#### Infusion Administration Episodes

``` r

# Construct parenteral/intravenous infusion therapy episodes
cdm$infusion_episodes <- computeInfusionCohorts(
  cdm = cdm,
  name = "infusion_episodes",
  routeConceptIds = c(4171047L) # Intravenous
)

cdm$infusion_episodes |>
  dplyr::collect()
#> # A tibble: 1 × 4
#>   cohort_definition_id subject_id cohort_start_date cohort_end_date
#>                  <int>      <int> <date>            <date>         
#> 1                    1          1 2010-03-01        2010-03-01
```

------------------------------------------------------------------------

### 3. Layer 2: In-Database Cohort Enrichment (`PatientProfiles` Style)

Cohort enricher functions take an existing study cohort, execute
database-side joins across configurable temporal windows (e.g., baseline
`[-365, -1]` and follow-up `[0, 365]`), and append metric columns
without dropping zero-utilization subjects.

``` r

# Pipe study cohort through all 5 domain enrichers
cdm$study_enriched <- cdm$target_cohort |>
  addHospitalizations(
    window = list(baseline = c(-365, -1), followup = c(0, 365)),
    readmissions = TRUE
  ) |>
  addOutpatientVisits(
    window = list(baseline = c(-365, -1), followup = c(0, 365)),
    stratifySpecialty = TRUE
  ) |>
  addPrescriptions(
    window = list(baseline = c(-365, -1), followup = c(0, 365)),
    daysSupply = TRUE,
    pdc = TRUE
  ) |>
  addProcedures(
    window = list(baseline = c(-365, -1), followup = c(0, 365))
  ) |>
  addCosts(
    window = list(baseline = c(-365, -1), followup = c(0, 365)),
    costField = "total_paid",
    name = "study_enriched"
  )

# Inspect enriched columns
colnames(cdm$study_enriched)
#>  [1] "cohort_definition_id"             "subject_id"                      
#>  [3] "cohort_start_date"                "cohort_end_date"                 
#>  [5] "inpatient_admissions_baseline"    "inpatient_los_days_baseline"     
#>  [7] "icu_admissions_baseline"          "icu_los_days_baseline"           
#>  [9] "readmissions_30d_baseline"        "readmissions_90d_baseline"       
#> [11] "inpatient_admissions_followup"    "inpatient_los_days_followup"     
#> [13] "icu_admissions_followup"          "icu_los_days_followup"           
#> [15] "readmissions_30d_followup"        "readmissions_90d_followup"       
#> [17] "emergency_visits_baseline"        "gp_visits_baseline"              
#> [19] "specialist_visits_baseline"       "other_outpatient_visits_baseline"
#> [21] "emergency_visits_followup"        "gp_visits_followup"              
#> [23] "specialist_visits_followup"       "other_outpatient_visits_followup"
#> [25] "rx_fills_baseline"                "days_supply_baseline"            
#> [27] "infusions_baseline"               "pdc_baseline"                    
#> [29] "rx_fills_followup"                "days_supply_followup"            
#> [31] "infusions_followup"               "pdc_followup"                    
#> [33] "lab_tests_count_baseline"         "procedures_count_baseline"       
#> [35] "lab_tests_count_followup"         "procedures_count_followup"       
#> [37] "cost_inpatient_baseline"          "cost_outpatient_baseline"        
#> [39] "cost_drug_baseline"               "cost_procedure_baseline"         
#> [41] "cost_total_baseline"              "cost_inpatient_followup"         
#> [43] "cost_outpatient_followup"         "cost_drug_followup"              
#> [45] "cost_procedure_followup"          "cost_total_followup"
```

``` text
The enriched cohort table contains:
• Inpatient: inpatient_admissions_*, inpatient_los_days_*, icu_admissions_*, icu_los_days_*, readmissions_30d_*
• Outpatient: emergency_visits_*, gp_visits_*, specialist_visits_*, other_outpatient_visits_*
• Pharmacy: rx_fills_*, days_supply_*, pdc_*, infusions_*
• Diagnostics: lab_tests_count_*, procedures_count_*
• Direct Costs: cost_inpatient_*, cost_outpatient_*, cost_drug_*, cost_procedure_*, cost_total_*
```

------------------------------------------------------------------------

### 4. Layer 3: Analytics & Reporting (`CohortCharacteristics` Style)

We aggregate patient-level utilization and costs into DARWIN EU
standardized `summarised_result` objects compatible with
`visOmopResults`.

#### Summarise Care Utilization

``` r

utilSummary <- summariseUtilization(
  cohort = cdm$study_enriched,
  strata = list("cohort_definition_id"),
  estimates = c("mean", "sd", "median", "q25", "q75", "min", "max")
)

# View standardised result structure
utilSummary |>
  dplyr::select("strata_name", "strata_level", "variable_name", "estimate_name", "estimate_value") |>
  utils::head(10)
#> # A tibble: 10 × 5
#>    strata_name strata_level variable_name           estimate_name estimate_value
#>    <chr>       <chr>        <chr>                   <chr>         <chr>         
#>  1 overall     overall      number records          count         2             
#>  2 overall     overall      number subjects         count         2             
#>  3 overall     overall      inpatient_admissions_b… mean          0             
#>  4 overall     overall      inpatient_admissions_b… sd            0             
#>  5 overall     overall      inpatient_admissions_b… median        0             
#>  6 overall     overall      inpatient_admissions_b… q25           0             
#>  7 overall     overall      inpatient_admissions_b… q75           0             
#>  8 overall     overall      inpatient_admissions_b… min           0             
#>  9 overall     overall      inpatient_admissions_b… max           0             
#> 10 overall     overall      inpatient_los_days_bas… mean          0
```

#### Summarise Direct Medical Costs

``` r

costSummary <- summariseCosts(
  cohort = cdm$study_enriched,
  strata = list("cohort_definition_id"),
  estimates = c("mean", "sd", "median", "q25", "q75", "min", "max")
)

costSummary |>
  dplyr::select("strata_name", "strata_level", "variable_name", "estimate_name", "estimate_value") |>
  utils::head(8)
#> # A tibble: 8 × 5
#>   strata_name strata_level variable_name           estimate_name estimate_value
#>   <chr>       <chr>        <chr>                   <chr>         <chr>         
#> 1 overall     overall      number records          count         2             
#> 2 overall     overall      number subjects         count         2             
#> 3 overall     overall      cost_inpatient_baseline mean          0             
#> 4 overall     overall      cost_inpatient_baseline sd            0             
#> 5 overall     overall      cost_inpatient_baseline median        0             
#> 6 overall     overall      cost_inpatient_baseline q25           0             
#> 7 overall     overall      cost_inpatient_baseline q75           0             
#> 8 overall     overall      cost_inpatient_baseline min           0
```

#### Publication-Ready GT & Flextable Output

[`tableUtilization()`](../reference/tableUtilization.md) and
[`tableCosts()`](../reference/tableCosts.md) integrate with
[`visOmopResults::visOmopTable()`](https://darwin-eu.github.io/visOmopResults/reference/visOmopTable.html)
to format publication-grade summary tables:

``` r

# Format summary table with concise estimate strings
tableUtilization(
  result = utilSummary,
  estimateName = c(
    "Mean (SD)" = "<mean> (<sd>)",
    "Median [Q25 - Q75]" = "<median> [<q25> - <q75>]"
  ),
  header = c("cohort_name")
)
```

[TABLE]

------------------------------------------------------------------------

### 5. Visualizing Care Utilization & Costs (`visOmopResults` Style)

HERMES provides [`plotUtilization()`](../reference/plotUtilization.md)
and [`plotCosts()`](../reference/plotCosts.md) for rapid exploratory and
publication visualization, leveraging standard `visOmopResults` ggplot
themes and facets.

#### Bar Plots for Care Utilization

``` r

# Bar plot comparing follow-up mean care utilization across key settings
main_util_vars <- c(
  "inpatient_admissions_followup",
  "emergency_visits_followup",
  "gp_visits_followup",
  "specialist_visits_followup",
  "rx_fills_followup"
)

plotUtilization(
  result = utilSummary |> dplyr::filter(variable_name %in% main_util_vars),
  plotType = "barplot",
  x = "cohort_name",
  y = "mean",
  facet = "variable_name",
  colour = "cohort_name"
)
```

![](cohort-utilization_files/figure-html/plot_util_bar-1.png)

#### Box Plots for Direct Medical Costs

``` r

# Box plot showing median and interquartile range for follow-up cost domains
plotCosts(
  result = costSummary |> dplyr::filter(grepl("followup", variable_name)),
  plotType = "boxplot",
  x = "cohort_name",
  facet = "variable_name",
  colour = "cohort_name"
)
```

![](cohort-utilization_files/figure-html/plot_cost_box-1.png)

------------------------------------------------------------------------

### 6. Summary Matrix Mapping

| Domain | Metrics Extracted | Function Responsible | Output Columns |
|:---|:---|:---|:---|
| **\[Inpatient\]** | Admissions, ICU, LOS, Readmissions | [`addHospitalizations()`](../reference/addHospitalizations.md) | `inpatient_admissions_*`, `inpatient_los_days_*`, `icu_admissions_*`, `readmissions_30d_*` |
| **\[Outpatient\]** | GP, Specialist, ER, Other Visits | [`addOutpatientVisits()`](../reference/addOutpatientVisits.md) | `gp_visits_*`, `specialist_visits_*`, `emergency_visits_*` |
| **\[Pharmacy\]** | Rx Fills, Days Supply, PDC, Infusions | [`addPrescriptions()`](../reference/addPrescriptions.md) | `rx_fills_*`, `days_supply_*`, `pdc_*`, `infusions_*` |
| **\[Diagnostics/Proc\]** | Labs, Imaging, Procedures | [`addProcedures()`](../reference/addProcedures.md) | `lab_tests_count_*`, `procedures_count_*` |
| **\[Direct Costs\]** | Inpatient, Outpatient, Drug, Total | [`addCosts()`](../reference/addCosts.md) | `cost_inpatient_*`, `cost_outpatient_*`, `cost_drug_*`, `cost_total_*` |
