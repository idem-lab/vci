test_that("host_destination returns pre-intervention shares when accessibility is 1", {
  d <- host_destination(
    indoor = 2,
    outdoor = 1,
    animal = 1,
    residual_accessibility = 1
  )
  expect_equal(d$indoor, 0.5)
  expect_equal(d$outdoor, 0.25)
  expect_equal(d$animal, 0.25)
})

test_that("destination probabilities always sum to one", {
  d <- host_destination(2, 1, 1, residual_accessibility = 0.4)
  expect_equal(d$indoor + d$outdoor + d$animal, 1)
})

test_that("repellency redistributes attempts away from indoors", {
  d <- host_destination(2, 1, 1, residual_accessibility = 0.5)
  # with accessibility one half, the normalising denominator is three
  expect_equal(d$indoor, (0.5 * 2) / 3)
  expect_equal(d$outdoor, 1 / 3)
  expect_equal(d$animal, 1 / 3)
})

test_that("host_destination is vectorised over inputs", {
  d <- host_destination(c(2, 4), 1, 1, residual_accessibility = 1)
  expect_equal(d$indoor, c(2 / 4, 4 / 6))
})

test_that("successful_feeding_rate follows the maths spec: indoor + outdoor only", {
  a <- successful_feeding_rate(
    attempted_rate = 0.3,
    indoor_destination = 0.5,
    outdoor_destination = 0.25,
    indoor_survival = 1,
    outdoor_survival = 1,
    indoor_feeding = 1,
    outdoor_efficiency = 1
  )
  expect_equal(a, 0.3 * (0.5 + 0.25))
})

test_that("indoor killing and barrier reduce successful feeding", {
  a <- successful_feeding_rate(
    0.3,
    0.5,
    0.25,
    indoor_survival = 0.5,
    indoor_feeding = 0.4
  )
  expect_equal(a, 0.3 * (0.5 * 0.5 * 0.4 + 0.25))
})

test_that("animal-directed attempts never contribute to human feeding", {
  a <- successful_feeding_rate(0.3, 0.5, 0.25, indoor_survival = 0)
  expect_equal(a, 0.3 * 0.25)
})

test_that("mortality_hazard is the baseline when there is no intervention killing", {
  mu <- mortality_hazard(
    baseline_hazard = 0.12,
    attempted_rate = 0.3,
    indoor_destination = 0.5,
    outdoor_destination = 0.25,
    animal_destination = 0.25
  )
  expect_equal(mu, 0.12)
})

test_that("indoor and animal killing both raise the mortality hazard", {
  mu <- mortality_hazard(
    0.12,
    0.3,
    0.5,
    0.25,
    0.25,
    indoor_survival = 0.5,
    animal_survival = 0.8
  )
  expect_equal(mu, 0.12 + 0.3 * (0.5 * 0.5 + 0.25 * 0.2))
})

test_that("survival_probability is exp(-hazard) over the interval", {
  expect_equal(survival_probability(0.12), exp(-0.12))
  expect_equal(survival_probability(0.12, interval = 2), exp(-0.24))
})
