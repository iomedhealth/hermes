# ==============================================================================
# Makefile for omopHeor R Monorepo
# ==============================================================================

# Python & Airflow Environment
VENV ?= .venv
PYTHON ?= $(VENV)/bin/python
PIP ?= $(VENV)/bin/pip
AIRFLOW ?= $(VENV)/bin/airflow
COHORT_COSTS ?= packages/CohortCosts

.PHONY: help install-deps document doc test test-utilisation test-costs test-economics test-root check style lint vignettes site bump-patch bump-minor bump-major cran-wave1 cran-wave2 cran-wave3 cran-all cran-dry-run cran-check-win venv py-deps dag-test dag-run dag-airflow etl-download etl-scrape etl-report etl-all clean

# Default target: show help
help:
	@echo "omopHeor Monorepo Build & Release Automation"
	@echo "============================================"
	@echo "Development:"
	@echo "  make install-deps    Install local subpackages into active R library"
	@echo "  make document (doc)  Update roxygen documentation across monorepo"
	@echo "  make test            Run all testthat suites across all packages"
	@echo "  make check           Run R CMD check --as-cran across all packages"
	@echo "  make style           Format code using styler"
	@echo "  make lint            Lint code using lintr"
	@echo "  make vignettes       Render and verify all package vignettes"
	@echo "  make site            Build pkgdown website locally"
	@echo ""
	@echo "Python & Airflow ETL (CohortCosts):"
	@echo "  make venv            Initialize Python virtual environment (.venv)"
	@echo "  make py-deps         Install Python ETL dependencies from requirements.txt"
	@echo "  make dag-test        Execute standalone local test of cost_extraction_dag"
	@echo "  make dag-run         Execute Airflow DAG test run (alias: dag-airflow)"
	@echo "  make etl-download    Download raw gazette sources and INE price series"
	@echo "  make etl-scrape      Extract and normalize Spanish healthcare cost catalog"
	@echo "  make etl-report      Generate EDA markdown report and HTML dashboard"
	@echo "  make etl-all         Run end-to-end ETL pipeline (download -> scrape -> report)"
	@echo ""
	@echo "Version Management:"
	@echo "  make bump-patch      Bump patch version (e.g. 0.6.1 -> 0.6.2)"
	@echo "  make bump-minor      Bump minor version (e.g. 0.6.1 -> 0.7.0)"
	@echo "  make bump-major      Bump major version (e.g. 0.6.1 -> 1.0.0)"
	@echo ""
	@echo "CRAN Submission:"
	@echo "  make cran-dry-run    Verify tarball sizes & metadata without submitting"
	@echo "  make cran-check-win  Dispatch win-builder checks for all packages"
	@echo "  make cran-wave1      Submit Wave 1 (CohortUtilisation + CohortCosts)"
	@echo "  make cran-wave2      Submit Wave 2 (CohortEconomics)"
	@echo "  make cran-wave3      Submit Wave 3 (Root omopHeor metapackage)"
	@echo "  make cran-all        Submit all packages"
	@echo ""
	@echo "Maintenance:"
	@echo "  make clean           Remove temporary build artifacts, pycache, and logs"

install-deps:
	Rscript -e "pak::pkg_install(c('local::packages/CohortUtilisation', 'local::packages/CohortCosts', 'local::packages/CohortEconomics'))"

document:
	Rscript -e "devtools::document('packages/CohortUtilisation')"
	Rscript -e "devtools::document('packages/CohortCosts')"
	Rscript -e "devtools::document('packages/CohortEconomics')"
	Rscript -e "devtools::document('.')"

doc: document

test: test-utilisation test-costs test-economics test-root

test-utilisation:
	Rscript -e "devtools::test('packages/CohortUtilisation')"

test-costs:
	Rscript -e "devtools::test('packages/CohortCosts')"

test-economics:
	Rscript -e "devtools::test('packages/CohortEconomics')"

test-root:
	Rscript -e "devtools::test('.')"

