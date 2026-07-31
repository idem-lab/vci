test_that("the 'none' product has no effect, whatever the coverage or resistance", {
  e <- intervention_effect_stub("none", coverage = 0.8, susceptibility = 0.3)
  expect_equal(e$residual_accessibility, 1)
  expect_equal(e$indoor_feeding, 1)
  expect_equal(e$indoor_survival, 1)
  expect_equal(e$outdoor_survival, 1)
  expect_equal(e$animal_survival, 1)
})

test_that("zero coverage means no effect", {
  e <- intervention_effect_stub("pyrethroid", coverage = 0, susceptibility = 1)
  expect_equal(e$residual_accessibility, 1)
  expect_equal(e$indoor_survival, 1)
  expect_equal(e$indoor_feeding, 1)
})

test_that("a pyrethroid net repels, kills and blocks feeding, indoors only", {
  e <- intervention_effect_stub(
    "pyrethroid",
    coverage = 0.8,
    susceptibility = 1
  )
  expect_lt(e$residual_accessibility, 1)
  expect_lt(e$indoor_survival, 1)
  expect_lt(e$indoor_feeding, 1)
  expect_equal(e$outdoor_survival, 1)
  expect_equal(e$animal_survival, 1)
})

test_that("pyrethroid killing collapses as susceptibility falls (resistance rises)", {
  hi <- intervention_effect_stub("pyrethroid", 0.8, susceptibility = 1)
  lo <- intervention_effect_stub("pyrethroid", 0.8, susceptibility = 0.1)
  # less susceptible -> less killing -> higher residual indoor survival
  expect_gt(lo$indoor_survival, hi$indoor_survival)
})

test_that("dual-AI kills more than pyrethroid where resistance is high", {
  s <- 0.1 # highly resistant
  pyr <- intervention_effect_stub("pyrethroid", 0.8, susceptibility = s)
  dual <- intervention_effect_stub("dual_ai", 0.8, susceptibility = s)
  expect_lt(dual$indoor_survival, pyr$indoor_survival)
})

test_that("intervention_effect_stub is vectorised over coverage and susceptibility", {
  e <- intervention_effect_stub(
    "pyrethroid",
    coverage = c(0, 0.8),
    susceptibility = c(1, 1)
  )
  expect_length(e$indoor_survival, 2)
  expect_equal(e$indoor_survival[1], 1) # zero coverage
  expect_lt(e$indoor_survival[2], 1)
})

test_that("an unknown product is an error", {
  expect_error(intervention_effect_stub("ppf_net", 0.5, 0.5))
})
