#' Common operations on DuckDBColumn objects
#'
#' @description
#' Common operations on \linkS4class{DuckDBColumn} objects.
#'
#' @section SQL Methods:
#' In the code snippets below, \code{x} is a DuckDBColumn object:
#' \describe{
#'   \item{\code{sql_call(x, fun, ...)}:}{
#'     Applies the specified SQL function to all data columns of \code{x}.
#'   }
#'   \item{\code{sql_fun(x, function_type = NULL, return_type = NULL, description = FALSE)}:}{
#'     Finds DuckDB SQL functions compatible with the data type of \code{x}.
#'     Returns a data.frame of matching functions with optional filtering by
#'     function type and return type.
#'   }
#' }
#'
#' @section Group Generics:
#' DuckDBColumn objects have support for S4 group generic functionality:
#' \describe{
#'   \item{\code{Arith}}{\code{"+"}, \code{"-"}, \code{"*"}, \code{"^"},
#'     \code{"\%\%"}, \code{"\%/\%"}, \code{"/"}}
#'   \item{\code{Compare}}{\code{"=="}, \code{">"}, \code{"<"}, \code{"!="},
#'     \code{"<="}, \code{">="}}
#'   \item{\code{Logic}}{\code{"&"}, \code{"|"}, \code{"!"}}
#'   \item{\code{Ops}}{\code{"Arith"}, \code{"Compare"}, \code{"Logic"}}
#'   \item{\code{Math}}{\code{"abs"}, \code{"sign"}, \code{"sqrt"},
#'     \code{"ceiling"}, \code{"floor"}, \code{"trunc"}, \code{"log"},
#'     \code{"log10"}, \code{"log2"}, \code{"acos"}, \code{"acosh"},
#'     \code{"asin"}, \code{"asinh"}, \code{"atan"}, \code{"atanh"},
#'     \code{"exp"}, \code{"expm1"}, \code{"cos"}, \code{"cosh"},
#'     \code{"sin"}, \code{"sinh"}, \code{"tan"}, \code{"tanh"},
#'     \code{"gamma"}, \code{"lgamma"}}
#'   \item{\code{Summary}}{\code{"max"}, \code{"min"}, \code{"range"},
#'     \code{"prod"}, \code{"sum"}, \code{"any"}, \code{"all"}}
#'  }
#'  See \link[methods]{S4groupGeneric} for more details.
#'
#' @section Numerical Data Methods:
#' In the code snippets below, \code{x} is a DuckDBColumn object:
#' \describe{
#'   \item{\code{is.finite(x)}:}{
#'     Returns a DuckDBColumn containing logicals that indicate which values are
#'     finite.
#'   }
#'   \item{\code{is.infinite(x)}:}{
#'     Returns a DuckDBColumn containing logicals that indicate which values are
#'     infinite.
#'   }
#'   \item{\code{is.nan(x)}:}{
#'     Returns a DuckDBColumn containing logicals that indicate which values are
#'     Not a Number.
#'   }
#'   \item{\code{mean(x)}:}{
#'     Calculates the mean of \code{x}.
#'   }
#'   \item{\code{var(x)}:}{
#'     Calculates the variance of \code{x}.
#'   }
#'   \item{\code{sd(x)}:}{
#'     Calculates the standard deviation of \code{x}.
#'   }
#'   \item{\code{median(x)}:}{
#'     Calculates the median of \code{x}.
#'   }
#'   \item{\code{quantile(x, probs = seq(0, 1, 0.25), names = TRUE, type = 7)}:}{
#'     Calculates the specified quantiles of \code{x}.
#'     \describe{
#'       \item{\code{probs}}{A numeric vector of probabilities with values in
#'         [0,1].}
#'       \item{\code{names}}{If \code{TRUE}, the result has names describing the
#'         quantiles.}
#'       \item{\code{type}}{Either 1 or 7 that specifies the quantile algorithm
#'         detailed in \code{\link[stats]{quantile}}.}
#'     }
#'   }
#'   \item{\code{mad(x, constant = 1.4826)}:}{
#'     Calculates the median absolute deviation of \code{x}.
#'     \describe{
#'       \item{\code{constant}}{The scale factor.}
#'     }
#'   }
#'   \item{\code{IQR(x, type = 7)}:}{
#'     Calculates the interquartile range of \code{x}.
#'     \describe{
#'       \item{\code{type}}{Either 1 or 7 that specifies the quantile algorithm
#'         detailed in \code{\link[stats]{quantile}}.}
#'     }
#'   }
#'   \item{\code{pmax(..., na.rm = FALSE)}:}{
#'     Returns the parallel maxima of multiple DuckDBColumn objects.
#'     All arguments must be DuckDBColumn objects with compatible dimensions.
#'   }
#'   \item{\code{pmin(..., na.rm = FALSE)}:}{
#'     Returns the parallel minima of multiple DuckDBColumn objects.
#'     All arguments must be DuckDBColumn objects with compatible dimensions.
#'   }
#' }
#'
#' @section Character Methods:
#' In the code snippets below, \code{x} is a DuckDBColumn object:
#' \describe{
#'   \item{\code{nchar(x)}:}{
#'     Returns a DuckDBColumn containing the number of characters in each
#'     string.
#'   }
#'   \item{\code{tolower(x)}:}{
#'     Returns a DuckDBColumn with all strings converted to lowercase.
#'   }
#'   \item{\code{toupper(x)}:}{
#'     Returns a DuckDBColumn with all strings converted to uppercase.
#'   }
#'   \item{\code{chartr(old, new, x)}:}{
#'     Returns a DuckDBColumn with characters translated.
#'     \describe{
#'       \item{\code{old}}{Characters to be translated.}
#'       \item{\code{new}}{Characters to translate to.}
#'     }
#'   }
#'   \item{\code{substr(x, start, stop)}:}{
#'     Returns a DuckDBColumn containing substrings extracted by position.
#'     \describe{
#'       \item{\code{start}}{Integer starting position (1-indexed).}
#'       \item{\code{stop}}{Integer ending position (inclusive).}
#'     }
#'   }
#'   \item{\code{substring(x, first, last = 1000000L)}:}{
#'     Returns a DuckDBColumn containing substrings extracted by position.
#'     \describe{
#'       \item{\code{first}}{Integer starting position (1-indexed).}
#'       \item{\code{last}}{Integer ending position (inclusive).}
#'     }
#'   }
#'   \item{\code{grepl(pattern, x, ignore.case = FALSE, fixed = FALSE)}:}{
#'     Returns a DuckDBColumn containing logicals indicating pattern matches.
#'     \describe{
#'       \item{\code{pattern}}{Character string containing a regular expression.}
#'       \item{\code{ignore.case}}{If \code{TRUE}, case-insensitive matching.}
#'       \item{\code{fixed}}{If \code{TRUE}, pattern is a fixed string not regex.}
#'     }
#'   }
#'   \item{\code{sub(pattern, replacement, x, ignore.case = FALSE, fixed = FALSE)}:}{
#'     Returns a DuckDBColumn with first match of pattern replaced.
#'     \describe{
#'       \item{\code{pattern}}{Character string containing a regular expression.}
#'       \item{\code{replacement}}{Replacement string.}
#'       \item{\code{ignore.case}}{If \code{TRUE}, case-insensitive matching.}
#'       \item{\code{fixed}}{If \code{TRUE}, pattern is a fixed string not regex.}
#'     }
#'   }
#'   \item{\code{gsub(pattern, replacement, x, ignore.case = FALSE, fixed = FALSE)}:}{
#'     Returns a DuckDBColumn with all matches of pattern replaced.
#'     \describe{
#'       \item{\code{pattern}}{Character string containing a regular expression.}
#'       \item{\code{replacement}}{Replacement string.}
#'       \item{\code{ignore.case}}{If \code{TRUE}, case-insensitive matching.}
#'       \item{\code{fixed}}{If \code{TRUE}, pattern is a fixed string not regex.}
#'     }
#'   }
#'   \item{\code{startsWith(x, prefix)}:}{
#'     Returns a DuckDBColumn containing logicals indicating if strings start
#'     with the specified prefix.
#'   }
#'   \item{\code{endsWith(x, suffix)}:}{
#'     Returns a DuckDBColumn containing logicals indicating if strings end
#'     with the specified suffix.
#'   }
#'   \item{\code{paste(..., sep = " ", collapse = NULL)}:}{
#'     Concatenates multiple DuckDBColumn objects using the specified separator.
#'     The \code{collapse} argument is not supported.
#'     All arguments must be DuckDBColumn objects with compatible dimensions.
#'   }
#' }
#'
#' @section General Methods:
#' In the code snippets below, \code{x} is a DuckDBColumn object:
#' \describe{
#'   \item{\code{unique(x)}:}{
#'     Returns a DuckDBColumn containing the distinct rows.
#'   }
#'   \item{\code{x \%in\% table}:}{
#'     Returns a DuckDBColumn containing logicals that indicate the elements of
#'     \code{x} in \code{table}.
#'   }
#'   \item{\code{table(...)}:}{
#'     Returns a table containing the counts across the distinct values.
#'   }
#' }
#'
#' @section Sparsity Methods:
#' In the code snippets below, \code{x} is a DuckDBColumn object:
#' \describe{
#'   \item{\code{is_nonzero(x)}:}{
#'     Returns a DuckDBColumn containing logicals that indicate if the elements
#'     of \code{x} are non-zero.
#'   }
#'   \item{\code{nzcount(x)}:}{
#'     Returns the total number of non-zero values.
#'   }
#' }
#'
#' @return
#' Method return types are documented in the sections above.
#'
#' @author Patrick Aboyoun
#'
#' @aliases sql_call,DuckDBColumn-method
#' @aliases sql_fun,DuckDBColumn-method
#'
#' @aliases Ops,DuckDBColumn,DuckDBColumn-method
#' @aliases Ops,DuckDBColumn,atomic-method
#' @aliases Ops,atomic,DuckDBColumn-method
#' @aliases Ops,DuckDBColumn,missing-method
#' @aliases !,DuckDBColumn-method
#' @aliases Math,DuckDBColumn-method
#' @aliases Summary,DuckDBColumn-method
#'
#' @aliases is.finite,DuckDBColumn-method
#' @aliases is.infinite,DuckDBColumn-method
#' @aliases is.nan,DuckDBColumn-method
#' @aliases mean,DuckDBColumn-method
#' @aliases var,DuckDBColumn,ANY-method
#' @aliases sd,DuckDBColumn-method
#' @aliases median.DuckDBColumn
#' @aliases quantile.DuckDBColumn
#' @aliases mad,DuckDBColumn-method
#' @aliases IQR,DuckDBColumn-method
#' @aliases pmax,DuckDBColumn-method
#' @aliases pmin,DuckDBColumn-method
#'
#' @aliases nchar,DuckDBColumn-method
#' @aliases tolower,DuckDBColumn-method
#' @aliases toupper,DuckDBColumn-method
#' @aliases chartr,ANY,ANY,DuckDBColumn-method
#' @aliases substr,DuckDBColumn-method
#' @aliases substring,DuckDBColumn-method
#' @aliases grepl,ANY,DuckDBColumn-method
#' @aliases sub,ANY,ANY,DuckDBColumn-method
#' @aliases gsub,ANY,ANY,DuckDBColumn-method
#' @aliases startsWith,DuckDBColumn-method
#' @aliases endsWith,DuckDBColumn-method
#' @aliases paste2,DuckDBColumn,DuckDBColumn-method
#' @aliases paste2,DuckDBColumn,character-method
#' @aliases paste2,character,DuckDBColumn-method
#' @aliases paste,DuckDBColumn-method
#'
#' @aliases unique,DuckDBColumn-method
#' @aliases %in%,DuckDBColumn,ANY-method
#' @aliases table,DuckDBColumn-method
#'
#' @aliases is_nonzero,DuckDBColumn-method
#' @aliases nzcount,DuckDBColumn-method
#'
#' @seealso
#' \itemize{
#'   \item \code{\link{DuckDBColumn-class}} for the main class
#'   \item \code{\link[S4Vectors]{Vector}} for the base class
#' }
#'
#' @examples
#' tf <- tempfile(fileext = ".parquet")
#' on.exit(unlink(tf))
#' arrow::write_parquet(cbind(model = rownames(mtcars), mtcars), tf)
#' df <- DuckDBDataFrame(tf, datacols = colnames(mtcars), keycol = "model")
#' mpg <- df[["mpg"]]
#' mean(mpg)
#' sd(mpg)
#' unique(mpg)[1:5]
#'
#' @include DuckDBColumn-class.R
#' @include DuckDBTable-utils.R
#' @include sql_call.R
#' @include sql_fun.R
#'
#' @keywords utilities methods
#'
#' @name DuckDBColumn-utils
NULL

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### SQL call method
###

