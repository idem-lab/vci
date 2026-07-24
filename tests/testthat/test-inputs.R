make_valid_inputs <- function() {
  vectors <- data.frame(
    location_id = rep(c("d1", "d2"), each = 2),
    species = rep(c("gambiae", "funestus"), times = 2),
    abundance = c(8, 2, 6, 3)
  )
  bionomics <- data.frame(
    species = c("gambiae", "funestus"),
    host_indoor = c(0.8, 0.8),
    host_outdoor = c(0.1, 0.1),
    host_animal = c(0.1, 0.1),
    net_contact = c(0.85, 0.78),
    baseline_hazard = c(0.132, 0.112),
    infection_probability = c(0.5, 0.5)
  )
  sites <- data.frame(
    location_id = c("d1", "d2"),
    susceptibility = c(0.3, 0.6),
    net_use = c(0.7, 0.5),
    temperature = c(24, 21)
  )
  list(vectors = vectors, bionomics = bionomics, sites = sites)
}

test_that("vci_inputs builds a validated object", {
  i <- make_valid_inputs()
  x <- vci_inputs(i$vectors, i$bionomics, i$sites)
  expect_s3_class(x, "vci_inputs")
  expect_equal(nrow(x$vectors), 4)
  expect_null(x$geometry)
})

test_that("a missing required column is reported by name", {
  i <- make_valid_inputs()
  i$sites$net_use <- NULL
  expect_error(vci_inputs(i$vectors, i$bionomics, i$sites), "net_use")
})

test_that("out-of-range susceptibility is rejected", {
  i <- make_valid_inputs()
  i$sites$susceptibility[1] <- 1.5
  expect_error(vci_inputs(i$vectors, i$bionomics, i$sites), "susceptibility")
})

test_that("missing values are rejected (no silent imputation)", {
  i <- make_valid_inputs()
  i$sites$net_use[2] <- NA
  expect_error(vci_inputs(i$vectors, i$bionomics, i$sites), "net_use")
})

test_that("a vector species without bionomics is rejected", {
  i <- make_valid_inputs()
  i$vectors$species[1] <- "arabiensis"
  expect_error(vci_inputs(i$vectors, i$bionomics, i$sites), "arabiensis")
})

test_that("a vector district without site data is rejected", {
  i <- make_valid_inputs()
  i$vectors$location_id[1] <- "d99"
  expect_error(vci_inputs(i$vectors, i$bionomics, i$sites), "d99")
})

test_that("print summarises the object", {
  i <- make_valid_inputs()
  x <- vci_inputs(i$vectors, i$bionomics, i$sites)
  expect_output(print(x), "vci_inputs")
  expect_output(print(x), "gambiae")
})
