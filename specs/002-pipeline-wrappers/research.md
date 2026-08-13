# Phase 0: Research

All technology choices and architectural patterns are explicitly mandated by the HERMES Constitution and the feature specification.

- **Decision**: Wrap DARWIN-EU/OHDSI ecosystem packages (e.g., `CDMConnector`, `CohortMethod`, `hesim`, `BCEA`).
- **Rationale**: Core principle "Zero Wheel-Reinvention" strictly forbids custom analytic logic for standard RWE/HEOR tasks.
- **Alternatives considered**: None. Mandated by architecture.