#' @export
#' @importFrom S4Vectors new2
setMethod("sql_call", "DuckDBColumn", function(x, fun, ...) {
    new2("DuckDBColumn", table = callGeneric(x@table, fun, ...), check = FALSE)
})

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### SQL function discovery method
###

#' @export
setMethod("sql_fun", "DuckDBColumn",
function(x, function_type = NULL, return_type = NULL, description = FALSE)
{
    callGeneric(x@table, function_type, return_type, description)
})

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Group generic methods
###

#' @export
setMethod("Ops", c(e1 = "DuckDBColumn", e2 = "DuckDBColumn"), function(e1, e2) {
    replaceSlots(e1, table = callGeneric(e1@table, e2@table), check = FALSE)
})

#' @export
setMethod("Ops", c(e1 = "DuckDBColumn", e2 = "atomic"), function(e1, e2) {
    replaceSlots(e1, table = callGeneric(e1@table, e2), check = FALSE)
})

#' @export
setMethod("Ops", c(e1 = "atomic", e2 = "DuckDBColumn"), function(e1, e2) {
    replaceSlots(e2, table = callGeneric(e1, e2@table), check = FALSE)
})

#' @export
setMethod("Ops", c(e1 = "DuckDBColumn", e2 = "missing"), function(e1, e2) {
    # Unary operators (e.g., -, +)
    replaceSlots(e1, table = callGeneric(e1@table), check = FALSE)
})

