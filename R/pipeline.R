#' Compute total vectorial capacity per district and scenario
#'
#' Runs the full Milestone 0 pipeline over a [vci_inputs] object: for each
#' scenario it applies the intervention stub, assembles the successful-feeding
#' rate and mortality hazard, evaluates the species-specific capacity equation,
#' and sums across species to a district total. The intervention-independent
#' inputs (abundance, host weights, baseline hazard, EIP) are shared across
#' scenarios; only the net product and its coverage differ.
#'
#' A scenario is one net product applied at the district's net use: `"none"`
#' deploys nothing (coverage 0), while a net product (`"pyrethroid"` or
#' `"dual_ai"`) is applied at the site `net_use`, scaled by each species'
#' in-bed contact fraction (`net_contact`). The mapping from product to effects
#' is a stub ([intervention_effect_stub()]); results are illustrative only.
#'
#' @param inputs A [vci_inputs] object.
#' @param scenarios A named character vector mapping scenario label (the name)
#'   to net product (the value), each of `"none"`, `"pyrethroid"`, or
#'   `"dual_ai"`. Defaults to the three Milestone 0 scenarios: `none`,
#'   business-as-usual `bau` (pyrethroid), and the `alt` alternative (dual-AI).
#'
#' @return A tidy data frame with one row per district and scenario:
#'   `location_id`, `scenario`, and total `capacity`.
#'
#' @seealso [vci_by_scenario()] to turn these capacities into VCI.
#'
#' @examples
#' capacity <- compute_capacity(rwanda_inputs)
#' head(capacity)
#' @export
compute_capacity <- function(
  inputs,
  scenarios = c(
    none = "none",
    bau = "pyrethroid",
    alt = "dual_ai"
  )
) {
  if (!inherits(inputs, "vci_inputs")) {
    stop(
      "`inputs` must be a `vci_inputs` object (see `vci_inputs()`).",
      call. = FALSE
    )
  }

  tab <- merge(inputs$vectors, inputs$bionomics, by = "species")
  tab <- merge(tab, inputs$sites, by = "location_id")

  one_scenario <- function(label) {
    product <- scenarios[[label]]
    coverage <- if (product == "none") 0 else tab$net_use * tab$net_contact
    effect <- intervention_effect_stub(product, coverage, tab$susceptibility)
    destination <- host_destination(
      tab$host_indoor,
      tab$host_outdoor,
      tab$host_animal,
      effect$residual_accessibility
    )
    feeding <- successful_feeding_rate(
      tab$attempted_rate,
      destination$indoor,
      destination$outdoor,
      effect$indoor_survival,
      effect$outdoor_survival,
      effect$indoor_feeding
    )
    hazard <- mortality_hazard(
      tab$baseline_hazard,
      tab$attempted_rate,
      destination$indoor,
      destination$outdoor,
      destination$animal,
      effect$indoor_survival,
      effect$outdoor_survival,
      effect$animal_survival
    )
    capacity_species <- vectorial_capacity(
      tab$infection_probability,
      tab$abundance,
      feeding,
      survival_probability(hazard),
      tab$eip
    )
    total <- tapply(capacity_species, tab$location_id, sum)
    data.frame(
      location_id = names(total),
      scenario = label,
      capacity = as.numeric(total),
      row.names = NULL
    )
  }

  do.call(rbind, lapply(names(scenarios), one_scenario))
}

#' Vector control impact of each scenario against a reference
#'
#' Turns the district-by-scenario capacities from [compute_capacity()] into
#' vector control impact, comparing every scenario against a named reference
#' within each district: \eqn{VCI = 1 - V_\mathrm{alt}/V_\mathrm{ref}} (see
#' [compute_vci()]). The reference scenario itself yields a VCI of zero.
#'
#' @param capacity A data frame from [compute_capacity()], with columns
#'   `location_id`, `scenario`, and `capacity`.
#' @param reference The scenario label to treat as the reference; must appear in
#'   `capacity$scenario`.
#'
#' @return A tidy data frame with one row per district and scenario:
#'   `location_id`, `scenario`, and `vci` (a proportion; multiply by 100 for a
#'   percentage).
#'
#' @examples
#' capacity <- compute_capacity(rwanda_inputs)
#' vci_by_scenario(capacity, reference = "none")
#' @export
vci_by_scenario <- function(capacity, reference) {
  if (!reference %in% capacity$scenario) {
    stop(
      sprintf(
        "`reference` scenario \"%s\" is not present in `capacity`.",
        reference
      ),
      call. = FALSE
    )
  }
  ref <- capacity[capacity$scenario == reference, c("location_id", "capacity")]
  names(ref)[names(ref) == "capacity"] <- "reference_capacity"
  merged <- merge(capacity, ref, by = "location_id")
  merged$vci <- compute_vci(merged$reference_capacity, merged$capacity)
  out <- merged[, c("location_id", "scenario", "vci")]
  out[order(out$scenario, out$location_id), ]
}
