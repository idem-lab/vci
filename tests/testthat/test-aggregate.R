make_capacity <- function() {
  # species (3) x location (2), column-major: district d1 = 1,2,3; d2 = 4,5,6
  array(
    c(1, 2, 3, 4, 5, 6),
    dim = c(3, 2),
    dimnames = list(
      species = c("gambiae", "arabiensis", "funestus"),
      location = c("d1", "d2")
    )
  )
}

test_that("sum_species sums capacity over the species dimension", {
  total <- sum_species(make_capacity())
  expect_equal(total, c(d1 = 6, d2 = 15))
})

test_that("sum_species drops species but keeps the other dimensions", {
  total <- sum_species(make_capacity())
  expect_named(total, c("d1", "d2"))
  expect_length(total, 2)
})

test_that("summation is a plain sum: no composition re-weighting", {
  # Two species contribute V1 and V2; the total is exactly V1 + V2.
  v <- array(
    c(0.4, 0.6),
    dim = c(2, 1),
    dimnames = list(species = c("a", "b"), location = "d1")
  )
  expect_equal(sum_species(v), c(d1 = 1.0))
})

test_that("a single species passes its capacity through unchanged", {
  v <- array(
    c(2, 5),
    dim = c(1, 2),
    dimnames = list(species = "only", location = c("d1", "d2"))
  )
  expect_equal(sum_species(v), c(d1 = 2, d2 = 5))
})

test_that("sum_species requires a named species dimension", {
  x <- matrix(1:6, nrow = 3)
  expect_error(sum_species(x), "species")
})
