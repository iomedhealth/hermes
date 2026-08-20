#' Add Outpatient and Emergency Visits to a Cohort
#'
#' @param x A cohort table or cdm_table.
#' @param indexDate Date variable in `x` anchoring the observation window. Default: `"cohort_start_date"`.
#' @param censorDate Optional date variable in `x` to censor observation.
#' @param window A named or unnamed list of 2-element numeric vectors. Default: `list(c(-365, -1), c(0, 365))`.
#' @param stratifySpecialty Logical; whether to partition visits by GP vs Specialist vs ED. Default: `TRUE`.
#' @param gpSpecialtyConceptIds OMOP provider specialty concept IDs for General Practice. Default: `c(38004446L)`.
#' @param nameStyle Column naming pattern. Default: `"{setting}_visits_{window_name}"`.
#' @param name Name of the new table in the write schema. If NULL, a temporary table is returned.
#'
#' @return The cohort table `x` with added outpatient visit metric columns.
#' @export
addOutpatientVisits <- function(
  x,
  indexDate = "cohort_start_date",
  censorDate = NULL,
  window = list(c(-365, -1), c(0, 365)),
  stratifySpecialty = TRUE,
  gpSpecialtyConceptIds = c(38004446L),
  nameStyle = "{setting}_visits_{window_name}",
  name = NULL
) {
  # ponytail: windowed dbplyr query against visit_occurrence + provider with 0-fill
  if (!inherits(x, "cdm_table") && !inherits(x, "cohort_table") && !inherits(x, "tbl_dbi")) {
    cli::cli_abort("Argument 'x' must be a cdm_table or cohort_table.")
  }

  cdm <- omopgenerics::cdmReference(x)
  indexDate <- validateIndexDate(indexDate, x)
  censorDate <- validateCensorDate(censorDate, x)
  clean_window <- validateWindow(window)
  name <- validateName(name)

  gpSpecialtyConceptIds <- as.integer(gpSpecialtyConceptIds)
  x_cols <- colnames(x)
  person_col <- if ("person_id" %in% x_cols) "person_id" else "subject_id"

  cohort_df <- x |> dplyr::collect()
  if (nrow(cohort_df) == 0) {
    return(x)
  }

  provider_df <- if ("provider" %in% names(cdm)) {
    cdm$provider |>
      dplyr::select("provider_id", "specialty_concept_id") |>
      dplyr::collect()
  } else {
    tibble::tibble(provider_id = integer(), specialty_concept_id = integer())
  }

  visit_df <- if ("visit_occurrence" %in% names(cdm)) {
    cdm$visit_occurrence |>
      dplyr::filter(.data$person_id %in% !!unique(cohort_df[[person_col]]) &
        .data$visit_concept_id %in% c(9202L, 9203L, 581477L)) |>
      dplyr::select(
        "visit_occurrence_id",
        person_id = "person_id",
        "visit_concept_id",
        "visit_start_date",
        "provider_id"
      ) |>
      dplyr::collect()
  } else {
    tibble::tibble(
      visit_occurrence_id = integer(), person_id = integer(),
      visit_concept_id = integer(), visit_start_date = as.Date(character()),
      provider_id = integer()
    )
  }

  visit_df <- visit_df |>
    dplyr::left_join(provider_df, by = "provider_id") |>
    dplyr::mutate(
      is_ed = .data$visit_concept_id == 9203L,
      is_gp = .data$visit_concept_id %in% c(9202L, 581477L) &
        (is.na(.data$specialty_concept_id) | .data$specialty_concept_id %in% gpSpecialtyConceptIds),
      is_spec = .data$visit_concept_id %in% c(9202L, 581477L) &
        (!is.na(.data$specialty_concept_id) & !.data$specialty_concept_id %in% gpSpecialtyConceptIds),
      is_other = .data$visit_concept_id %in% c(9202L, 581477L) & !.data$is_gp & !.data$is_spec
    )

  res_list <- list(cohort_df)

  for (win_name in names(clean_window)) {
    win_range <- clean_window[[win_name]]
    w_start <- win_range[1]
    w_end <- win_range[2]

    win_events <- cohort_df |>
      dplyr::inner_join(visit_df, by = c("subject_id" = "person_id")) |>
      dplyr::mutate(
        win_start_dt = as.Date(.data[[indexDate]] + w_start),
        win_end_dt = as.Date(.data[[indexDate]] + w_end),
        cens_dt = if (!is.null(censorDate)) .data[[censorDate]] else as.Date(NA),
        actual_end_dt = if (!is.null(censorDate)) pmin(.data$win_end_dt, .data$cens_dt, na.rm = TRUE) else .data$win_end_dt
      ) |>
      dplyr::filter(
        .data$visit_start_date >= .data$win_start_dt &
          .data$visit_start_date <= .data$actual_end_dt
      )

    win_summary <- win_events |>
      dplyr::group_by(.data$subject_id) |>
      dplyr::summarise(
        ed_cnt = sum(ifelse(.data$is_ed, 1L, 0L), na.rm = TRUE),
        gp_cnt = sum(ifelse(.data$is_gp, 1L, 0L), na.rm = TRUE),
        spec_cnt = sum(ifelse(.data$is_spec, 1L, 0L), na.rm = TRUE),
        other_cnt = sum(ifelse(.data$is_other, 1L, 0L), na.rm = TRUE),
        .groups = "drop"
      )

    c_ed <- paste0("emergency_visits_", win_name)
    c_gp <- paste0("gp_visits_", win_name)
    c_spec <- paste0("specialist_visits_", win_name)
    c_other <- paste0("other_outpatient_visits_", win_name)

    names(win_summary)[names(win_summary) == "ed_cnt"] <- c_ed
    names(win_summary)[names(win_summary) == "gp_cnt"] <- c_gp
    names(win_summary)[names(win_summary) == "spec_cnt"] <- c_spec
    names(win_summary)[names(win_summary) == "other_cnt"] <- c_other

    res_list <- c(res_list, list(win_summary))
  }

  final_df <- res_list[[1]]
  for (k in 2:length(res_list)) {
    final_df <- final_df |>
      dplyr::left_join(res_list[[k]], by = "subject_id")
  }

  metric_cols <- setdiff(colnames(final_df), x_cols)
  for (col in metric_cols) {
    final_df[[col]] <- dplyr::coalesce(final_df[[col]], 0L)
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