#' @export
setMethod("!", "DuckDBColumn", function(x) {
    replaceSlots(x, table = !x@table, check = FALSE)
})

#' @export
setMethod("Math", "DuckDBColumn", function(x) {
    replaceSlots(x, table = callGeneric(x@table), check = FALSE)
})

#' @export
setMethod("Summary", "DuckDBColumn", function(x, ..., na.rm = FALSE) {
    callGeneric(x@table)
})

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Numerical methods
###

#' @export
setMethod("is.finite", "DuckDBColumn", function(x) {
    replaceSlots(x, table = callGeneric(x@table), check = FALSE)
})

#' @export
setMethod("is.infinite", "DuckDBColumn", function(x) {
    replaceSlots(x, table = callGeneric(x@table), check = FALSE)
})

#' @export
setMethod("is.nan", "DuckDBColumn", function(x) {
    replaceSlots(x, table = callGeneric(x@table), check = FALSE)
})

#' @export
setMethod("mean", "DuckDBColumn", function(x, ...) {
    callGeneric(x@table)
})

#' @export
setMethod("var", "DuckDBColumn", function(x, y = NULL, na.rm = FALSE, use)  {
    callGeneric(x@table)
})

#' @export
setMethod("sd", "DuckDBColumn", function(x, na.rm = FALSE) {
    callGeneric(x@table)
})

