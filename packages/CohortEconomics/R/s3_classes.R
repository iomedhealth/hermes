# ponytail: minimal s3 constructors with omopheor and hermes backward compatibility
new_hermes_study <- new_omopheor_study <- function(x = list()) {
  structure(x, class = c("omopheor_study", "hermes_study", "list"))
}

new_hermes_hcru <- new_omopheor_hcru <- function(x = list()) {
  structure(x, class = c("omopheor_hcru", "hermes_hcru", "omopheor_study", "hermes_study", "list"))
}

new_hermes_ps <- new_omopheor_ps <- function(x = list()) {
  structure(x, class = c("omopheor_ps", "hermes_ps", "omopheor_study", "hermes_study", "list"))
}

new_hermes_trajectories <- new_omopheor_trajectories <- function(x = list()) {
  structure(x, class = c("omopheor_trajectories", "hermes_trajectories", "omopheor_study", "hermes_study", "list"))
}

new_hermes_sim <- new_omopheor_sim <- function(x = list()) {
  structure(x, class = c("omopheor_sim", "hermes_sim", "omopheor_study", "hermes_study", "list"))
}

new_hermes_cea <- new_omopheor_cea <- function(x = list()) {
  structure(x, class = c("omopheor_cea", "hermes_cea", "omopheor_study", "hermes_study", "list"))
}
