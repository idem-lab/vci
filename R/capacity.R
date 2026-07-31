#' Species-specific vectorial capacity (Garrett-Jones form)
#'
#' Computes the stationary Garrett-Jones vectorial capacity for a single
#' mosquito species, at each location and time. This is the core quantity of
#' the framework: the vector-side transmission potential attributable to one
#' species, before any summation across species ([sum_species()] sums them).
#'
#' The equation is
#' \deqn{V = c\, m\, a^{2}\, \frac{p^{\nu}}{-\log p},}
#' with symbols as in the arguments below. All arguments are vectorised and
#' recycled, so the function works elementwise over arrays of any shape (over
#' location, time, and draw); it is called once per species.
#'
#' `survival` is the daily adult survival probability \eqn{p}. Where survival is
#' assembled from a mortality hazard \eqn{\mu} (for example under interventions,
#' see the maths spec), pass \eqn{p = \exp(-\mu)}; the two forms are identical.
#'
#' @param infection_probability Probability \eqn{c} that a mosquito becomes
#'   infected after biting an infectious human. In \eqn{[0, 1]}.
#' @param abundance Adult mosquitoes of the species per human, \eqn{m}.
#'   Non-negative.
#' @param feeding_rate Realised, successful human blood-feeding rate per
#'   mosquito per day, \eqn{a}. Non-negative.
#' @param survival Daily adult survival probability, \eqn{p}. Strictly between
#'   0 and 1.
#' @param eip Extrinsic incubation period in days, \eqn{\nu}. Positive.
#'
#' @return A numeric vector (or array, following the recycled inputs) of
#'   species-specific vectorial capacity, in the same units as `abundance`
#'   (per human).
#'
#' @references `MATHEMATICAL_SPEC_WORKING.md` section 1 (and section 17.2 for the
#'   equivalent mortality-hazard form). The maths spec is authoritative.
#'
#' @examples
#' vectorial_capacity(
#'   infection_probability = 0.5,
#'   abundance = 12,
#'   feeding_rate = 0.3,
#'   survival = 0.9,
#'   eip = 11
#' )
#' @export
vectorial_capacity <- function(
  infection_probability,
  abundance,
  feeding_rate,
  survival,
  eip
) {
  check_probability(infection_probability, "infection_probability")
  check_non_negative(abundance, "abundance")
  check_non_negative(feeding_rate, "feeding_rate")
  check_open_unit(survival, "survival")
  check_positive(eip, "eip")

  infection_probability *
    abundance *
    feeding_rate^2 *
    survival^eip /
    (-log(survival))
}
