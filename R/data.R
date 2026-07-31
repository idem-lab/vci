#' Illustrative district-level inputs for Rwanda (Milestone 0 smoke test)
#'
#' @description
#' A [vci_inputs] object holding district-level (GADM admin-2) inputs for
#' Rwanda's three primary malaria vectors — *Anopheles gambiae*, *An.
#' arabiensis*, and *An. funestus* — assembled for the Milestone 0 end-to-end
#' smoke test.
#'
#' @section Illustrative only:
#' **This is not a real analysis.** It is built from ballpark parameters, a
#' stubbed intervention mapping, and mocked/locally-cached rasters, purely to
#' exercise the pipeline end to end (issue #45). Its numbers must not be read as
#' findings about malaria transmission or vector control in Rwanda.
#'
#' @format A [vci_inputs] object (a list), with:
#' \describe{
#'   \item{`vectors`}{data frame, 90 rows (30 districts x 3 species):
#'     `location_id`, `species`, and `abundance` (relative adults per human).}
#'   \item{`bionomics`}{data frame, one row per species: host-opportunity weights
#'     `host_indoor`, `host_outdoor`, `host_animal` (derived from the
#'     malariasimulation `Q0` and `phi_indoors` under an explicit
#'     equal-host-availability assumption), `net_contact` (`phi_bednets`),
#'     `baseline_hazard` (`mum`), and `infection_probability`.}
#'   \item{`sites`}{data frame, one row per district: `susceptibility` (the
#'     pyrethroid-bioassay mortality fraction, i.e. `1 - resistance`), `net_use`
#'     (2024 net use, used for the business-as-usual scenario), and
#'     `temperature` (annual mean, degrees Celsius). The temperature-driven
#'     biting rate and EIP are derived by [compute_capacity()].}
#'   \item{`geometry`}{an `sf` object of the 30 district polygons, keyed by
#'     `location_id`, for mapping.}
#' }
#'
#' @source Built by `data-raw/rwanda_inputs.R`. District boundaries: GADM 4.1
#'   admin-2 and annual mean temperature (WorldClim) via the \pkg{geodata}
#'   package. Species bionomics: the malariasimulation defaults
#'   (\url{https://github.com/mrc-ide/malariasimulation}). Species abundance,
#'   pyrethroid susceptibility, and net-use rasters are locally cached inputs
#'   (not distributed with the package).
"rwanda_inputs"
