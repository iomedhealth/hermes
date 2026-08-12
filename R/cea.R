# ponytail: minimal cea wrappers
compute_cea <- function(study) {
  # ponytail: mocked BCEA object using real BCEA::bcea until Stage 5 sim is implemented
  e <- matrix(rnorm(200, mean = 0.5, sd = 0.1), ncol = 2)
  c <- matrix(rnorm(200, mean = 1000, sd = 100), ncol = 2)
  mock_bcea <- BCEA::bcea(e, c)
  new_hermes_cea(c(study, list(cea_results = mock_bcea)))
}
plot_ceac <- function(study) BCEA::ceac.plot(study$cea_results)
plot_plane <- function(study) BCEA::ceplane.plot(study$cea_results)
table_summary <- function(study) summary(study$cea_results)
