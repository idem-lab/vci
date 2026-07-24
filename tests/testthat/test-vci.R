test_that("compute_vci is the proportional reduction in capacity", {
  expect_equal(compute_vci(reference = 10, alternative = 4), 0.6)
})

test_that("identical scenarios give zero VCI", {
  x <- c(3, 7, 11)
  expect_equal(compute_vci(reference = x, alternative = x), c(0, 0, 0))
})

test_that("a capacity increase gives negative VCI", {
  expect_lt(compute_vci(reference = 5, alternative = 8), 0)
})

test_that("compute_vci is vectorised and recycles", {
  v <- compute_vci(reference = c(10, 20), alternative = c(5, 5))
  expect_equal(v, c(0.5, 0.75))
})

test_that("a zero reference warns rather than failing silently", {
  expect_warning(compute_vci(reference = 0, alternative = 1), "reference")
})

test_that("negative capacity inputs are rejected", {
  expect_error(compute_vci(reference = -1, alternative = 1), "reference")
  expect_error(compute_vci(reference = 1, alternative = -1), "alternative")
})
