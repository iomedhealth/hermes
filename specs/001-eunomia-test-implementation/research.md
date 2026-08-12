# Research & Technical Decisions: Eunomia Test Implementation

## Decision 1: Eunomia Embedded Test CDM Fixture

- **Decision**: Create a standardized test helper (`tests/testthat/helper-eunomia.R`) providing `hermes_test_cdm()` that provisions an embedded DuckDB/SQLite OMOP CDM reference using `CDMConnector::eunomiaDir()`.
- **Rationale**: `CDMConnector` and `omopgenerics` provide native support for Eunomia embedded DuckDB/SQLite databases. This ensures fast (<60 seconds), offline, reproducible test execution across all environment configurations.
- **Alternatives Considered**:
  - *External Database Server (PostgreSQL/Redshift)*: Rejected due to requirement for network access, credentials, and CI infrastructure complexity.
  - *Mock Objects*: Rejected because `dbplyr` SQL generation requires active connection catalog metadata.

## Decision 2: Synthetic OMOP COST Table Injection

- **Decision**: The Eunomia test helper will check and synthetically populate the `cost` table if missing or empty, inserting standard records with `cost_event_id`, `cost_domain_id` = 'Visit', `cost_type_concept_id`, `total_paid`, `total_charge`, and `amount_allowed`.
- **Rationale**: Standard Eunomia sample datasets focus on clinical domains and may lack complete `COST` table entries. Injecting deterministic cost data ensures Stage 2 (`extract_hcru()`) and Stage 4 (`extract_state_costs()`) tests execute consistently.
- **Alternatives Considered**:
  - *Relying solely on default Eunomia cost tables*: Rejected because cost data presence varies across Eunomia version releases.

## Decision 3: 6-Stage Pipeline Test Organization

- **Decision**: Organize integration tests into modular files under `tests/testthat/` corresponding 1-to-1 with the HERMES 6-stage architecture specified in `docs/API_SPECIFICATION.md`:
  - `helper-eunomia.R`: Fixture setup and teardown (`cdmDisconnect()`)
  - `test-stage1-init.R`: Stage 1 cohort setup & `hermes_study` class creation
  - `test-stage2-baseline-hcru.R`: Stage 2 characterization and direct `COST` table queries
  - `test-stage3-causal-ps.R`: Stage 3 propensity score modeling & balance assessments
  - `test-stage4-trajectories-costs.R`: Stage 4 longitudinal trajectory state transitions and cost distributions
  - `test-stage5-economic-simulation.R`: Stage 5 state-transition economic simulations
  - `test-stage6-cea-decision.R`: Stage 6 ICER/NMB calculation and visualization methods
- **Rationale**: Keeps tests clean, modular, and easy to maintain while strictly validating the package wrapping strategy.
- **Alternatives Considered**:
  - *Monolithic test file*: Rejected to maintain clear stage isolation and diagnostic readability.
