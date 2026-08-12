# ponytail: minimal s3 constructors, add validation when properties dictate it
new_hermes_study <- function(x = list()) {
  structure(x, class = c("hermes_study", "list"))
}

new_hermes_hcru <- function(x = list()) {
  structure(x, class = c("hermes_hcru", "hermes_study", "list"))
}

new_hermes_ps <- function(x = list()) {
  structure(x, class = c("hermes_ps", "hermes_study", "list"))
}

new_hermes_trajectories <- function(x = list()) {
  structure(x, class = c("hermes_trajectories", "hermes_study", "list"))
}

new_hermes_sim <- function(x = list()) {
  structure(x, class = c("hermes_sim", "hermes_study", "list"))
}

new_hermes_cea <- function(x = list()) {
  structure(x, class = c("hermes_cea", "hermes_study", "list"))
}
