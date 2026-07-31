#' Repellency-redistributed host destination probabilities
#'
#' Given the pre-intervention host-opportunity weights for the three feeding
#' pathways — indoor human, outdoor human, and non-human animal — and the
#' residual indoor accessibility after repellency, returns the probability that
#' a feeding attempt is directed through each pathway.
#'
#' The v1 host-choice model treats repellency as *redistributing* attempts
#' rather than preventing them: the indoor-human weight is scaled by the residual
#' accessibility \eqn{R}, and the three pathways are renormalised so the
#' probabilities sum to one (maths spec section 15). With `residual_accessibility
#' = 1` (no repellency) the result is the pre-intervention split.
#'
#' The weights are relative host opportunity, not probabilities: only their
#' ratios matter. They may be any non-negative numbers on a common scale.
#'
#' @param indoor,outdoor,animal Non-negative host-opportunity weights for the
#'   indoor-human (\eqn{G^{in}}), outdoor-human (\eqn{G^{out}}), and animal
#'   (\eqn{G^{animal}}) pathways. Vectorised and recycled.
#' @param residual_accessibility Residual accessibility of indoor humans after
#'   repellency, \eqn{R}, in \eqn{[0, 1]}. Defaults to 1 (no repellency).
#'
#' @return A named list with elements `indoor`, `outdoor`, and `animal`: the
#'   post-repellency destination probabilities \eqn{P^{e,R}}, each the shape of
#'   the recycled inputs and summing to one across the three pathways.
#'
#' @references `MATHEMATICAL_SPEC_WORKING.md` section 15.
#'
#' @examples
#' host_destination(indoor = 3, outdoor = 1, animal = 1, residual_accessibility = 0.5)
#' @export
host_destination <- function(
  indoor,
  outdoor,
  animal,
  residual_accessibility = 1
) {
  check_non_negative(indoor, "indoor")
  check_non_negative(outdoor, "outdoor")
  check_non_negative(animal, "animal")
  check_probability(residual_accessibility, "residual_accessibility")

  indoor_weighted <- residual_accessibility * indoor
  denominator <- indoor_weighted + outdoor + animal
  if (any(denominator <= 0, na.rm = TRUE)) {
    stop(
      "Host-opportunity weights sum to zero for at least one element.",
      call. = FALSE
    )
  }
  list(
    indoor = indoor_weighted / denominator,
    outdoor = outdoor / denominator,
    animal = animal / denominator
  )
}

#' Successful human blood-feeding rate
#'
#' Assembles the realised, successful human blood-feeding rate \eqn{a} from the
#' attempted-feeding rate and the destination, killing, and barrier effects, in
#' the biological order attempt -> repellency/redistribution -> pre-feed killing
#' -> barrier -> successful feed (maths spec section 16):
#' \deqn{a = a^{*}\left[P^{in,R} K^{in} B^{in} + P^{out,R} K^{out} F^{out}\right].}
#'
#' Only indoor- and outdoor-human attempts can produce a human blood meal;
#' animal-directed attempts never contribute (though they may still kill, see
#' [mortality_hazard()]). Destination probabilities come from
#' [host_destination()]; killing and barrier terms come from an intervention
#' mapping such as [intervention_effect_stub()].
#'
#' @param attempted_rate Attempted-feeding rate per mosquito per day,
#'   \eqn{a^{*}}. Non-negative.
#' @param indoor_destination,outdoor_destination Post-repellency probabilities
#'   that an attempt is indoor-human (\eqn{P^{in,R}}) or outdoor-human
#'   (\eqn{P^{out,R}}).
#' @param indoor_survival,outdoor_survival Residual survival of an attempt
#'   through the indoor (\eqn{K^{in}}) and outdoor (\eqn{K^{out}}) pathways, in
#'   \eqn{[0, 1]}. Default 1 (no killing).
#' @param indoor_feeding Residual successful feeding given a survived indoor
#'   attempt and the barrier, \eqn{B^{in}}, in \eqn{[0, 1]}. Default 1.
#' @param outdoor_efficiency Outdoor feeding efficiency \eqn{F^{out}} in
#'   \eqn{[0, 1]}. Default 1.
#'
#' @return The successful human blood-feeding rate \eqn{a}, the shape of the
#'   recycled inputs.
#'
#' @references `MATHEMATICAL_SPEC_WORKING.md` section 16.
#'
#' @examples
#' d <- host_destination(3, 1, 1, residual_accessibility = 0.6)
#' successful_feeding_rate(
#'   attempted_rate = 0.3,
#'   indoor_destination = d$indoor,
#'   outdoor_destination = d$outdoor,
#'   indoor_survival = 0.7,
#'   indoor_feeding = 0.6
#' )
#' @export
successful_feeding_rate <- function(
  attempted_rate,
  indoor_destination,
  outdoor_destination,
  indoor_survival = 1,
  outdoor_survival = 1,
  indoor_feeding = 1,
  outdoor_efficiency = 1
) {
  check_non_negative(attempted_rate, "attempted_rate")
  attempted_rate *
    (indoor_destination *
      indoor_survival *
      indoor_feeding +
      outdoor_destination * outdoor_survival * outdoor_efficiency)
}

