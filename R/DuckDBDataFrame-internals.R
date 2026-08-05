#' Internal generics and helpers for the BiocDuckDB suite
#'
#' These generics and helper functions are the low-level extension points shared
#' across the BiocDuckDB packages (for example \pkg{DuckDBArray} and
#' \pkg{DuckDBGRanges} define methods on the generics). They are exported so
#' companion packages can dispatch methods on them across package boundaries, but
#' they are not part of the public user-facing API and are not intended for
#' direct use by end users.
#'
#' @param x A \linkS4class{DuckDBTable}-derived object.
#' @param conn A \code{tbl_duckdb_connection}.
#'
#' @return
#' \code{keycols()} returns the named list of key-dimension index vectors.
#' \code{has_row_number()} returns a logical scalar indicating whether the object
#' is addressed by a generated row number (rather than named keys).
#' \code{set_row_number()} returns the \code{integer64} row-number encoding for a
#' connection. \code{makePrettyCharacterMatrixForDisplay()} returns a character
#' matrix used by the \code{show()} method.
#'
#' @name DuckDBDataFrame-internals
#' @keywords internal
NULL
