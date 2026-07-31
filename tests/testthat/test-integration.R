# End-to-end integration test for the Milestone 0 smoke test (issue #45), on the
# pinned, committed `rwanda_inputs` dataset. Illustrative only.

test_that("the three-scenario Rwanda run executes end to end", {
  cap <- compute_capacity(rwanda_inputs)
  expect_equal(nrow(cap), 30 * 3) # 30 districts x 3 scenarios
  expect_setequal(cap$scenario, c("none", "bau", "alt"))
  expect_true(all(is.finite(cap$capacity)))
  expect_true(all(cap$capacity > 0))
})

test_that("scientific invariants hold on the Rwanda inputs", {
  cap <- compute_capacity(rwanda_inputs)
  v_none <- vci_by_scenario(cap, reference = "none")

  # identical reference scenario gives exactly zero
  expect_true(all(v_none$vci[v_none$scenario == "none"] == 0))

  # business-as-usual is a genuine reduction in (0, 1) in every district
  bau <- v_none$vci[v_none$scenario == "bau"]
  expect_true(all(bau > 0 & bau < 1))

  # dual-AI is at least as impactful as pyrethroid everywhere (resistance)
  wide <- reshape(
    v_none[v_none$scenario != "none", ],
    idvar = "location_id",
    timevar = "scenario",
    direction = "wide"
  )
  expect_true(all(wide$vci.alt >= wide$vci.bau))
})

test_that("VCI is invariant to the absolute level of abundance (issue #63)", {
  scaled <- rwanda_inputs
  scaled$vectors$abundance <- scaled$vectors$abundance * 10

  base <- vci_by_scenario(compute_capacity(rwanda_inputs), "none")
  ten <- vci_by_scenario(compute_capacity(scaled), "none")
  expect_equal(ten$vci, base$vci)
})

test_that("district VCI matches the pinned snapshot", {
  cap <- compute_capacity(rwanda_inputs)
  v_none <- vci_by_scenario(cap, reference = "none")
  wide <- reshape(
    v_none[v_none$scenario != "none", ],
    idvar = "location_id",
    timevar = "scenario",
    direction = "wide"
  )
  wide <- wide[order(wide$location_id), ]
  snapshot <- data.frame(
    location_id = wide$location_id,
    vci_bau = round(wide$vci.bau, 4),
    vci_alt = round(wide$vci.alt, 4),
    row.names = NULL
  )
  expect_snapshot_value(snapshot, style = "json2")
})
