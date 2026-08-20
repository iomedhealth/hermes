#' Create Infusion Administration Episode Cohorts
#'
#' @param cdm A `cdm_reference` object.
#' @param name String specifying the cohort table name in the write schema.
#' @param conceptSet Optional concept set / codelist of specific infused drugs.
#' @param routeConceptIds Integer vector of OMOP route concept IDs. Default: `c(4171047L, 4171048L)`.
#' @param collapseGap Maximum gap in days between contiguous administration records to collapse. Default: `0L`.
#'
#' @return An `omopgenerics::cohort_table` object.
#' @export
computeInfusionCohorts <- function(
  cdm,
  name,
  conceptSet = NULL,
  routeConceptIds = c(4171047L, 4171048L),
  collapseGap = 0L
) {
  # ponytail: filter drug_exposure by route, collapse via gap, return cohort_table
  omopgenerics::assertCharacter(name, length = 1)
  omopgenerics::assertClass(cdm, "cdm_reference")
  routeConceptIds <- as.integer(routeConceptIds)
  collapseGap <- as.integer(collapseGap)

  if (!"drug_exposure" %in% names(cdm)) {
    cli::cli_abort("Missing 'drug_exposure' table in CDM.")
  }

  drugs <- cdm$drug_exposure
  if (!is.null(conceptSet)) {
    cs_ids <- as.integer(unlist(conceptSet))
    drugs <- drugs |> dplyr::filter(.data$drug_concept_id %in% cs_ids)
  }

  d_cols <- colnames(drugs)
  if ("route_concept_id" %in% d_cols) {
    drugs <- drugs |> dplyr::filter(.data$route_concept_id %in% routeConceptIds)
  }

  raw_episodes <- drugs |>
    dplyr::select(
      subject_id = "person_id",
      cohort_start_date = "drug_exposure_start_date",
      cohort_end_date = "drug_exposure_end_date"
    ) |>
    dplyr::mutate(
      cohort_end_date = dplyr::coalesce(.data$cohort_end_date, .data$cohort_start_date),
      cohort_definition_id = 1L
    ) |>
    dplyr::collect()

  if (nrow(raw_episodes) == 0) {
    empty_df <- tibble::tibble(
      cohort_definition_id = integer(),
      subject_id = integer(),
      cohort_start_date = as.Date(character()),
      cohort_end_date = as.Date(character())
    )
    cdm <- omopgenerics::insertTable(cdm = cdm, name = name, table = empty_df, overwrite = TRUE)
    cohort_set <- dplyr::tibble(cohort_definition_id = 1L, cohort_name = "infusion_episode")
    return(omopgenerics::newCohortTable(cdm[[name]], cohortSetRef = cohort_set, .softValidation = TRUE))
  }

  # Collapse contiguous records by gap
  collapsed <- raw_episodes |>
    dplyr::arrange(.data$subject_id, .data$cohort_start_date, .data$cohort_end_date) |>
    dplyr::group_by(.data$subject_id) |>
    dplyr::mutate(
      prev_end = dplyr::lag(.data$cohort_end_date),
      new_episode = dplyr::if_else(
        dplyr::row_number() == 1L | .data$cohort_start_date > .data$prev_end + collapseGap + 1L,
        1L,
        0L
      ),
      episode_id = cumsum(.data$new_episode)
    ) |>
    dplyr::group_by(.data$subject_id, .data$episode_id) |>
    dplyr::summarise(
      cohort_start_date = min(.data$cohort_start_date, na.rm = TRUE),
      cohort_end_date = max(.data$cohort_end_date, na.rm = TRUE),
      .groups = "drop"
    ) |>
    dplyr::mutate(cohort_definition_id = 1L) |>
    dplyr::select("cohort_definition_id", "subject_id", "cohort_start_date", "cohort_end_date")

  cdm <- omopgenerics::insertTable(cdm = cdm, name = name, table = collapsed, overwrite = TRUE)
  cohort_set <- dplyr::tibble(cohort_definition_id = 1L, cohort_name = "infusion_episode")
  omopgenerics::newCohortTable(cdm[[name]], cohortSetRef = cohort_set, .softValidation = TRUE)
}
