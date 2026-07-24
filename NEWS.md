# vci 0.0.0.9000

* Added the Milestone 0 smoke test: an end-to-end, **illustrative** district-level
  VCI example for Rwanda, with a vignette (`vignette("rwanda-smoke-test")`) and
  the packaged `rwanda_inputs` dataset (#45).
* Added the computational kernel: `vectorial_capacity()` (the Garrett-Jones
  capacity equation), `sum_species()` (aggregation across species),
  `compute_vci()` (scenario comparison), the host-choice and survival assembly
  (`host_destination()`, `successful_feeding_rate()`, `mortality_hazard()`,
  `survival_probability()`), and `intervention_effect_stub()` (a clearly-labelled
  illustrative intervention mapping).
* Added `vci_inputs()`, the district-level input contract, and the
  `compute_capacity()` / `vci_by_scenario()` pipeline that runs scenarios over it.
* Added temperature-dependent `biting_rate()` and `eip()` (illustrative Brière
  thermal responses), and drove them from a WorldClim temperature layer in the
  Rwanda example so cool, high-altitude districts show low vectorial capacity
  (#64).
