# HERMES: Health Economic Resource Modeling & Evaluation System

**HERMES** is an R-based framework and package ecosystem designed for Real-World Evidence (RWE) and Health Economics and Outcomes Research (HEOR). It streamlines the end-to-end process of Healthcare Resource Utilization (HCRU) analysis and Cost-Effectiveness Analysis (CEA) starting from observational data in the OMOP Common Data Model (CDM).

---

## The 6-Stage Process (From Question to HCRU & CEA Answers)

HERMES implements a structured 6-stage analytical framework to transition from observational data to actionable health economic insights:

### Stage 1: Cohort Generation
Define target treatment, comparator, and clinical outcome cohorts using standardized vocabularies.
* **Core R Packages:** `CDMConnector`, `CodelistGenerator`, `omopgenerics`
* **Details:** Connects programmatically to OMOP CDM databases (e.g., DuckDB, Postgres, Snowflake) and instantiates cohort tables based on concept sets and logic rules.

### Stage 2: Descriptive Baseline & HCRU Characterization
Build unadjusted baseline tables and extract raw healthcare resource utilization and direct medical costs.
* **Core R Packages:** `PatientProfiles`, `CohortCharacteristics`, `ClinicalCharacteristics`
* **Details:** Enriches cohorts with baseline demographics, tracks entry timing and attrition (`summariseCohortAttrition`), and extracts raw unadjusted care utilization (hospitalizations, outpatient visits, ED visits, drug prescriptions) and direct costs.

### Stage 3: Causal Propensity Score (PS) Adjustment (The Causal Bridge)
Control for baseline confounding between comparative cohorts to enable causal inference.
* **Core R Packages:** `CohortMethod`, `Cyclops`
* **Details:** Fits high-dimensional regularized logistic regression models using `Cyclops` on thousands of baseline clinical features. Performs patient trimming, matching, or weighting (e.g., IPTW) and verifies balance using Standardized Mean Difference (SMD) metrics.

### Stage 4: Trajectory Compilation & State-Cost Extraction
Compile balanced patient timelines into discrete health states and extract state-specific cost distributions.
* **Core R Packages:** `Cohort2Trajectory`, `TrajectoryMarkovAnalysis`
* **Details:** Maps balanced patient longitudinal journeys into mutually exclusive health states over discrete time cycles. Estimates state-to-state transition probabilities and directly extracts medical expenditure distributions from the OMOP `COST` table.

### Stage 5: Economic Simulation
Integrate transition probabilities and cost distributions into economic state-transition models.
* **Core R Packages:** `hesim`, `heemod`
* **Details:** Runs cohort or individual-level simulations (Markov cohort models, microsimulations) to project long-term costs and Quality-Adjusted Life-Years (QALYs) under parametric uncertainty.

### Stage 6: Decision Analysis & Post-Processing (CEA)
Compute decision-analytic endpoints and produce Health Technology Assessment (HTA) outputs.
* **Core R Packages:** `BCEA`
* **Details:** Calculates Incremental Cost-Effectiveness Ratios (ICER) and Net Monetary Benefit (NMB). Generates decision-analytic visualizations including Cost-Effectiveness Acceptability Curves (CEAC) and scatter plots on the cost-effectiveness plane.

---

## Repository Structure

```
HERMES/
├── README.md
├── AGENTS.md
└── ...
```
