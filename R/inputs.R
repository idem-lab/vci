#' Construct a validated `vci` input object
#'
#' Assembles the district-level inputs for a vector control impact calculation
#' into a single validated object. This is the minimal input contract for the
#' Milestone 0 smoke test: a boundary representation (tidy tables, keyed by
#' location and species) rather than the full typed-array core of `DESIGN.md`
#' section 7.
#'
#' The inputs are held in three tables plus optional geometry, keyed so that no
#' value is duplicated across keys it does not depend on:
#'
#' - **`vectors`** — one row per district and species: the district- and
#'   species-varying `abundance` (adults per human, \eqn{m}).
#' - **`bionomics`** — one row per species: the species-level biology assumed
#'   constant across districts (host-opportunity weights, attempted-feeding rate,
#'   baseline mortality hazard, human-to-mosquito infection probability, and
#'   EIP).
#' - **`sites`** — one row per district: the district-level intervention context
#'   (insecticide `susceptibility` and net-use `net_use`).
#'
#' Validation is strict and non-imputing: required columns must be present,
#' values must be in range, there must be no missing values in the data columns
#' (`DESIGN.md` section 7.4), and every species and district referenced in
#' `vectors` must be described in `bionomics` and `sites` respectively.
#'
#' @param vectors A data frame with columns `location_id`, `species`, and
#'   `abundance` (non-negative).
#' @param bionomics A data frame with one row per species and columns `species`,
#'   `host_indoor`, `host_outdoor`, `host_animal` (non-negative host-opportunity
#'   weights), `net_contact` (in-bed contact fraction, in \eqn{[0, 1]}),
#'   `attempted_rate` (non-negative), `baseline_hazard` (non-negative),
#'   `infection_probability` (in \eqn{[0, 1]}), and `eip` (positive).
#' @param sites A data frame with columns `location_id`, `susceptibility` (in
#'   \eqn{[0, 1]}), and `net_use` (in \eqn{[0, 1]}).
#' @param geometry Optional; district geometry (for example an `sf` object)
#'   keyed by `location_id`, carried for mapping. Not used by the calculation.
#'
#' @return An object of class `vci_inputs`: a list with elements `vectors`,
#'   `bionomics`, `sites`, and `geometry`.
#'
#' @references `DESIGN.md` section 7 (data contracts).
#'
#' @examples
#' vectors <- data.frame(
#'   location_id = c("d1", "d1"),
#'   species = c("gambiae", "funestus"),
#'   abundance = c(8, 2)
#' )
#' bionomics <- data.frame(
#'   species = c("gambiae", "funestus"),
#'   host_indoor = 0.8, host_outdoor = 0.1, host_animal = 0.1,
#'   net_contact = c(0.85, 0.78), attempted_rate = 0.333,
#'   baseline_hazard = c(0.132, 0.112), infection_probability = 0.5, eip = 10
#' )
#' sites <- data.frame(location_id = "d1", susceptibility = 0.3, net_use = 0.7)
#' vci_inputs(vectors, bionomics, sites)
#' @export
vci_inputs <- function(vectors, bionomics, sites, geometry = NULL) {
  check_columns(vectors, c("location_id", "species", "abundance"), "vectors")
  check_columns(
    bionomics,
    c(
      "species",
      "host_indoor",
      "host_outdoor",
      "host_animal",
      "net_contact",
      "attempted_rate",
      "baseline_hazard",
      "infection_probability",
      "eip"
    ),
    "bionomics"
  )
  check_columns(sites, c("location_id", "susceptibility", "net_use"), "sites")

  check_no_na(vectors$abundance, "abundance")
  check_no_na(sites$susceptibility, "susceptibility")
  check_no_na(sites$net_use, "net_use")

  check_non_negative(vectors$abundance, "abundance")
  check_probability(sites$susceptibility, "susceptibility")
  check_probability(sites$net_use, "net_use")
  check_non_negative(bionomics$host_indoor, "host_indoor")
  check_non_negative(bionomics$host_outdoor, "host_outdoor")
  check_non_negative(bionomics$host_animal, "host_animal")
  check_probability(bionomics$net_contact, "net_contact")
  check_non_negative(bionomics$attempted_rate, "attempted_rate")
  check_non_negative(bionomics$baseline_hazard, "baseline_hazard")
  check_probability(bionomics$infection_probability, "infection_probability")
  check_positive(bionomics$eip, "eip")

  unknown_species <- setdiff(unique(vectors$species), bionomics$species)
  if (length(unknown_species) > 0) {
    stop(
      sprintf(
        "`vectors` references species with no `bionomics` row: %s.",
        paste(unknown_species, collapse = ", ")
      ),
      call. = FALSE
    )
  }
  unknown_sites <- setdiff(unique(vectors$location_id), sites$location_id)
  if (length(unknown_sites) > 0) {
    stop(
      sprintf(
        "`vectors` references districts with no `sites` row: %s.",
        paste(unknown_sites, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  structure(
    list(
      vectors = vectors,
      bionomics = bionomics,
      sites = sites,
      geometry = geometry
    ),
    class = "vci_inputs"
  )
}

#' @export
print.vci_inputs <- function(x, ...) {
  cat("<vci_inputs>\n")
  cat(sprintf("  districts:   %d\n", length(unique(x$sites$location_id))))
  cat(sprintf(
    "  species:     %s\n",
    paste(x$bionomics$species, collapse = ", ")
  ))
  cat(sprintf("  vector rows: %d (district x species)\n", nrow(x$vectors)))
  cat(sprintf(
    "  geometry:    %s\n",
    if (is.null(x$geometry)) "none" else "attached"
  ))
  invisible(x)
}
