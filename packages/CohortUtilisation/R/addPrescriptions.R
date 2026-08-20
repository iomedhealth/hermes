#' Add Prescription and Medication Metrics to a Cohort
#'
#' @param x A cohort table or cdm_table.
#' @param indexDate Date variable in `x` anchoring the observation window. Default: `"cohort_start_date"`.
#' @param censorDate Optional date variable in `x` to censor observation.
#' @param window A named or unnamed list of 2-element numeric vectors. Default: `list(c(-365, -1), c(0, 365))`.
#' @param conceptSet Optional concept set / codelist of specific drugs.
#' @param infusionRouteConceptIds OMOP route concept IDs for parenteral/IV infusions. Default: `c(4171047L, 4171048L)`.
#' @param daysSupply Logical; whether to compute cumulative days supply. Default: `TRUE`.
#' @param pdc Logical; whether to compute Proportion of Days Covered. Default: `FALSE`.
#' @param nameStyle Column naming pattern. Default: `"{metric}_{window_name}"`.
#' @param name Name of the new table in the write schema. If NULL, a temporary table is returned.
#'
#' @return The cohort table `x` with added prescription metric columns.
#' @export
addPrescriptions <- function(
  x,
  indexDate = "cohort_start_date",
  censorDate = NULL,
  window = list(c(-365, -1), c(0, 365)),
  conceptSet = NULL,
  infusionRouteConceptIds = c(4171047L, 4171048L),
  daysSupply = TRUE,
  pdc = FALSE,
  nameStyle = "{metric}_{window_name}",
  name = NULL
) {
  # ponytail: windowed dbplyr query against drug_exposure with fills, days supply, pdc, and infusions
  if (!inherits(x, "cdm_table") && !inherits(x, "cohort_table") && !inherits(x, "tbl_dbi")) {
    cli::cli_abort("Argument 'x' must be a cdm_table or cohort_table.")
  }

  cdm <- omopgenerics::cdmReference(x)
  indexDate <- validateIndexDate(indexDate, x)
  censorDate <- validateCensorDate(censorDate, x)
  clean_window <- validateWindow(window)
  name <- validateName(name)

  infusionRouteConceptIds <- as.integer(infusionRouteConceptIds)
  x_cols <- colnames(x)
  person_col <- if ("person_id" %in% x_cols) "person_id" else "subject_id"

  cohort_df <- x |> dplyr::collect()
  if (nrow(cohort_df) == 0) {
    return(x)
  }

  drug_df <- if ("drug_exposure" %in% names(cdm)) {
    d <- cdm$drug_exposure |>
      dplyr::filter(.data$person_id %in% !!unique(cohort_df[[person_col]]))

    if (!is.null(conceptSet)) {
      cs_ids <- as.integer(unlist(conceptSet))
      d <- d |> dplyr::filter(.data$drug_concept_id %in% cs_ids)
    }

    d_cols <- colnames(d)
    has_route <- "route_concept_id" %in% d_cols
    has_days <- "days_supply" %in% d_cols

    d |>
      dplyr::select(
        "drug_exposure_id",
        person_id = "person_id",
        "drug_concept_id",
        "drug_exposure_start_date",
        dplyr::any_of(c("days_supply", "route_concept_id"))
      ) |>
      dplyr::collect() |>
      dplyr::mutate(
        days_supply = if (has_days) dplyr::coalesce(as.numeric(.data$days_supply), 0) else 0,
        route_concept_id = if (has_route) as.integer(.data$route_concept_id) else NA_integer_
      )
  } else {
    tibble::tibble(
      drug_exposure_id = integer(), person_id = integer(),
      drug_concept_id = integer(), drug_exposure_start_date = as.Date(character()),
      days_supply = numeric(), route_concept_id = integer()
    )
  }

  drug_df <- drug_df |>
    dplyr::mutate(
      is_infusion = !is.na(.data$route_concept_id) & .data$route_concept_id %in% infusionRouteConceptIds
    )

  res_list <- list(cohort_df)

  for (win_name in names(clean_window)) {
    win_range <- clean_window[[win_name]]
    w_start <- win_range[1]
    w_end <- win_range[2]
    win_len <- abs(w_end - w_start) + 1

    win_events <- cohort_df |>
      dplyr::inner_join(drug_df, by = c("subject_id" = "person_id")) |>
      dplyr::mutate(
        win_start_dt = as.Date(.data[[indexDate]] + w_start),
        win_end_dt = as.Date(.data[[indexDate]] + w_end),
        cens_dt = if (!is.null(censorDate)) .data[[censorDate]] else as.Date(NA),
        actual_end_dt = if (!is.null(censorDate)) pmin(.data$win_end_dt, .data$cens_dt, na.rm = TRUE) else .data$win_end_dt
      ) |>
      dplyr::filter(
        .data$drug_exposure_start_date >= .data$win_start_dt &
          .data$drug_exposure_start_date <= .data$actual_end_dt
      )

    win_summary <- win_events |>
      dplyr::group_by(.data$subject_id) |>
      dplyr::summarise(
        rx_cnt = dplyr::n(),
        days_sup = sum(.data$days_supply, na.rm = TRUE),
        inf_cnt = sum(ifelse(.data$is_infusion, 1L, 0L), na.rm = TRUE),
        .groups = "drop"
      )

    c_rx <- paste0("rx_fills_", win_name)
    c_days <- paste0("days_supply_", win_name)
    c_pdc <- paste0("pdc_", win_name)
    c_inf <- paste0("infusions_", win_name)

    names(win_summary)[names(win_summary) == "rx_cnt"] <- c_rx
    names(win_summary)[names(win_summary) == "days_sup"] <- c_days
    names(win_summary)[names(win_summary) == "inf_cnt"] <- c_inf

    if (pdc) {
      win_summary[[c_pdc]] <- if (is.infinite(win_len)) 0.0 else pmin(1.0, win_summary[[c_days]] / win_len)
    }

    res_list <- c(res_list, list(win_summary))
  }

  final_df <- res_list[[1]]
  for (k in 2:length(res_list)) {
    final_df <- final_df |>
      dplyr::left_join(res_list[[k]], by = "subject_id")
  }

  metric_cols <- setdiff(colnames(final_df), x_cols)
  for (col in metric_cols) {
    if (grepl("^pdc_", col)) {
      final_df[[col]] <- dplyr::coalesce(final_df[[col]], 0.0)
    } else {
      final_df[[col]] <- dplyr::coalesce(final_df[[col]], 0L)
    }
  }

  table_name <- if (!is.null(name)) name else omopgenerics::uniqueTableName(omopgenerics::tmpPrefix())
  cdm <- omopgenerics::insertTable(cdm = cdm, name = table_name, table = final_df, overwrite = TRUE)
  if (inherits(x, "cohort_table")) {
    cdm[[table_name]] <- omopgenerics::newCohortTable(
      cdm[[table_name]],
      cohortSetRef = attr(x, "cohort_set"),
      cohortAttritionRef = attr(x, "cohort_attrition"),
      .softValidation = TRUE
    )
  }
  cdm[[table_name]]
}
