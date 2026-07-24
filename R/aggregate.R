#' Sum species-specific capacity across species
#'
#' Aggregates species-specific vectorial capacity (from [vectorial_capacity()])
#' to a total by summing over the `species` dimension:
#' \deqn{V_{i,t} = \sum_s V_{s,i,t}.}
#'
#' There is a single aggregation path — species-specific capacities are computed
#' and then summed — so species composition can never be applied twice by
#' construction. This function is a plain sum: it applies no fractions or
#' weights. Allocating abundance to species (for example from a total abundance
#' and species fractions) is input preparation done *before* capacity is
#' computed, not a step here.
#'
#' @param x A numeric array whose dimensions are named (see
#'   `names(dimnames(x))`), one of which is the species dimension. Typically the
#'   output of [vectorial_capacity()] arranged over species and any of location,
#'   time, and draw.
#' @param dim Name of the species dimension to sum over. Defaults to
#'   `"species"`.
#'
#' @return The array `x` with the species dimension removed: total capacity over
#'   the remaining dimensions. If species was the only dimension, a scalar.
#'
#' @references `MATHEMATICAL_SPEC_WORKING.md` section 18; `DESIGN.md` section 5.2.
#'
#' @examples
#' capacity <- array(
#'   c(0.4, 0.6, 0.1, 0.9),
#'   dim = c(2, 2),
#'   dimnames = list(
#'     species = c("gambiae", "funestus"),
#'     location = c("district_1", "district_2")
#'   )
#' )
#' sum_species(capacity)
#' @export
sum_species <- function(x, dim = "species") {
  dim_names <- names(dimnames(x))
  if (is.null(dim_names) || !dim %in% dim_names) {
    stop(
      sprintf("`x` must be an array with a named `%s` dimension.", dim),
      call. = FALSE
    )
  }
  keep <- setdiff(seq_along(dim(x)), match(dim, dim_names))
  if (length(keep) == 0) {
    return(sum(x))
  }
  apply(x, keep, sum)
}
