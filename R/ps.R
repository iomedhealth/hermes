#' Fit Propensity Score Model
#'
#' @export
fit_ps <- function(hcru_obj, ...) {
  # ponytail: minimal CohortMethod/Cyclops wrapper.
  # 365d lookback assumed handled in getDbCohortMethodData creation prior to this.

  model_fit <- NULL
  if (!is.null(hcru_obj$cm_data)) {
    model_fit <- CohortMethod::createPs(
      cohortMethodData = hcru_obj$cm_data,
      prior = Cyclops::createPrior("laplace", useCrossValidation = TRUE),
      control = Cyclops::createControl(cvType = "auto", fold = 10, cvRepetitions = 1)
    )
  }

  structure(
    list(
      model = model_fit,
      hcru_obj = hcru_obj
    ),
    class = "hermes_ps"
  )
}

#' Adjust Propensity Scores
#'
#' @export
adjust_ps <- function(ps_obj, ...) {
  # ponytail: minimal matching wrapper
  matched <- NA
  if (!is.null(ps_obj$model)) {
    matched <- CohortMethod::matchOnPs(ps_obj$model, caliper = 0.2, caliperScale = "standardized logit")
  }

  ps_obj$matched_pop <- matched
  structure(ps_obj, class = "hermes_ps")
}

#' Assess Balance
#'
#' @export
assess_balance <- function(ps_obj, ...) {
  # ponytail: minimal balance wrapper
  smd <- NA
  if (!is.na(ps_obj$matched_pop[1]) && !is.null(ps_obj$hcru_obj$cm_data)) {
    smd <- CohortMethod::computeCovariateBalance(ps_obj$matched_pop, ps_obj$hcru_obj$cm_data)
  }

  ps_obj$smd_summary <- smd
  structure(ps_obj, class = "hermes_ps")
}
