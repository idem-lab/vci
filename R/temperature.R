# Briere thermal-response function, f(T) = c T (T - t_min) sqrt(t_max - T) for
# t_min < T < t_max, and 0 otherwise. A standard single-peaked form for insect
# and parasite temperature responses (Briere et al. 1999).
briere <- function(temperature, scale, t_min, t_max) {
  in_range <- temperature > t_min & temperature < t_max
  ifelse(
    in_range,
    scale *
      temperature *
      (temperature - t_min) *
      sqrt(pmax(t_max - temperature, 0)),
    0
  )
}

#' Temperature-dependent biting rate
#'
#' A simple mechanistic temperature response for the mosquito biting
#' (attempted-feeding) rate, as a Briere curve: it rises from a lower thermal
#' limit to an optimum and falls again to an upper limit, and is zero outside
#' those limits. Used to map the attempted-feeding rate `a*` across space from a
#' temperature layer, so that cool, high-altitude areas have lower biting rates
#' (longer gonotrophic cycles).
#'
#' The coefficients are the *An. gambiae* fit from Mordecai et al. (2013), as
#' used by Villena et al. (2022). For this smoke test a single relationship is
#' applied to all species; it is illustrative, not a validated parameterisation.
#'
#' @param temperature Air temperature in degrees Celsius. Vectorised.
#'
#' @return The biting rate per mosquito per day, the shape of `temperature`.
#'   Zero below 13.35 C and above 40.08 C.
#'
#' @references Mordecai et al. (2013) *Ecology Letters* 16:22-30; Villena et al.
#'   (2022) *Ecology* 103:e3685 \doi{10.1002/ecy.3685}.
#'
#' @examples
#' biting_rate(c(18, 22, 26, 30))
#' @export
biting_rate <- function(temperature) {
  briere(temperature, 2.02e-4, 13.35, 40.08)
}

#' Temperature-dependent extrinsic incubation period
#'
#' A simple mechanistic temperature response for the extrinsic incubation period
#' (EIP), the time for the parasite to develop within the mosquito. It is the
#' reciprocal of the parasite development rate, which follows a Briere curve, so
#' the EIP is shortest near the thermal optimum and lengthens as it cools. Used
#' to map the EIP across space from a temperature layer.
#'
#' Outside the parasite-development range the development rate is zero and the
#' EIP is therefore infinite (no transmission); [vectorial_capacity()] takes such
#' locations to zero capacity.
#'
#' The coefficients are the *An. gambiae* parasite-development fit from Mordecai
#' et al. (2013), as used by Villena et al. (2022). For this smoke test a single
#' relationship is applied to all species; it is illustrative, not a validated
#' parameterisation.
#'
#' @param temperature Air temperature in degrees Celsius. Vectorised.
#'
#' @return The extrinsic incubation period in days, the shape of `temperature`;
#'   `Inf` below 14.7 C and above 34 C.
#'
#' @references Mordecai et al. (2013) *Ecology Letters* 16:22-30; Villena et al.
#'   (2022) *Ecology* 103:e3685 \doi{10.1002/ecy.3685}.
#'
#' @examples
#' eip(c(18, 22, 26, 30))
#' @export
eip <- function(temperature) {
  development_rate <- briere(temperature, 1.11e-4, 14.7, 34.0)
  1 / development_rate
}
