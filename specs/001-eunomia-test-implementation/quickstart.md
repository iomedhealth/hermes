# Quickstart Guide: Running Eunomia Tests for HERMES

## Prerequisites

Ensure R >= 4.1 is installed along with `devtools`, `testthat`, `covr`, `CDMConnector`, `omopgenerics`, and `Eunomia`.

```r
# Install required dependencies
install.packages(c("devtools", "testthat", "CDMConnector", "omopgenerics", "duckdb", "covr"))
```

## Running the Eunomia Test Suite

Execute all package unit and integration tests locally from R or terminal:

### From R Console
```r
devtools::test()
```

### From Terminal / Command Line
```bash
Rscript -e "devtools::test()"
```

### Running Specific Pipeline Stage Tests
```r
# Test Stage 1: Cohort Init
testthat::test_file("tests/testthat/test-stage1-init.R")

# Test Stage 2: HCRU & COST Extraction
testthat::test_file("tests/testthat/test-stage2-baseline-hcru.R")

# Test Stage 3: Causal Propensity Score
testthat::test_file("tests/testthat/test-stage3-causal-ps.R")

# Test Stage 4: Trajectories & State Costs
testthat::test_file("tests/testthat/test-stage4-trajectories-costs.R")

# Test Stage 5: Economic Simulation
testthat::test_file("tests/testthat/test-stage5-economic-simulation.R")

# Test Stage 6: CEA Decision Analysis
testthat::test_file("tests/testthat/test-stage6-cea-decision.R")
```

### Verify Code Coverage

```r
# Verify test coverage for database interactions
covr::package_coverage()
```

## How the Test Fixture Works

`tests/testthat/helper-eunomia.R` automatically creates a temporary DuckDB database pre-populated with synthetic OMOP CDM tables (including populated `COST` records) and cleans up database connections on test exit using `withr::defer()` or `cdmDisconnect()`.