#' @exportS3Method stats::median
#' @importFrom stats median
median.DuckDBColumn <- function(x, na.rm = FALSE, ...) {
    median(x@table, na.rm = na.rm, ...)
}

#' @exportS3Method stats::quantile
#' @importFrom stats quantile
quantile.DuckDBColumn <-
function(x, probs = seq(0, 1, 0.25), na.rm = FALSE, names = TRUE, type = 7, digits = 7, ...) {
    quantile(x@table, probs = probs, na.rm = na.rm, names = names, type = type, digits = digits, ...)
}

#' @export
setMethod("mad", "DuckDBColumn",
function(x, center = median(x), constant = 1.4826, na.rm = FALSE, low = FALSE, high = FALSE) {
    callGeneric(x@table, constant = constant)
})

#' @export
setMethod("IQR", "DuckDBColumn", function(x, na.rm = FALSE, type = 7) {
    callGeneric(x@table, type = type)
})

#' @export
setMethod("pmax", "DuckDBColumn", function(..., na.rm = FALSE) {
    args <- list(...)
    table_args <- lapply(args, function(a) {
        if (is(a, "DuckDBColumn")) a@table else a
    })
    replaceSlots(args[[1L]], table = do.call(callGeneric, c(table_args, list(na.rm = na.rm))), check = FALSE)
})

#' @export
setMethod("pmin", "DuckDBColumn", function(..., na.rm = FALSE) {
    args <- list(...)
    table_args <- lapply(args, function(a) {
        if (is(a, "DuckDBColumn")) a@table else a
    })
    replaceSlots(args[[1L]], table = do.call(callGeneric, c(table_args, list(na.rm = na.rm))), check = FALSE)
})

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Character methods
###

#' @export
#' @importMethodsFrom S4Vectors nchar
setMethod("nchar", "DuckDBColumn", function(x, type = "chars", allowNA = FALSE, keepNA = NA) {
    replaceSlots(x, table = callGeneric(x@table, type = type, allowNA = allowNA, keepNA = keepNA), check = FALSE)
})

#' @export
#' @importMethodsFrom IRanges tolower
setMethod("tolower", "DuckDBColumn", function(x) {
    replaceSlots(x, table = callGeneric(x@table), check = FALSE)
})

