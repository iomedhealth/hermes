# Data Model

The pipeline relies on a sequence of S3 objects, each encapsulating the state of the analysis.

## Entities

- **hermes_study**
  - Fields: `cdm` (reference to CDM), cohort counts/validation status.
  - Transitions: Serves as input for Stage 2.

- **hermes_hcru**
  - Fields: All `hermes_study` data + Table 1 demographics/comorbidities, unadjusted cost summaries.
  - Transitions: Serves as input for Stage 3.

- **hermes_ps**
  - Fields: All `hermes_hcru` data + matched/weighted populations, SMD balance diagnostics.
  - Transitions: Serves as input for Stage 4.

- **hermes_trajectories**
  - Fields: All `hermes_ps` data + discrete health states, transition probability matrices, state-grouped costs.
  - Transitions: Serves as input for Stage 5.

- **hermes_sim**
  - Fields: All `hermes_trajectories` data + simulated costs (`c`) matrix, simulated effects (`e`) matrix.
  - Transitions: Serves as input for Stage 6.

- **hermes_cea**
  - Fields: All `hermes_sim` data + final CEA summaries (ICER, NMB, CEAC).