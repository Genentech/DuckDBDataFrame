#' Arrow type helpers for the DuckDB package suite
#'
#' Utilities for narrowing integer types and converting between
#' \code{\link[arrow]{DataType}} objects and Arrow type names. Used by
#' \pkg{BiocDuckDB} and \pkg{DuckDBArray} for Parquet schema selection
#' and parallel-safe type passing.
#'
#' @param range Length-two numeric vector \code{c(min, max)} for
#'   \code{\link{arrowIntType}}.
#' @param x An R vector for \code{\link{arrowType}}.
#' @param type An \code{\link[arrow]{DataType}} or Arrow type name (character)
#'   for \code{\link{arrowTypeToName}}.
#' @param name Length-one character Arrow type name (e.g. \code{"uint16"})
#'   for \code{\link{arrowTypeFromName}}.
#'
#' @return
#' \describe{
#'   \item{\code{arrowIntType}, \code{arrowType}}{
#'     An \code{\link[arrow]{DataType}}.}
#'   \item{\code{arrowTypeToName}}{
#'     A length-one character Arrow type name.}
#'   \item{\code{arrowTypeFromName}}{
#'     An \code{\link[arrow]{DataType}}.}
#' }
#'
#' @details
#' \code{arrowIntType} selects the narrowest unsigned or signed Arrow integer
#' type that can represent \code{range}. \code{arrowType} infers an Arrow type
#' from an R vector, narrowing integers when possible.
#'
#' \code{arrowTypeFromName} and \code{arrowTypeToName} implement a small
#' registry of scalar Arrow types used when passing type information to
#' BiocParallel workers (where \code{DataType} external pointers do not
#' serialize reliably).
#'
#' @author Patrick Aboyoun
#'
#' @seealso
#' \code{\link{parquet-io}},
#' \code{\link[BiocDuckDB]{writeParquet}},
#' \code{\link[DuckDBArray]{writeCoordArray}}
#'
#' @aliases arrowIntType
#' @aliases arrowType
#' @aliases arrowTypeToName
#' @aliases arrowTypeFromName
#'
#' @examples
#' arrowIntType(c(0L, 10L))
#' arrowType(1:10L)
#' arrowTypeToName(arrow::uint16())
#' arrowTypeFromName("uint16")
#'
#' @name arrow-types
NULL

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Arrow type helpers
###

#' @export
#' @importFrom arrow uint8 uint16 uint32 uint64 int8 int16 int32 int64
#' @rdname arrow-types
arrowIntType <- function(range) {
    min_x <- range[1L]
    max_x <- range[2L]
    if (min_x >= 0L) {
        if (max_x <= 255L) {
            uint8()
        } else if (max_x <= 65535L) {
            uint16()
        } else if (max_x <= 2147483647L) {
            int32()
        } else if (max_x <= 4294967295) {
            uint32()
        } else {
            int64()
        }
    } else {
        if (min_x >= -128L && max_x <= 127L) {
            int8()
        } else if (min_x >= -32768L && max_x <= 32767L) {
            int16()
        } else if (min_x >= -2147483648 && max_x <= 2147483647L) {
            int32()
        } else {
            int64()
        }
    }
}

#' @export
#' @importFrom arrow infer_type
#' @rdname arrow-types
arrowType <- function(x) {
    if (is.integer(x)) {
        x <- x[!is.na(x)]
    }

    if (is.integer(x) && length(x) > 0L) {
        arrowIntType(range(x))
    } else {
        infer_type(x)
    }
}

#' @export
#' @rdname arrow-types
arrowTypeToName <- function(type) {
    if (is.character(type)) {
        if (length(type) != 1L) {
            stop("'type' must be a single Arrow type name")
        }
        return(type)
    }
    if (!inherits(type, "DataType")) {
        stop("'type' must be NULL, a character Arrow type name, ",
             "or an arrow DataType object")
    }
    type$ToString()
}

#' @export
#' @importFrom arrow bool int8 int16 int32 int64 uint8 uint16 uint32 uint64
#' @importFrom arrow float32 float64
#' @rdname arrow-types
arrowTypeFromName <- function(name) {
    if (!is.character(name) || length(name) != 1L) {
        stop("'name' must be a single Arrow type name")
    }
    switch(name,
           "bool" = bool(),
           "int8" = int8(),
           "int16" = int16(),
           "int32" = int32(),
           "int64" = int64(),
           "uint8" = uint8(),
           "uint16" = uint16(),
           "uint32" = uint32(),
           "uint64" = uint64(),
           "float" = float32(),
           "double" = float64(),
           stop("unsupported Arrow type name: ", name, call. = FALSE))
}
