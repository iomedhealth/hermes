# Feature Specification: omopHeor Metapackage Renaming and CRAN-Readiness Cleanup

**Feature Branch**: `010-omopheor-cran-cleanup`

**Created**: 2026-08-21

**Status**: Draft

**Input**: User description: "execute the renaming and CRAN-readiness cleanup"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Metapackage Renamed to omopHeor (Priority: P1)

As an R/HEOR researcher working with OMOP CDM data, I want to load the unified analytical ecosystem via `library(omopHeor)` so that I can use all HCRU, cost extraction, and health economics modeling capabilities without naming collisions against existing Bioconductor packages.

**Why this priority**: The name `hermes` is already reserved and in active distribution on Bioconductor for RNA-Seq data processing. CRAN policy strictly forbids package name collisions across CRAN and Bioconductor. Renaming the metapackage to `omopHeor` unblocks CRAN eligibility and aligns with DARWIN EU and OHDSI naming conventions (`omopgenerics`, `visOmopResults`, `CohortUtilisation`, `CohortCosts`, `CohortEconomics`).

**Independent Test**: Install the metapackage root, run `library(omopHeor)`, and verify that `CohortUtilisation`, `CohortCosts`, and `CohortEconomics` are attached with the startup banner and all exported functions are accessible.

**Acceptance Scenarios**:

1. **Given** a clean R environment, **When** `library(omopHeor)` is called, **Then** all three underlying packages (`CohortUtilisation`, `CohortCosts`, `CohortEconomics`) attach successfully with the startup banner.
2. **Given** `omopHeor` is installed, **When** package metadata is inspected via `packageDescription("omopHeor")`, **Then** the package name is `omopHeor`, URLs resolve without 301 redirects, and no forbidden `Remotes:` fields exist.

---

### User Story 2 - Subpackage Size Reduction and Footprint Compliance (Priority: P2)

As a CRAN package maintainer, I want `CohortCosts` to be under the 5 MB package size limit so that incoming CRAN submission checks pass without size warnings or manual review flags.

**Why this priority**: CRAN enforces a strict 5 MB package archive limit. Currently `CohortCosts` includes large unused Spanish tariff data files (`inst/extdata/costs_spain.*`, ~46.2 MB) that inflate the tarball.

**Independent Test**: Build the `CohortCosts` source package (`R CMD build packages/CohortCosts`) and verify that the resulting `.tar.gz` size is < 500 KB and `R CMD check --as-cran` passes with 0 size warnings.

**Acceptance Scenarios**:

1. **Given** the `CohortCosts` source tree, **When** built via `R CMD build`, **Then** the archive size is well below 5 MB.
2. **Given** the `CohortCosts` package namespace, **When** inspected for dependencies, **Then** declared `Imports` (such as `dbplyr`) are actively utilized or removed to prevent unused namespace NOTEs.

---

### User Story 3 - Dependency Sanitization and Test Isolation (Priority: P3)

As a package developer, I want `CohortEconomics` and all other packages to depend only on active CRAN/Bioconductor packages so that automated CRAN checks run cleanly on any isolated CRAN testing machine.

**Why this priority**: CRAN machines do not allow non-CRAN `Suggests` or `Remotes` fields. Packages like `Cohort2Trajectory` and `TrajectoryMarkovAnalysis` that are only on GitHub must not be declared in `DESCRIPTION`.

**Independent Test**: Run `R CMD check --as-cran` with `_R_CHECK_FORCE_SUGGESTS_=true` on all package archives and verify that no unresolvable dependency errors occur.

**Acceptance Scenarios**:

1. **Given** `CohortEconomics/DESCRIPTION`, **When** validated by `R CMD check`, **Then** all entries in `Imports` and `Suggests` exist on CRAN, and the `Remotes` field is completely omitted.
2. **Given** the `CohortEconomics` test suite, **When** executed, **Then** cross-package functions like `CohortCosts::addCosts()` resolve properly and 100% of unit tests pass.

---

### User Story 4 - Fast Examples and CRAN Documentation Standards (Priority: P4)

As a user reading package help files or CRAN automated testers running examples, I want every exported function to have runnable, self-contained examples that execute in under 5 seconds.

**Why this priority**: CRAN strongly encourages runnable examples for user-facing APIs and requires the total package example check time to remain minimal.

**Independent Test**: Run `devtools::run_examples()` across all subpackages and confirm all examples execute without errors within budget.

**Acceptance Scenarios**:

1. **Given** help pages for `omopHeor`, `CohortUtilisation`, `CohortCosts`, and `CohortEconomics`, **When** examples are executed, **Then** mock in-memory data (`duckdb`) runs cleanly and completes in < 5s per function.
2. **Given** package `DESCRIPTION` files, **When** checked, **Then** all acronyms (OMOP, CDM, HCRU, HEOR, CEA) are fully expanded on first mention in `Description:` fields.

---

### Edge Cases

