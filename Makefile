# ==============================================================================
# Makefile for omopHeor R Monorepo
# ==============================================================================

# Directory path for Python virtual environment.
VENV ?= .venv
# Path to Python executable.
PYTHON ?= $(VENV)/bin/python
# Path to pip package manager.
PIP ?= $(VENV)/bin/pip
# Path to Apache Airflow CLI binary.
AIRFLOW ?= $(VENV)/bin/airflow
# Path to CohortCosts subpackage directory.
COHORT_COSTS ?= packages/CohortCosts

.PHONY: help install-deps document doc test test-utilisation test-costs test-economics test-root check style lint vignettes site bump-patch bump-minor bump-major cran-wave1 cran-wave2 cran-wave3 cran-all cran-dry-run cran-check-win venv py-deps dag-test dag-run dag-airflow etl-download etl-scrape etl-report etl-all clean

# Show this help prompt.
help:
	@ echo
	@ echo '  Usage:'
	@ echo ''
	@ echo '    make <target> [flags...]'
	@ echo ''
	@ echo '  Targets:'
	@ echo ''
	@ awk '/^#/{ comment = substr($$0,3) } comment && /^[a-zA-Z][a-zA-Z0-9_-]+ ?:/{ print "   ", $$1, comment }' $(MAKEFILE_LIST) | column -t -s ':' | sort
	@ echo ''
	@ echo '  Flags:'
	@ echo ''
	@ awk '/^#/{ comment = substr($$0,3) } comment && /^[a-zA-Z][a-zA-Z0-9_-]+ ?\?=/{ print "   ", $$1, $$2, comment }' $(MAKEFILE_LIST) | column -t -s '?=' | sort
	@ echo ''

# Install local subpackages into active R library.
install-deps:
	Rscript -e "pak::pkg_install(c('local::packages/CohortUtilisation', 'local::packages/CohortCosts', 'local::packages/CohortEconomics'))"

# Update roxygen documentation across monorepo.
document:
	Rscript -e "devtools::document('packages/CohortUtilisation')"
	Rscript -e "devtools::document('packages/CohortCosts')"
	Rscript -e "devtools::document('packages/CohortEconomics')"
	Rscript -e "devtools::document('.')"

# Update roxygen documentation across monorepo (alias for document).
doc: document

# Run all testthat suites across all packages.
test: test-utilisation test-costs test-economics test-root

# Run testthat suite for CohortUtilisation.
test-utilisation:
	Rscript -e "devtools::test('packages/CohortUtilisation')"

# Run testthat suite for CohortCosts.
test-costs:
	Rscript -e "devtools::test('packages/CohortCosts')"

# Run testthat suite for CohortEconomics.
test-economics:
	Rscript -e "devtools::test('packages/CohortEconomics')"

# Run testthat suite for root package.
test-root:
	Rscript -e "devtools::test('.')"

# Run R CMD check --as-cran across all packages.
check:
	Rscript -e "rcmdcheck::rcmdcheck('packages/CohortUtilisation', args = c('--no-manual', '--as-cran'), error_on = 'warning')"
	Rscript -e "rcmdcheck::rcmdcheck('packages/CohortCosts', args = c('--no-manual', '--as-cran'), error_on = 'warning')"
	Rscript -e "rcmdcheck::rcmdcheck('packages/CohortEconomics', args = c('--no-manual', '--as-cran'), error_on = 'warning')"
	Rscript -e "rcmdcheck::rcmdcheck('.', args = c('--no-manual', '--as-cran'), error_on = 'warning')"

# Format code using styler.
style:
	Rscript -e "styler::style_dir('packages/CohortUtilisation/R'); styler::style_dir('packages/CohortCosts/R'); styler::style_dir('packages/CohortEconomics/R'); styler::style_dir('R')"

# Lint code using lintr.
lint:
	Rscript -e "lintr::lint_package('.', linters = lintr::linters_with_defaults(lintr::object_name_linter(styles = 'camelCase')))"

