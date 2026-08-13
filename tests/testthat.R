library(testthat)
library(HERMES)

# Verify required dependencies for Stages 4 and 5
requireNamespace("Cohort2Trajectory", quietly = TRUE)
requireNamespace("TrajectoryMarkovAnalysis", quietly = TRUE)
requireNamespace("hesim", quietly = TRUE)
requireNamespace("BCEA", quietly = TRUE)

test_check("HERMES")
