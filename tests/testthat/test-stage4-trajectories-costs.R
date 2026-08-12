test_that("Stage 4 trajectories works", {
  cdm <- hermes_test_cdm()
  study <- init(cdm)
  traj1 <- compile_trajectories(study)
  expect_true(inherits(traj1, "hermes_trajectories"))
  
  traj2 <- extract_state_costs(study)
  expect_true(inherits(traj2, "hermes_trajectories"))
})
