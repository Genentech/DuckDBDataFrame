### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Arrow type helpers
###

#' Narrowest Arrow integer type for a numeric range
#'
#' @description
#' Selects the narrowest unsigned or signed Arrow integer type that can
#' represent \code{range}.
#'
#' @param range Length-two numeric vector \code{c(min, max)}.
#'
#' @return An \code{\link[arrow]{DataType}}.
#'
#' @author Patrick Aboyoun
#'
#' @export
#' @importFrom arrow uint8 uint16 uint32 uint64 int8 int16 int32 int64
#' @rdname arrowIntType
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

#' Infer Arrow type from R values
#'
#' @description
#' Infers an Arrow type from an R vector, narrowing integers when possible.
#'
#' @param x An R vector.
#'
#' @return An \code{\link[arrow]{DataType}}.
#'
#' @author Patrick Aboyoun
#'
#' @export
#' @importFrom arrow infer_type
#' @rdname arrowType
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
