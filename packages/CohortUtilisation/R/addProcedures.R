#' Add Diagnostic Measurements and Procedure Occurrences to a Cohort
#'
#' @param x A cohort table or cdm_table.
#' @param indexDate Date variable in `x` anchoring the observation window. Default: `"cohort_start_date"`.
#' @param censorDate Optional date variable in `x` to censor observation.
#' @param window A named or unnamed list of 2-element numeric vectors. Default: `list(c(-365, -1), c(0, 365))`.
#' @param labConceptSet Optional concept set / codelist for laboratory tests in `measurement`.
#' @param imagingConceptSet Optional concept set / codelist for imaging scans in `procedure_occurrence`.
#' @param procedureConceptSet Optional concept set / codelist for procedures in `procedure_occurrence`.
#' @param nameStyle Column naming pattern. Default: `"{metric}_count_{window_name}"`.
#' @param name Name of the new table in the write schema. If NULL, a temporary table is returned.
#'
#' @return The cohort table `x` with added procedure and diagnostic metric columns.
#' @export
addProcedures <- function(
  x,
  indexDate = "cohort_start_date",
  censorDate = NULL,
  window = list(c(-365, -1), c(0, 365)),
  labConceptSet = NULL,
  imagingConceptSet = NULL,
  procedureConceptSet = NULL,
  nameStyle = "{metric}_count_{window_name}",
  name = NULL
) {
  # ponytail: windowed dbplyr query against procedure_occurrence and measurement with 0-fill
  if (!inherits(x, "cdm_table") && !inherits(x, "cohort_table") && !inherits(x, "tbl_dbi")) {
    cli::cli_abort("Argument 'x' must be a cdm_table or cohort_table.")
  }

  cdm <- omopgenerics::cdmReference(x)
  indexDate <- validateIndexDate(indexDate, x)
  censorDate <- validateCensorDate(censorDate, x)
  clean_window <- validateWindow(window)
  name <- validateName(name)

  x_cols <- colnames(x)
  person_col <- if ("person_id" %in% x_cols) "person_id" else "subject_id"

  cohort_df <- x |> dplyr::collect()
  if (nrow(cohort_df) == 0) {
    return(x)
  }

  proc_df <- if ("procedure_occurrence" %in% names(cdm)) {
    p <- cdm$procedure_occurrence |>
      dplyr::filter(.data$person_id %in% !!unique(cohort_df[[person_col]]))

    if (!is.null(procedureConceptSet)) {
      p_ids <- as.integer(unlist(procedureConceptSet))
      p <- p |> dplyr::filter(.data$procedure_concept_id %in% p_ids)
    }

    p |>
      dplyr::select(
        "procedure_occurrence_id",
        person_id = "person_id",
        "procedure_concept_id",
        "procedure_date"
      ) |>
      dplyr::collect()
  } else {
    tibble::tibble(
      procedure_occurrence_id = integer(), person_id = integer(),
      procedure_concept_id = integer(), procedure_date = as.Date(character())
    )
  }

  meas_df <- if ("measurement" %in% names(cdm)) {
    m <- cdm$measurement |>
      dplyr::filter(.data$person_id %in% !!unique(cohort_df[[person_col]]))

    if (!is.null(labConceptSet)) {
      m_ids <- as.integer(unlist(labConceptSet))
      m <- m |> dplyr::filter(.data$measurement_concept_id %in% m_ids)
    }

    m |>
      dplyr::select(
        "measurement_id",
        person_id = "person_id",
        "measurement_concept_id",
        "measurement_date"
      ) |>
      dplyr::collect()
  } else {
    tibble::tibble(
      measurement_id = integer(), person_id = integer(),
      measurement_concept_id = integer(), measurement_date = as.Date(character())
    )
  }

  res_list <- list(cohort_df)

  for (win_name in names(clean_window)) {
    win_range <- clean_window[[win_name]]
    w_start <- win_range[1]
    w_end <- win_range[2]

    win_procs <- cohort_df |>
      dplyr::inner_join(proc_df, by = c("subject_id" = "person_id")) |>
      dplyr::mutate(
        win_start_dt = as.Date(.data[[indexDate]] + w_start),
        win_end_dt = as.Date(.data[[indexDate]] + w_end),
        cens_dt = if (!is.null(censorDate)) .data[[censorDate]] else as.Date(NA),
        actual_end_dt = if (!is.null(censorDate)) pmin(.data$win_end_dt, .data$cens_dt, na.rm = TRUE) else .data$win_end_dt
      ) |>
      dplyr::filter(
        .data$procedure_date >= .data$win_start_dt &
          .data$procedure_date <= .data$actual_end_dt
      )

    win_proc_sum <- win_procs |>
      dplyr::group_by(.data$subject_id) |>
      dplyr::summarise(proc_cnt = dplyr::n(), .groups = "drop")

    win_meas <- cohort_df |>
      dplyr::inner_join(meas_df, by = c("subject_id" = "person_id")) |>
      dplyr::mutate(
        win_start_dt = as.Date(.data[[indexDate]] + w_start),
        win_end_dt = as.Date(.data[[indexDate]] + w_end),
        cens_dt = if (!is.null(censorDate)) .data[[censorDate]] else as.Date(NA),
        actual_end_dt = if (!is.null(censorDate)) pmin(.data$win_end_dt, .data$cens_dt, na.rm = TRUE) else .data$win_end_dt
      ) |>
      dplyr::filter(
        .data$measurement_date >= .data$win_start_dt &
          .data$measurement_date <= .data$actual_end_dt
      )

    win_meas_sum <- win_meas |>
      dplyr::group_by(.data$subject_id) |>
      dplyr::summarise(lab_cnt = dplyr::n(), .groups = "drop")

    c_lab <- paste0("lab_tests_count_", win_name)
    c_proc <- paste0("procedures_count_", win_name)

    names(win_meas_sum)[names(win_meas_sum) == "lab_cnt"] <- c_lab
    names(win_proc_sum)[names(win_proc_sum) == "proc_cnt"] <- c_proc

    win_combined <- dplyr::full_join(win_meas_sum, win_proc_sum, by = "subject_id")
    res_list <- c(res_list, list(win_combined))
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
