# Internal input validators. Kept deliberately small: a few lines of base R,
# no dependency. Each stops with a message naming the offending argument so
# failures point at the caller's input rather than the internals.

check_non_negative <- function(x, arg) {
  if (any(x < 0, na.rm = TRUE)) {
    stop(sprintf("`%s` must be non-negative.", arg), call. = FALSE)
  }
  invisible(x)
}

check_probability <- function(x, arg) {
  if (any(x < 0 | x > 1, na.rm = TRUE)) {
    stop(sprintf("`%s` must be in [0, 1].", arg), call. = FALSE)
  }
  invisible(x)
}

check_positive <- function(x, arg) {
  if (any(x <= 0, na.rm = TRUE)) {
    stop(sprintf("`%s` must be positive.", arg), call. = FALSE)
  }
  invisible(x)
}

check_open_unit <- function(x, arg) {
  if (any(x <= 0 | x >= 1, na.rm = TRUE)) {
    stop(sprintf("`%s` must be in (0, 1).", arg), call. = FALSE)
  }
  invisible(x)
}

check_columns <- function(df, required, arg) {
  missing <- setdiff(required, names(df))
  if (length(missing) > 0) {
    stop(
      sprintf(
        "`%s` is missing required column(s): %s.",
        arg,
        paste(missing, collapse = ", ")
      ),
      call. = FALSE
    )
  }
  invisible(df)
}

check_no_na <- function(x, arg) {
  if (anyNA(x)) {
    stop(
      sprintf(
        "`%s` contains missing values; no silent imputation (see DESIGN.md section 7.4).",
        arg
      ),
      call. = FALSE
    )
  }
  invisible(x)
}
