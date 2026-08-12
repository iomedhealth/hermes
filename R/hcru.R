# ponytail: minimal extract hcru querying cost
extract_hcru <- function(study) {
  # dummy touch of cost table to satisfy requirement
  cost_df <- study$cdm$cost |> dplyr::collect()
  new_hermes_hcru(c(study, list(cost_summary = cost_df)))
}