#' Total adult mortality hazard under interventions
#'
#' Combines the baseline mortality hazard with intervention-mediated killing,
#' accumulated across all three feeding pathways as a stationary competing
#' hazard (maths spec section 17):
#' \deqn{\mu = \mu^{0} + a^{*}\sum_{e} P^{e,R}\left(1 - K^{e}\right).}
#'
#' Killing on every pathway contributes, including the animal pathway (a
#' mosquito can be killed at an animal-directed attempt even though that attempt
#' yields no human blood meal). The barrier term \eqn{B} does not enter here — it
#' prevents feeding, not survival. Convert the hazard to a survival probability
#' with [survival_probability()].
#'
#' @param baseline_hazard Baseline adult mortality hazard per day \eqn{\mu^{0}},
#'   before intervention killing. Non-negative.
#' @param attempted_rate Attempted-feeding rate per mosquito per day
#'   \eqn{a^{*}}. Non-negative.
#' @param indoor_destination,outdoor_destination,animal_destination
#'   Post-repellency destination probabilities \eqn{P^{e,R}} from
#'   [host_destination()].
#' @param indoor_survival,outdoor_survival,animal_survival Residual survival of
#'   an attempt through each pathway \eqn{K^{e}}, in \eqn{[0, 1]}. Default 1 (no
#'   killing).
#'
#' @return The total adult mortality hazard \eqn{\mu} per day, the shape of the
#'   recycled inputs.
#'
#' @references `MATHEMATICAL_SPEC_WORKING.md` section 17.
#'
#' @examples
#' d <- host_destination(3, 1, 1, residual_accessibility = 0.6)
#' mortality_hazard(
#'   baseline_hazard = 0.12,
#'   attempted_rate = 0.3,
#'   indoor_destination = d$indoor,
#'   outdoor_destination = d$outdoor,
#'   animal_destination = d$animal,
#'   indoor_survival = 0.7
#' )
#' @export
mortality_hazard <- function(
  baseline_hazard,
  attempted_rate,
  indoor_destination,
  outdoor_destination,
  animal_destination,
  indoor_survival = 1,
  outdoor_survival = 1,
  animal_survival = 1
) {
  check_non_negative(baseline_hazard, "baseline_hazard")
  check_non_negative(attempted_rate, "attempted_rate")
  baseline_hazard +
    attempted_rate *
      (indoor_destination *
        (1 - indoor_survival) +
        outdoor_destination * (1 - outdoor_survival) +
        animal_destination * (1 - animal_survival))
}

#' Survival probability from a mortality hazard
#'
#' Converts a mortality hazard to a survival probability over an interval,
#' \eqn{p(\Delta) = \exp(-\mu\Delta)} (maths spec section 17). With the default
#' unit interval this is daily adult survival, ready for [vectorial_capacity()].
#'
#' @param hazard Mortality hazard per day \eqn{\mu}. Non-negative.
#' @param interval Interval length in days \eqn{\Delta}. Positive; default 1.
#'
#' @return The survival probability over the interval, the shape of the recycled
#'   inputs.
#'
#' @references `MATHEMATICAL_SPEC_WORKING.md` section 17.
#'
#' @examples
#' survival_probability(0.12)
#' @export
survival_probability <- function(hazard, interval = 1) {
  check_non_negative(hazard, "hazard")
  check_positive(interval, "interval")
  exp(-hazard * interval)
}