#' @export
#' @importMethodsFrom IRanges toupper
setMethod("toupper", "DuckDBColumn", function(x) {
    replaceSlots(x, table = callGeneric(x@table), check = FALSE)
})

#' @export
#' @importMethodsFrom IRanges chartr
setMethod("chartr", signature(x = "DuckDBColumn"), function(old, new, x) {
    replaceSlots(x, table = callGeneric(old = old, new = new, x = x@table), check = FALSE)
})

#' @export
#' @importMethodsFrom S4Vectors substr
setMethod("substr", "DuckDBColumn", function(x, start, stop) {
    replaceSlots(x, table = callGeneric(x@table, start, stop), check = FALSE)
})

#' @export
#' @importMethodsFrom S4Vectors substring
setMethod("substring", "DuckDBColumn", function(text, first, last = 1000000L) {
    replaceSlots(text, table = callGeneric(text@table, first, last), check = FALSE)
})

#' @export
setMethod("grepl", signature(x = "DuckDBColumn"), function(pattern, x, ignore.case = FALSE, perl = FALSE, fixed = FALSE, useBytes = FALSE) {
    replaceSlots(x, table = callGeneric(pattern, x@table, ignore.case = ignore.case, perl = perl, fixed = fixed, useBytes = useBytes), check = FALSE)
})

#' @export
#' @importMethodsFrom IRanges sub
setMethod("sub", signature(x = "DuckDBColumn"), function(pattern, replacement, x, ignore.case = FALSE, perl = FALSE, fixed = FALSE, useBytes = FALSE) {
    replaceSlots(x, table = callGeneric(pattern, replacement, x@table, ignore.case = ignore.case, perl = perl, fixed = fixed, useBytes = useBytes), check = FALSE)
})

#' @export
#' @importMethodsFrom IRanges gsub
setMethod("gsub", signature(x = "DuckDBColumn"), function(pattern, replacement, x, ignore.case = FALSE, perl = FALSE, fixed = FALSE, useBytes = FALSE) {
    replaceSlots(x, table = callGeneric(pattern, replacement, x@table, ignore.case = ignore.case, perl = perl, fixed = fixed, useBytes = useBytes), check = FALSE)
})

#' @export
#' @importMethodsFrom IRanges startsWith
setMethod("startsWith", "DuckDBColumn", function(x, prefix) {
    replaceSlots(x, table = callGeneric(x@table, prefix), check = FALSE)
})

#' @export
#' @importMethodsFrom IRanges endsWith
setMethod("endsWith", "DuckDBColumn", function(x, suffix) {
    replaceSlots(x, table = callGeneric(x@table, suffix), check = FALSE)
})

#' @export
setMethod("paste2", signature(x = "DuckDBColumn", y = "DuckDBColumn"), function(x, y) {
    replaceSlots(x, table = callGeneric(x@table, y@table), check = FALSE)
})

#' @export
setMethod("paste2", signature(x = "DuckDBColumn", y = "character"), function(x, y) {
    replaceSlots(x, table = callGeneric(x@table, y), check = FALSE)
})

#' @export
setMethod("paste2", signature(x = "character", y = "DuckDBColumn"), function(x, y) {
    replaceSlots(y, table = callGeneric(x, y@table), check = FALSE)
})

#' @export
setMethod("paste", "DuckDBColumn", function(..., sep = " ", collapse = NULL) {
    args <- list(...)
    table_args <- lapply(args, function(a) {
        if (is(a, "DuckDBColumn")) a@table else a
    })
    replaceSlots(args[[1L]], table = do.call(callGeneric, c(table_args, list(sep = sep, collapse = collapse))), check = FALSE)
})

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Set methods
###

#' @export
setMethod("unique", "DuckDBColumn",
function (x, incomparables = FALSE, fromLast = FALSE, ...)  {
    replaceSlots(x, table = callGeneric(x@table), check = FALSE)
})

#' @export
setMethod("%in%", c(x = "DuckDBColumn", table = "ANY"), function(x, table) {
    replaceSlots(x, table = callGeneric(x@table, table), check = FALSE)
})

#' @export
setMethod("table", "DuckDBColumn", function(x, ...) {
    callGeneric(cbind.DuckDBDataFrame(x, ...))
})

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Sparsity methods
###

#' @export
#' @importFrom SparseArray is_nonzero
setMethod("is_nonzero", "DuckDBColumn", function(x) {
    replaceSlots(x, table = callGeneric(x@table), check = FALSE)
})

#' @export
#' @importFrom SparseArray nzcount
setMethod("nzcount", "DuckDBColumn", function(x) {
    callGeneric(x@table)
})
