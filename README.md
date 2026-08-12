# HERMES: Health Economic Resource Modeling & Evaluation System

**HERMES** is an R-based framework designed for Real-World Evidence (RWE) and Health Economics and Outcomes Research (HEOR). It streamlines the end-to-end process of Healthcare Resource Utilization (HCRU) analysis and Cost-Effectiveness Analysis (CEA) starting from observational data in the OMOP Common Data Model (CDM).

---

## The 6-Stage Process (From Question to HCRU & CEA Answers)

HERMES implements a structured 6-stage analytical framework to transition from observational data to actionable health economic insights:

### Stage 1: Cohort Generation
Define target treatment, comparator, and clinical outcome cohorts using standardized vocabularies. Connect programmatically to OMOP CDM databases and instantiates cohort tables based on concept sets and logic rules.

### Stage 2: Descriptive Baseline & HCRU Characterization
Build unadjusted baseline tables. Enrich cohorts with baseline demographics, evaluate entry timing and attrition, and extract raw unadjusted direct medical costs and care utilization (hospitalizations, stays, visits, prescriptions).

### Stage 3: Causal Propensity Score (PS) Adjustment (The Causal Bridge)
Control for baseline confounding using Propensity Scores (PS). Fit high-dimensional regularized logistic regression models based on thousands of baseline clinical features to estimate propensity scores for every patient. Trim, match, or weight patients, and verify balance using Standardized Mean Difference (SMD) metrics.

### Stage 4: Trajectory Compilation & State-Cost Extraction
Compile balanced patient timelines into mutually exclusive health states over discrete time cycles. Estimate state-to-state transition probabilities and directly extract state-specific medical expenditure distributions from the long-form OMOP `COST` table.

### Stage 5: Economic Simulation
Integrate probabilities and cost distributions into an economic state-transition model. Run cohort or individual-level simulations to project long-term costs and Quality-Adjusted Life-Years (QALYs) under uncertainty.

### Stage 6: Decision Analysis & Post-Processing (CEA)
Post-process simulation outputs to compute the Incremental Cost-Effectiveness Ratio (ICER) and Net Monetary Benefit (NMB). Generate decision-analytic plots like Cost-Effectiveness Acceptability Curves (CEAC) to inform Health Technology Assessments (HTA).

---

## Documentation

* [API & Architecture Specification](docs/API_SPECIFICATION.md): Full technical specification of function signatures, S3 class object flow, and OMOP `COST` query strategy.

---

## Repository Structure

```
HERMES/
├── README.md
├── AGENTS.md
└── docs/
    └── API_SPECIFICATION.md
```
