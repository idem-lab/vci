make_two_district_inputs <- function() {
  species <- c("gambiae", "funestus")
  vectors <- data.frame(
    location_id = rep(c("d_resistant", "d_susceptible"), each = 2),
    species = rep(species, times = 2),
    abundance = c(8, 2, 8, 2)
  )
  bionomics <- data.frame(
    species = species,
    host_indoor = c(0.83, 0.82),
    host_outdoor = c(0.09, 0.12),
    host_animal = c(0.08, 0.06),
    net_contact = c(0.85, 0.78),
    attempted_rate = c(1 / 3, 1 / 3),
    baseline_hazard = c(0.132, 0.112),
    infection_probability = c(0.5, 0.5),
    eip = c(10, 10)
  )
  sites <- data.frame(
    location_id = c("d_resistant", "d_susceptible"),
    susceptibility = c(0.15, 0.90),
    net_use = c(0.8, 0.8)
  )
  vci_inputs(vectors, bionomics, sites)
}

test_that("compute_capacity returns a tidy district x scenario table", {
  cap <- compute_capacity(make_two_district_inputs())
  expect_named(cap, c("location_id", "scenario", "capacity"))
  expect_equal(nrow(cap), 2 * 3) # 2 districts x 3 scenarios
  expect_setequal(cap$scenario, c("none", "bau", "alt"))
  expect_true(all(cap$capacity >= 0))
})

test_that("nets reduce capacity relative to no intervention", {
  cap <- compute_capacity(make_two_district_inputs())
  wide <- reshape(
    cap,
    idvar = "location_id",
    timevar = "scenario",
    direction = "wide"
  )
  expect_true(all(wide$capacity.bau < wide$capacity.none))
  expect_true(all(wide$capacity.alt < wide$capacity.none))
})

test_that("dual-AI reduces capacity more than pyrethroid where resistant", {
  cap <- compute_capacity(make_two_district_inputs())
  wide <- reshape(
    cap,
    idvar = "location_id",
    timevar = "scenario",
    direction = "wide"
  )
  resistant <- wide[wide$location_id == "d_resistant", ]
  expect_lt(resistant$capacity.alt, resistant$capacity.bau)
})

test_that("vci_by_scenario gives 0 for the reference and (0,1) for reductions", {
  cap <- compute_capacity(make_two_district_inputs())
  v <- vci_by_scenario(cap, reference = "none")
  expect_named(v, c("location_id", "scenario", "vci"))
  expect_true(all(v$vci[v$scenario == "none"] == 0))
  bau <- v$vci[v$scenario == "bau"]
  expect_true(all(bau > 0 & bau < 1))
})

test_that("dual-AI VCI is at least pyrethroid VCI everywhere", {
  cap <- compute_capacity(make_two_district_inputs())
  v <- vci_by_scenario(cap, reference = "none")
  wide <- reshape(
    v[v$scenario != "none", ],
    idvar = "location_id",
    timevar = "scenario",
    direction = "wide"
  )
  expect_true(all(wide$vci.alt >= wide$vci.bau))
})

test_that("an unknown reference scenario is an error", {
  cap <- compute_capacity(make_two_district_inputs())
  expect_error(vci_by_scenario(cap, reference = "nope"), "nope")
})

test_that("compute_capacity rejects a non-vci_inputs object", {
  expect_error(compute_capacity(list(a = 1)), "vci_inputs")
})