- What happens if a user previously wrote scripts with `library(hermes)`? The repository documentation and deprecation guide should clearly specify the migration path to `library(omopHeor)`.
- How does the system handle CRAN check environments without network access? All test fixtures and `@examples` must use local in-memory DuckDB / synthetic data without making external HTTP requests or persistent writes outside `tempdir()`.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The root package MUST be named `omopHeor` across `DESCRIPTION`, `tests/testthat.R`, `R/zzz.R`, `inst/CITATION`, vignettes, and documentation.
- **FR-002**: All 4 `DESCRIPTION` files (`omopHeor`, `CohortUtilisation`, `CohortCosts`, `CohortEconomics`) MUST omit `Remotes:` and ensure all `Imports` and `Suggests` refer exclusively to packages published on CRAN or Bioconductor.
- **FR-003**: The `Description:` field in each package `DESCRIPTION` MUST expand all domain acronyms on first use (e.g., "Observational Medical Outcomes Partnership (OMOP)", "Common Data Model (CDM)", "Healthcare Resource Utilization (HCRU)", "Health Economics and Outcomes Research (HEOR)", "Cost-Effectiveness Analysis (CEA)") and quote software package names in single quotes.
- **FR-004**: `CohortCosts` MUST remove redundant large files (`costs_spain.csv`, `costs_spain.json`, `costs_spain.parquet`) from `packages/CohortCosts/inst/extdata/` to comply with CRAN size limits (< 5 MB).
- **FR-005**: `CohortCosts` MUST ensure all declared `Imports` (including `dbplyr`) are properly imported or cleaned up to avoid unused import NOTEs.
- **FR-006**: `CohortEconomics` MUST remove references to non-CRAN packages (`Cohort2Trajectory`, `TrajectoryMarkovAnalysis`) from `Suggests:` and `Remotes:`.
- **FR-007**: `CohortEconomics` test suite MUST explicitly namespace cross-package helper calls (e.g., `CohortCosts::addCosts`) and pass 100% of tests.
- **FR-008**: Exported functions across all packages MUST provide concise, self-contained `@examples` using synthetic in-memory DuckDB / mock CDM data.
- **FR-009**: All URL references in `DESCRIPTION`, `README.md`, and documentation MUST use canonical HTTPS addresses without 301 redirects (e.g., `https://www.iomed.health/`, `https://github.com/iomedhealth/hermes/issues`).
- **FR-010**: Every package MUST generate valid `.Rd` documentation via `devtools::document()` with no missing parameter descriptions or broken cross-references.
- **FR-011**: All subpackages and the root metapackage MUST pass `R CMD check --no-manual --as-cran` with 0 Errors, 0 Warnings, and at most 1 standard NOTE ("New submission").
- **FR-012**: The repository MUST maintain a structured CRAN submission sequencing plan documenting the progressive publication from independent packages (`CohortUtilisation`, `CohortCosts`) to dependent analytical packages (`CohortEconomics`) and finally the metapackage (`omopHeor`).

### Key Entities

- **`omopHeor` Metapackage**: Umbrella R package providing unified startup hooks, namespace attachments, and high-level re-exports.
- **`CohortUtilisation`**: Standalone CRAN R package for in-database HCRU domain extraction (inpatient, outpatient, emergency, pharmacy, procedures).
- **`CohortCosts`**: Standalone CRAN R package for direct medical cost extraction and expenditure aggregation on OMOP CDM `COST` records.
- **`CohortEconomics`**: Analytical CRAN R package for propensity score adjustment, Markov state trajectories, microsimulation, and Cost-Effectiveness Analysis.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of packages (`CohortUtilisation`, `CohortCosts`, `CohortEconomics`, `omopHeor`) achieve `0 errors` and `0 warnings` on `R CMD check --no-manual --as-cran`.
- **SC-002**: Package tarball size for `CohortCosts` is reduced by over 95% (from 46.3 MB to < 1 MB).
- **SC-003**: 0 non-CRAN/non-Bioconductor dependencies remain in any `DESCRIPTION` file across the repository.
- **SC-004**: Metapackage startup (`library(omopHeor)`) successfully attaches all 3 subpackages in < 1 second.
- **SC-005**: All unit test suites pass 100% with zero test failures across the monorepo.
- **SC-006**: All vignettes render cleanly without errors in < 60 seconds.

## Assumptions

- Subpackages `CohortUtilisation`, `CohortCosts`, and `CohortEconomics` will be submitted to CRAN in topological order before `omopHeor`.
- `Cohort2Trajectory` and `TrajectoryMarkovAnalysis` functionality is replaced or implemented with native pure-R logic and DARWIN EU standard tooling, eliminating the need for unapproved GitHub dependencies.
- Spanish healthcare cost catalog data (`data/costs_spain.*`) remains in the project root for local workflows, Airflow DAGs, and scripts, but is excluded from the R package distribution bundle in `packages/CohortCosts/inst/extdata/`.