# Render and verify all package vignettes.
vignettes:
	Rscript -e "lapply(list.files('vignettes', pattern = '[.]Rmd$$', full.names = TRUE), rmarkdown::render, output_dir = tempdir())"

# Build pkgdown website locally.
site:
	Rscript -e "pkgdown::build_site(preview = FALSE, install = FALSE)"

# Bump patch version (e.g. 0.6.1 -> 0.6.2).
bump-patch:
	Rscript extras/bumpVersion.R patch

# Bump minor version (e.g. 0.6.1 -> 0.7.0).
bump-minor:
	Rscript extras/bumpVersion.R minor

# Bump major version (e.g. 0.6.1 -> 1.0.0).
bump-major:
	Rscript extras/bumpVersion.R major

# Verify tarball sizes and metadata without submitting.
cran-dry-run:
	Rscript extras/submitCran.R all --dry-run

# Dispatch win-builder checks for all packages.
cran-check-win:
	Rscript extras/submitCran.R all --check-win --dry-run

# Submit Wave 1 (CohortUtilisation and CohortCosts).
cran-wave1:
	Rscript extras/submitCran.R wave1

# Submit Wave 2 (CohortEconomics).
cran-wave2:
	Rscript extras/submitCran.R wave2

# Submit Wave 3 (Root omopHeor metapackage).
cran-wave3:
	Rscript extras/submitCran.R wave3

# Submit all packages to CRAN.
cran-all:
	Rscript extras/submitCran.R all

# Initialize Python virtual environment (.venv).
venv:
	@test -d $(VENV) || python3 -m venv $(VENV)
	@$(PYTHON) -m pip install --upgrade pip

# Install Python ETL dependencies from requirements.txt.
py-deps: venv
	@$(PIP) install -r requirements.txt

# Execute standalone local test of cost_extraction_dag.
dag-test: venv
	PYTHONPATH=. $(PYTHON) $(COHORT_COSTS)/dags/cost_extraction_dag.py

# Execute Airflow DAG test run.
dag-run: venv
	@TMPDIR=$$(mktemp -d -t airflow_hermes_XXXXXX); \
	trap 'rm -rf "$$TMPDIR"' EXIT; \
	AIRFLOW_HOME="$$TMPDIR" AIRFLOW__CORE__DAGS_FOLDER="$(CURDIR)/$(COHORT_COSTS)/dags" $(AIRFLOW) db migrate > /dev/null 2>&1; \
	AIRFLOW_HOME="$$TMPDIR" AIRFLOW__CORE__DAGS_FOLDER="$(CURDIR)/$(COHORT_COSTS)/dags" PYTHONPATH="$(CURDIR)" $(AIRFLOW) dags test hermes_cost_catalogs_etl 2026-01-01

# Execute Airflow DAG test run (alias for dag-run).
dag-airflow: dag-run

# Download raw gazette sources and INE price series.
etl-download: venv
	PYTHONPATH=. $(PYTHON) $(COHORT_COSTS)/scripts/download_costs_sources.py

# Extract and normalize Spanish healthcare cost catalog.
etl-scrape: venv
	PYTHONPATH=. $(PYTHON) $(COHORT_COSTS)/scripts/scrape_costs_es.py

# Generate EDA markdown report and HTML dashboard.
etl-report: venv
	PYTHONPATH=. $(PYTHON) $(COHORT_COSTS)/scripts/generate_eda_report.py
	PYTHONPATH=. $(PYTHON) $(COHORT_COSTS)/scripts/build_dashboard_html.py

# Run end-to-end ETL pipeline (download -> scrape -> report).
etl-all: etl-download etl-scrape etl-report

# Remove temporary build artifacts, pycache, and logs.
clean:
	rm -rf *.tar.gz *.Rcheck packages/*/*.tar.gz packages/*/*.Rcheck Rplots.pdf packages/*/Rplots.pdf packages/*/tests/testthat/Rplots.pdf tests/testthat/Rplots.pdf packages/*/packages
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete 2>/dev/null || true
