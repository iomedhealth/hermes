# Please work through the below before pushing any changes to github

# 1) run all testthat tests (after reloading with current code) - do all pass?
devtools::test()

# 2) check code coverage - are all functions covered 100%?
# detach("package:HERMES", unload = TRUE)
# devtools::test_coverage()
# for more coverage details uncomment the following
# covr::report()
# cov <- covr::package_coverage(here::here())
# covr::zero_coverage(cov)

# 3) run all examples - do they all run without error?
devtools::run_examples()

# 4) check spelling throughout - any obvious typos to fix?
devtools::spell_check()
# spelling::update_wordlist() # if they are not true spelling mistakes we can add them to our wordlist

# 5) Check documentation (as R CMD check)
devtools::check_man()

# 6) fuller checks - any warnings or notes to be fixed?
devtools::check()

# 7) have you followed the style guide?
# note you can use styler to fix formatting
lintr::lint_package(".",
  linters = lintr::linters_with_defaults(
    lintr::object_name_linter(styles = "camelCase")
  )
)

# 8) Rebuild readme
devtools::build_readme()

# 9) Document package
devtools::document() # Use roxygen to document a package.

# 10) Check website locally (if pkgdown configured)
# pkgdown::build_site()

# 11) Phased CRAN Submission via extras/submitCran.R (or make targets)
# make cran-dry-run        # Verify all tarballs & cran-comments
# make cran-wave1          # Submit CohortUtilisation & CohortCosts
# make cran-wave2          # Submit CohortEconomics (after wave 1 acceptance)
# make cran-wave3          # Submit omopHeor root (after wave 2 acceptance)

# 12) Python & Airflow ETL Pipelines (CohortCosts)
# make venv                # Initialize Python virtual environment (.venv)
# make py-deps             # Install Python requirements
# make dag-test            # Local test of cost_extraction_dag without Airflow scheduler
# make dag-run             # Airflow CLI DAG test run
# make etl-download        # Download raw gazettes & INE series
# make etl-scrape          # Run cost scraping & normalization
# make etl-report          # Generate EDA markdown report & HTML dashboard
# make etl-all             # End-to-end data pipeline
