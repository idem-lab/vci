#' Vector control impact between two scenarios
#'
#' Vector control impact (VCI) is the proportional change in total vectorial
#' capacity from a reference scenario to an alternative:
#' \deqn{VCI = 1 - \frac{V_\mathrm{alt}}{V_\mathrm{ref}}.}
#'
#' The comparison is deliberately general: `reference` and `alternative` may be
#' any two scenarios computed by the same capacity calculation (typically the
#' species-summed output of [sum_species()]). The common case is a
#' no-intervention or status-quo reference against an intervention alternative,
#' but two intervention packages, or two non-intervention futures, are equally
#' valid. Which scenario is named the reference is the only thing that differs.
#'
#' A positive VCI is a reduction in capacity (the intervention helps); zero means
#' no change (identical scenarios give exactly zero); a negative VCI means the
#' alternative *increases* capacity. Multiply by 100 for a percentage.
#'
#' A reference capacity of zero makes VCI undefined (division by zero), so the
#' function warns rather than returning a silent `Inf`/`NaN`. Handling of the
#' zero-reference and capacity-increase cases is still an open decision
#' (see the package issues); this is the interim behaviour.
#'
#' @param reference Total vectorial capacity under the reference scenario.
#'   Non-negative; numeric scalar or array.
#' @param alternative Total vectorial capacity under the alternative scenario.
#'   Non-negative; recycled against `reference`.
#'
#' @return VCI as a proportion, the shape of the recycled inputs.
#'
#' @references `MATHEMATICAL_SPEC_WORKING.md` section 19; `DESIGN.md` section 5.3.
#'
#' @examples
#' compute_vci(reference = 1.8, alternative = 0.6)
#' @export
compute_vci <- function(reference, alternative) {
  check_non_negative(reference, "reference")
  check_non_negative(alternative, "alternative")
  if (any(reference == 0, na.rm = TRUE)) {
    warning(
      "`reference` capacity is zero in one or more elements; VCI is ",
      "undefined there.",
      call. = FALSE
    )
  }
  1 - alternative / reference
}
