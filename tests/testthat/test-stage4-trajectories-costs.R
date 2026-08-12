test_that("Stage 4 trajectories works", {
  cdm <- hermes_test_cdm()
  study <- init(cdm)
  traj <- compile_trajectories(study)
  expect_true(inherits(traj, "hermes_trajectories"))
})
