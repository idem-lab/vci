test_that("biting_rate follows a Briere thermal response", {
  # ~0.25 / day near the thermal optimum for An. gambiae (Mordecai et al. 2013)
  expect_gt(biting_rate(26), 0.24)
  expect_lt(biting_rate(26), 0.26)
  # zero at or beyond the thermal limits
  expect_equal(biting_rate(13.35), 0)
  expect_equal(biting_rate(10), 0)
  expect_equal(biting_rate(41), 0)
  # rises with temperature through the cool part of the range
  expect_gt(biting_rate(28), biting_rate(18))
})

test_that("eip is ~11 days near the optimum and lengthens as it cools", {
  expect_gt(eip(26), 9)
  expect_lt(eip(26), 12)
  # cooler -> slower parasite development -> longer EIP
  expect_gt(eip(20), eip(28))
  expect_gt(eip(17), eip(20))
})

test_that("eip is infinite outside the parasite-development range", {
  expect_identical(eip(14), Inf)
  expect_identical(eip(10), Inf)
  expect_identical(eip(35), Inf)
})

test_that("temperature responses are vectorised", {
  b <- biting_rate(c(18, 26))
  expect_length(b, 2)
  expect_lt(b[1], b[2])

  e <- eip(c(20, 28))
  expect_length(e, 2)
  expect_gt(e[1], e[2])
})
