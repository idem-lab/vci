test_that("vectorial_capacity matches the Garrett-Jones form", {
  v <- vectorial_capacity(
    infection_probability = 0.5,
    abundance = 10,
    feeding_rate = 0.3,
    survival = 0.9,
    eip = 10
  )
  expected <- 0.5 * 10 * 0.3^2 * 0.9^10 / (-log(0.9))
  expect_equal(v, expected)
})

test_that("zero abundance or zero feeding gives zero capacity", {
  expect_equal(
    vectorial_capacity(
      0.5,
      abundance = 0,
      feeding_rate = 0.3,
      survival = 0.9,
      eip = 10
    ),
    0
  )
  expect_equal(
    vectorial_capacity(
      0.5,
      abundance = 10,
      feeding_rate = 0,
      survival = 0.9,
      eip = 10
    ),
    0
  )
})

test_that("capacity is linear in abundance", {
  base <- vectorial_capacity(0.5, 10, 0.3, 0.9, 10)
  expect_equal(vectorial_capacity(0.5, 20, 0.3, 0.9, 10), 2 * base)
})

test_that("capacity increases monotonically with survival", {
  lo <- vectorial_capacity(0.5, 10, 0.3, 0.80, 10)
  hi <- vectorial_capacity(0.5, 10, 0.3, 0.95, 10)
  expect_gt(hi, lo)
})

test_that("capacity is vectorised over inputs", {
  v <- vectorial_capacity(
    infection_probability = 0.5,
    abundance = c(10, 20),
    feeding_rate = 0.3,
    survival = c(0.9, 0.9),
    eip = 10
  )
  expect_length(v, 2)
  expect_equal(v[2], 2 * v[1])
})

test_that("survival outside (0, 1) is an error", {
  expect_error(vectorial_capacity(0.5, 10, 0.3, 1, 10), "survival")
  expect_error(vectorial_capacity(0.5, 10, 0.3, 0, 10), "survival")
  expect_error(vectorial_capacity(0.5, 10, 0.3, 1.2, 10), "survival")
})

test_that("negative or invalid inputs are rejected", {
  expect_error(vectorial_capacity(0.5, -1, 0.3, 0.9, 10), "abundance")
  expect_error(vectorial_capacity(0.5, 10, -0.3, 0.9, 10), "feeding_rate")
  expect_error(vectorial_capacity(0.5, 10, 0.3, 0.9, 0), "eip")
  expect_error(
    vectorial_capacity(1.5, 10, 0.3, 0.9, 10),
    "infection_probability"
  )
})
