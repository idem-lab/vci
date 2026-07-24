# Illustrative-only STUB parameters for the intervention mapping. These are
# plausible round numbers, NOT a validated parameterisation. Per-net-contact
# effect on a mosquito attempting to feed on an indoor human:
#   repel   - probability the attempt is deterred (feeds into residual accessibility R)
#   kill    - pyrethroid killing at full susceptibility (scales with susceptibility)
#   barrier - reduction in feeding success given the mosquito survives and reaches the human
#   ai_kill - additional, resistance-INDEPENDENT killing from a second active
#             ingredient (0 for pyrethroid-only; the chlorfenapyr-like floor for dual-AI)
# See intervention_effect_stub() for how these combine. Do not cite these numbers.
.stub_net_params <- list(
  pyrethroid = list(repel = 0.50, kill = 0.40, barrier = 0.30, ai_kill = 0.00),
  dual_ai = list(repel = 0.50, kill = 0.40, barrier = 0.30, ai_kill = 0.50)
)

#' Intervention effects (R, B, K) --- ILLUSTRATIVE STUB
#'
#' @description
#' Maps a deployed net product, its coverage, and local insecticide
#' susceptibility to the three intervention-effect channels the framework uses:
#' residual indoor accessibility after repellency \eqn{R}, residual indoor
#' feeding success \eqn{B^{in}}, and pathway-specific residual survival
#' \eqn{K^{e}} (maths spec section 14).
#'
#' @section Stub, not science:
#' **This is a deliberately crude placeholder, not the real intervention model
#' (issue #17).** Its numbers are illustrative round values chosen only so the
#' Milestone 0 smoke test exercises the whole pipeline end to end. They are not
#' fitted, not validated, and must never be read as a bionomic parameterisation.
#' Nets act on the indoor-human pathway only; outdoor and animal survival are
#' left at 1.
#'
#' The stub captures one qualitatively real contrast: pyrethroid killing scales
#' with susceptibility (it collapses as resistance rises), whereas a dual-AI net
#' adds resistance-independent killing, so it retains impact where pyrethroid
#' nets lose it.
#'
#' @param product One of `"none"`, `"pyrethroid"`, or `"dual_ai"`.
#' @param coverage Proportion using the net (effective indoor coverage), in
#'   \eqn{[0, 1]}. Vectorised.
#' @param susceptibility Proportion of mosquitoes killed in a pyrethroid
#'   susceptibility bioassay, in \eqn{[0, 1]} (1 = fully susceptible, 0 = fully
#'   resistant). Vectorised. Note this is *susceptibility*, i.e. `1 - resistance`.
#'
#' @return A named list of effect channels, each the shape of the recycled
#'   inputs: `residual_accessibility` (\eqn{R}), `indoor_feeding`
#'   (\eqn{B^{in}}), `indoor_survival` (\eqn{K^{in}}), `outdoor_survival`
#'   (\eqn{K^{out}}), and `animal_survival` (\eqn{K^{animal}}). These feed
#'   [host_destination()], [successful_feeding_rate()], and [mortality_hazard()].
#'
#' @references `MATHEMATICAL_SPEC_WORKING.md` section 14. Effect structure only;
#'   the numbers are a stub (see above).
#'
#' @examples
#' # A dual-AI net keeps killing where a pyrethroid net has failed to resistance:
#' intervention_effect_stub("pyrethroid", coverage = 0.6, susceptibility = 0.1)
#' intervention_effect_stub("dual_ai", coverage = 0.6, susceptibility = 0.1)
#' @export
intervention_effect_stub <- function(product, coverage, susceptibility) {
  product <- match.arg(product, c("none", "pyrethroid", "dual_ai"))
  check_probability(coverage, "coverage")
  check_probability(susceptibility, "susceptibility")

  n <- max(length(coverage), length(susceptibility))
  residual_accessibility <- rep(1, n)
  indoor_survival <- rep(1, n)
  indoor_feeding <- rep(1, n)

  if (product != "none") {
    pars <- .stub_net_params[[product]]
    # Competing-risk combination of pyrethroid (susceptibility-scaled) and a
    # resistance-independent second-AI killing per net contact.
    kill_per_contact <- 1 -
      (1 - pars$kill * susceptibility) * (1 - pars$ai_kill)
    residual_accessibility <- 1 - coverage * pars$repel
    indoor_survival <- 1 - coverage * kill_per_contact
    indoor_feeding <- 1 - coverage * pars$barrier
  }

  list(
    residual_accessibility = residual_accessibility,
    indoor_feeding = indoor_feeding,
    indoor_survival = indoor_survival,
    outdoor_survival = rep(1, n),
    animal_survival = rep(1, n)
  )
}