check:
	Rscript -e "rcmdcheck::rcmdcheck('packages/CohortUtilisation', args = c('--no-manual', '--as-cran'), error_on = 'warning')"
	Rscript -e "rcmdcheck::rcmdcheck('packages/CohortCosts', args = c('--no-manual', '--as-cran'), error_on = 'warning')"
	Rscript -e "rcmdcheck::rcmdcheck('packages/CohortEconomics', args = c('--no-manual', '--as-cran'), error_on = 'warning')"
	Rscript -e "rcmdcheck::rcmdcheck('.', args = c('--no-manual', '--as-cran'), error_on = 'warning')"

style:
	Rscript -e "styler::style_dir('packages/CohortUtilisation/R'); styler::style_dir('packages/CohortCosts/R'); styler::style_dir('packages/CohortEconomics/R'); styler::style_dir('R')"

lint:
	Rscript -e "lintr::lint_package('.', linters = lintr::linters_with_defaults(lintr::object_name_linter(styles = 'camelCase')))"

vignettes:
	Rscript -e "lapply(list.files('vignettes', pattern = '[.]Rmd$$', full.names = TRUE), rmarkdown::render, output_dir = tempdir())"

site:
	Rscript -e "pkgdown::build_site(preview = FALSE, install = FALSE)"

bump-patch:
	Rscript extras/bumpVersion.R patch

bump-minor:
	Rscript extras/bumpVersion.R minor

bump-major:
	Rscript extras/bumpVersion.R major

cran-dry-run:
	Rscript extras/submitCran.R all --dry-run

cran-check-win:
	Rscript extras/submitCran.R all --check-win --dry-run

cran-wave1:
	Rscript extras/submitCran.R wave1

cran-wave2:
	Rscript extras/submitCran.R wave2

cran-wave3:
	Rscript extras/submitCran.R wave3

cran-all:
	Rscript extras/submitCran.R all

# Python Environment Management
venv:
	@test -d $(VENV) || python3 -m venv $(VENV)
	@$(PYTHON) -m pip install --upgrade pip

py-deps: venv
	@$(PIP) install -r requirements.txt

# Airflow DAG & ETL Pipeline Orchestration
dag-test: venv
	PYTHONPATH=. $(PYTHON) $(COHORT_COSTS)/dags/cost_extraction_dag.py

dag-run dag-airflow: venv
	@TMPDIR=$$(mktemp -d -t airflow_hermes_XXXXXX); \
	trap 'rm -rf "$$TMPDIR"' EXIT; \
	AIRFLOW_HOME="$$TMPDIR" AIRFLOW__CORE__DAGS_FOLDER="$(CURDIR)/$(COHORT_COSTS)/dags" $(AIRFLOW) db migrate > /dev/null 2>&1; \
	AIRFLOW_HOME="$$TMPDIR" AIRFLOW__CORE__DAGS_FOLDER="$(CURDIR)/$(COHORT_COSTS)/dags" PYTHONPATH="$(CURDIR)" $(AIRFLOW) dags test hermes_cost_catalogs_etl 2026-01-01

etl-download: venv
	PYTHONPATH=. $(PYTHON) $(COHORT_COSTS)/scripts/download_costs_sources.py

etl-scrape: venv
	PYTHONPATH=. $(PYTHON) $(COHORT_COSTS)/scripts/scrape_costs_es.py

etl-report: venv
	PYTHONPATH=. $(PYTHON) $(COHORT_COSTS)/scripts/generate_eda_report.py
	PYTHONPATH=. $(PYTHON) $(COHORT_COSTS)/scripts/build_dashboard_html.py

etl-all: etl-download etl-scrape etl-report

clean:
	rm -rf *.tar.gz *.Rcheck packages/*/*.tar.gz packages/*/*.Rcheck Rplots.pdf packages/*/Rplots.pdf packages/*/tests/testthat/Rplots.pdf tests/testthat/Rplots.pdf packages/*/packages
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete 2>/dev/null || true
