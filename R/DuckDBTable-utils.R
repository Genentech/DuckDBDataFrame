#' Common operations on DuckDBTable objects
#'
#' @description
#' Common operations on \linkS4class{DuckDBTable} objects.
#'
#' @section SQL Methods:
#' In the code snippets below, \code{x} is a DuckDBTable object:
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
#' DuckDBTable objects have support for S4 group generic functionality:
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
#'  The \code{Summary} methods, \code{mean()}, \code{var()}, \code{sd()} and
#'  \code{median()} take \code{na.rm} as base R does. With
#'  \code{na.rm = FALSE} (the default) a missing value, SQL \code{NULL}, gives
#'  \code{NA}. A \code{NaN} gives \code{NaN} for \code{sum}, \code{prod},
#'  \code{mean}, \code{min} and \code{max}, and \code{NA} for \code{var},
#'  \code{sd} and \code{median}. With \code{na.rm = TRUE} the missing values
#'  and \code{NaN} are dropped, and an aggregate with nothing left is the value
#'  base R gives for an empty set: 0 for \code{sum}, 1 for \code{prod},
#'  \code{NaN} for \code{mean}, \code{Inf} for \code{min} and \code{-Inf} for
#'  \code{max}.
#'
#' @section Numerical Data Methods:
#' In the code snippets below, \code{x} is a DuckDBTable object:
#' \describe{
#'   \item{\code{anyNA(x)}:}{
#'     Returns a single logical: \code{TRUE} if any value in \code{x} is
#'     missing.
#'   }
#'   \item{\code{is.finite(x)}:}{
#'     Returns a DuckDBTable containing logicals that indicate which values are
#'     finite.
#'   }
#'   \item{\code{is.infinite(x)}:}{
#'     Returns a DuckDBTable containing logicals that indicate which values are
#'     infinite.
#'   }
#'   \item{\code{is.na(x)}:}{
#'     Returns a DuckDBTable containing logicals that indicate which values are
#'     missing (SQL \code{NULL}, or \code{NaN} in a floating point column).
#'   }
#'   \item{\code{is.nan(x)}:}{
#'     Returns a DuckDBTable containing logicals that indicate which values are
#'     Not a Number.
#'   }
#'   \item{\code{mean(x, na.rm = FALSE)}:}{
#'     Calculates the mean of \code{x}.
#'   }
#'   \item{\code{var(x, na.rm = FALSE)}:}{
#'     Calculates the variance of \code{x}.
#'   }
#'   \item{\code{sd(x, na.rm = FALSE)}:}{
#'     Calculates the standard deviation of \code{x}.
#'   }
#'   \item{\code{median(x, na.rm = FALSE)}:}{
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
#'     Returns the parallel maxima of multiple DuckDBTable objects.
#'     All arguments must be DuckDBTable objects with compatible dimensions.
#'   }
#'   \item{\code{pmin(..., na.rm = FALSE)}:}{
#'     Returns the parallel minima of multiple DuckDBTable objects.
#'     All arguments must be DuckDBTable objects with compatible dimensions.
#'   }
#' }
#'
#' @section Character Methods:
#' In the code snippets below, \code{x} is a DuckDBTable object:
#' \describe{
#'   \item{\code{nchar(x)}:}{
#'     Returns a DuckDBTable containing the number of characters in each
#'     string.
#'   }
#'   \item{\code{tolower(x)}:}{
#'     Returns a DuckDBTable with all strings converted to lowercase.
#'   }
#'   \item{\code{toupper(x)}:}{
#'     Returns a DuckDBTable with all strings converted to uppercase.
#'   }
#'   \item{\code{chartr(old, new, x)}:}{
#'     Returns a DuckDBTable with characters translated.
#'     \describe{
#'       \item{\code{old}}{Characters to be translated.}
#'       \item{\code{new}}{Characters to translate to.}
#'     }
#'   }
#'   \item{\code{substr(x, start, stop)}:}{
#'     Returns a DuckDBTable containing substrings extracted by position.
#'     \describe{
#'       \item{\code{start}}{Integer starting position (1-indexed).}
#'       \item{\code{stop}}{Integer ending position (inclusive).}
#'     }
#'   }
#'   \item{\code{substring(x, first, last = 1000000L)}:}{
#'     Returns a DuckDBTable containing substrings extracted by position.
#'     \describe{
#'       \item{\code{first}}{Integer starting position (1-indexed).}
#'       \item{\code{last}}{Integer ending position (inclusive).}
#'     }
#'   }
#'   \item{\code{grepl(pattern, x, ignore.case = FALSE, fixed = FALSE)}:}{
#'     Returns a DuckDBTable containing logicals indicating pattern matches.
#'     \describe{
#'       \item{\code{pattern}}{Character string containing a regular expression.}
#'       \item{\code{ignore.case}}{If \code{TRUE}, case-insensitive matching.}
#'       \item{\code{fixed}}{If \code{TRUE}, pattern is a fixed string not regex.}
#'     }
#'   }
#'   \item{\code{sub(pattern, replacement, x, ignore.case = FALSE, fixed = FALSE)}:}{
#'     Returns a DuckDBTable with first match of pattern replaced.
#'     \describe{
#'       \item{\code{pattern}}{Character string containing a regular expression.}
#'       \item{\code{replacement}}{Replacement string.}
#'       \item{\code{ignore.case}}{If \code{TRUE}, case-insensitive matching.}
#'       \item{\code{fixed}}{If \code{TRUE}, pattern is a fixed string not regex.}
#'     }
#'   }
#'   \item{\code{gsub(pattern, replacement, x, ignore.case = FALSE, fixed = FALSE)}:}{
#'     Returns a DuckDBTable with all matches of pattern replaced.
#'     \describe{
#'       \item{\code{pattern}}{Character string containing a regular expression.}
#'       \item{\code{replacement}}{Replacement string.}
#'       \item{\code{ignore.case}}{If \code{TRUE}, case-insensitive matching.}
#'       \item{\code{fixed}}{If \code{TRUE}, pattern is a fixed string not regex.}
#'     }
#'   }
#'   \item{\code{startsWith(x, prefix)}:}{
#'     Returns a DuckDBTable containing logicals indicating if strings start
#'     with the specified prefix.
#'   }
#'   \item{\code{endsWith(x, suffix)}:}{
#'     Returns a DuckDBTable containing logicals indicating if strings end
#'     with the specified suffix.
#'   }
#'   \item{\code{paste(..., sep = " ", collapse = NULL)}:}{
#'     Concatenates multiple DuckDBTable objects column-wise using the
#'     specified separator. The \code{collapse} argument is not supported.
#'     All arguments must be DuckDBTable objects with compatible dimensions.
#'   }
#' }
#'
#' @section General Methods:
#' In the code snippets below, \code{x} is a DuckDBTable object:
#' \describe{
#'   \item{\code{unique(x)}:}{
#'     Returns a DuckDBTable containing the distinct rows.
#'   }
#'   \item{\code{x \%in\% table}:}{
#'     Returns a DuckDBTable containing logicals that indicate if the
#'     values in each of the columns of \code{x} are in \code{table}.
#'   }
#'   \item{\code{table(...)}:}{
#'     Returns a table containing the counts across the distinct values.
#'   }
#' }
#'
#' @section List Methods:
#' In the code snippets below, \code{x} is a DuckDBTable object:
#' \describe{
#'   \item{\code{elementNROWS(x)}:}{
#'     Returns a DuckDBTable containing the number of elements in each list
#'     column of \code{x}.
#'   }
#' }
#'
#' @section Sparsity Methods:
#' In the code snippets below, \code{x} is a DuckDBTable object:
#' \describe{
#'   \item{\code{is_nonzero(x)}:}{
#'     Returns a DuckDBTable containing logicals that indicate if the
#'     values in each of the columns of \code{x} are non-zero.
#'   }
#'   \item{\code{nzcount(x)}:}{
#'     Returns the total number of non-zero values.
#'   }
#'   \item{\code{is_sparse(x)}:}{
#'     Returns \code{TRUE} since data are stored in a sparse array representation.
#'   }
#' }
#'
#' @return
#' Method return types are documented in the sections above.
#'
#' @author Patrick Aboyoun
#'
#' @seealso
#' \itemize{
#'   \item \code{\link{DuckDBTable-class}} for the main class
#'   \item \code{\link[S4Vectors]{RectangularData}} for the base class
#' }
#'
#' @aliases sql_call,DuckDBTable-method
#' @aliases sql_fun,DuckDBTable-method
#'
#' @aliases Ops,DuckDBTable,DuckDBTable-method
#' @aliases Ops,DuckDBTable,atomic-method
#' @aliases Ops,atomic,DuckDBTable-method
#' @aliases Ops,DuckDBTable,missing-method
#' @aliases !,DuckDBTable-method
#' @aliases Math,DuckDBTable-method
#' @aliases Summary,DuckDBTable-method
#'
#' @aliases anyNA,DuckDBTable-method
#' @aliases is.finite,DuckDBTable-method
#' @aliases is.infinite,DuckDBTable-method
#' @aliases is.na,DuckDBTable-method
#' @aliases is.nan,DuckDBTable-method
#' @aliases mean,DuckDBTable-method
#' @aliases var,DuckDBTable,ANY-method
#' @aliases sd,DuckDBTable-method
#' @aliases median.DuckDBTable
#' @aliases quantile.DuckDBTable
#' @aliases mad,DuckDBTable-method
#' @aliases IQR,DuckDBTable-method
#'
#' @aliases nchar,DuckDBTable-method
#' @aliases tolower,DuckDBTable-method
#' @aliases toupper,DuckDBTable-method
#' @aliases chartr,ANY,ANY,DuckDBTable-method
#' @aliases substr,DuckDBTable-method
#' @aliases substring,DuckDBTable-method
#' @aliases grepl,ANY,DuckDBTable-method
#' @aliases sub,ANY,ANY,DuckDBTable-method
#' @aliases gsub,ANY,ANY,DuckDBTable-method
#' @aliases startsWith,DuckDBTable-method
#' @aliases endsWith,DuckDBTable-method
#' @aliases paste2,DuckDBTable,DuckDBTable-method
#' @aliases paste2,DuckDBTable,character-method
#' @aliases paste2,character,DuckDBTable-method
#' @aliases paste,DuckDBTable-method
#' @aliases pmax,DuckDBTable-method
#' @aliases pmin,DuckDBTable-method
#'
#' @aliases unique,DuckDBTable-method
#' @aliases %in%,DuckDBTable,ANY-method
#' @aliases table,DuckDBTable-method
#'
#' @aliases elementNROWS,DuckDBTable-method
#'
#' @aliases is_nonzero,DuckDBTable-method
#' @aliases nzcount,DuckDBTable-method
#' @aliases is_sparse,DuckDBTable-method
#'
#' @examples
#' tf <- tempfile(fileext = ".parquet")
#' on.exit(unlink(tf))
#' arrow::write_parquet(cbind(model = rownames(mtcars), mtcars), tf)
#' tbl <- DuckDBTable(tf, datacols = colnames(mtcars), keycol = "model")
#' mean(tbl[, "mpg"])
#' head(tbl, 3)
#'
#' @include DuckDBTable-class.R
#' @include sql_call.R
#' @include sql_fun.R
#'
#' @keywords utilities methods
#'
#' @name DuckDBTable-utils
NULL

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### SQL call method
###

#' @export
#' @importFrom S4Vectors endoapply
setMethod("sql_call", "DuckDBTable", function(x, fun, ...) {
    FUN <- function(j) do.call("call", list(fun, j, ...), quote = TRUE)
    datacols <- endoapply(x@datacols, FUN)
    replaceSlots(x, datacols = datacols, check = FALSE)
})

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### SQL function discovery method
###

#' @export
#' @importFrom DBI dbGetQuery dbQuoteString
#' @importFrom dbplyr sql_render
setMethod("sql_fun", "DuckDBTable",
function(x, function_type = NULL, return_type = NULL, description = FALSE)
{
    conn <- dbconn(x)
    if (is.null(conn) || !inherits(conn, "duckdb_connection")) {
        stop("could not extract DuckDB connection from object")
    }

    tblconn <- tblconn(x)
    if (!inherits(tblconn, "tbl_duckdb_connection")) {
        stop("could not extract table connection from object")
    }

    colname <- colnames(x)
    if (length(colname) != 1L) {
        stop("expected exactly one data column")
    }

    sql <- sql_render(tblconn)
    schema <- dbGetQuery(conn, sprintf("DESCRIBE (%s)", sql))

    dtype <- schema$column_type[schema$column_name == colname]
    if (length(dtype) == 0L) {
        stop("could not find column '", colname, "' in schema")
    }

    # Array types ends with [] and match generic array types (T[], ANY[])
    # Non-array types also match generic ANY
    # Match only the first parameter (parameter_types[1])
    is_array <- grepl("\\[\\]$", dtype)
    if (is_array) {
        predicate <- sprintf(
"(parameter_types[1] = '%s' OR
  parameter_types[1] = 'T[]' OR
  parameter_types[1] = 'ANY[]')",
                             dtype)
    } else {
        predicate <- sprintf(
"(parameter_types[1] = '%s' OR
  parameter_types[1] = 'ANY')",
                             dtype)
    }

    if (length(return_type) > 0L) {
        if (!is.character(return_type)) {
            stop("'return_type' must be a character vector")
        }
        types_sql <- paste(dbQuoteString(conn, return_type), collapse = ", ")
        predicate <- c(predicate, sprintf("return_type IN (%s)", types_sql))
    }

    if (length(function_type) > 0L) {
        allowed_ftypes <- c("scalar", "aggregate", "macro", "table", "pragma", "table_macro")
        ftypes <- match.arg(function_type, allowed_ftypes, several.ok = TRUE)
        ftypes_sql <- paste(dbQuoteString(conn, ftypes), collapse = ", ")
        predicate <- c(predicate, sprintf("function_type IN (%s)", ftypes_sql))
    }

    predicate <- paste(predicate, collapse = " AND ")

    slist <- c("function_name", "alias_of", "function_type",
               "list(DISTINCT return_type) as return_type")
    if (description) {
        slist <- c(slist, "any_value(description) as description")
    }
    slist <- paste(slist, collapse = ",\n  ")

    query <- sprintf(
"SELECT
  %s
FROM duckdb_functions()
WHERE %s
GROUP BY function_name, alias_of, function_type
ORDER BY function_name",
                     slist,
                     predicate)

    dbGetQuery(conn, query)
})

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Group generic methods
###

#' @importFrom stats setNames
.Ops.DuckDBTable <- function(.Generic, x, fin1, fin2, fout) {
    datacols <- setNames(as.expression(Map(function(x, y) call(.Generic, x, y), fin1, fin2)), fout)
    replaceSlots(x, datacols = datacols, check = FALSE)
}

#' @export
setMethod("Ops", c(e1 = "DuckDBTable", e2 = "DuckDBTable"), function(e1, e2) {
    if (!isTRUE(all.equal(e1, e2)) || ((ncol(e1) > 1L) && (ncol(e2) > 1L) && (ncol(e1) != ncol(e2)))) {
        stop("can only perform binary operations with compatible objects")
    }
    comb <- cbind(e1, e2)
    fin1 <- head(comb@datacols, ncol(e1))
    fin2 <- tail(comb@datacols, ncol(e2))
    if (ncol(e1) >= ncol(e2)) {
        fout <- colnames(e1)
    } else {
        fout <- colnames(e2)
    }
    .Ops.DuckDBTable(.Generic, x = comb, fin1 = fin1, fin2 = fin2, fout = fout)
})

#' @export
setMethod("Ops", c(e1 = "DuckDBTable", e2 = "atomic"), function(e1, e2) {
    if (length(e2) != 1L) {
        stop("can only perform binary operations with a scalar value")
    }
    .Ops.DuckDBTable(.Generic, x = e1, fin1 = e1@datacols, fin2 = e2, fout = colnames(e1))
})

#' @export
setMethod("Ops", c(e1 = "atomic", e2 = "DuckDBTable"), function(e1, e2) {
    if (length(e1) != 1L) {
        stop("can only perform binary operations with a scalar value")
    }
    .Ops.DuckDBTable(.Generic, x = e2, fin1 = e1, fin2 = e2@datacols, fout = colnames(e2))
})

#' @export
setMethod("Ops", c(e1 = "DuckDBTable", e2 = "missing"), function(e1, e2) {
    sql_call(e1, .Generic)
})

#' @export
setMethod("!", "DuckDBTable", function(x) {
    sql_call(x, "!")
})

#' @export
setMethod("Math", "DuckDBTable", function(x) {
    if (.Generic == "log1p") {
        return(log(x + 1))
    } else if (.Generic == "expm1") {
        return(exp(x) - 1)
    }
    datacols <-
      switch(.Generic,
             abs =,
             sign =,
             sqrt =,
             ceiling =,
             floor =,
             trunc =,
             log =,
             log10 =,
             log2 =,
             acos =,
             acosh =,
             asin =,
             asinh =,
             atan =,
             atanh =,
             exp =,
             cos =,
             cosh =,
             sin =,
             sinh =,
             tan =,
             tanh =,
             gamma =,
             lgamma = {
                sql_call(x, .Generic)
             },
             stop("unsupported Math operator: ", .Generic))
})

#' @importFrom dplyr pull summarize
.pull.aggregagte <- function(x, fun, na.rm = FALSE) {
    if (length(x@datacols) != 1L) {
        stop("aggregation requires a single datacols")
    }
    if (na.rm) {
        aggr <- call(fun, x@datacols[[1L]], na.rm = TRUE)
    } else {
        aggr <- call(fun, x@datacols[[1L]])
    }
    pull(summarize(tblconn(x, select = FALSE), !!aggr))
}

### Aggregates and missing values
###
### An aggregate follows base R for a missing value. With na.rm = FALSE a
### missing value gives NA; a NaN gives NaN for a sum, a product, a mean and a
### maximum, which SQL already does, and for a minimum, which needs a guard
### because DuckDB orders NaN above every number; and a NaN gives NA for a
### variance, a standard deviation and a median. With na.rm = TRUE a NaN is
### dropped as an NA is, and an aggregate with nothing left is the value base R
### gives for an empty set: 0 for a sum, 1 for a product, NaN for a mean, Inf
### for a minimum and -Inf for a maximum.
###
### Only a floating point column can hold a NaN. The test is is.nan(), which
### dbplyr writes as a printf() comparison. DuckDB's own isnan() is not used: on
### a Parquet column that has no NULL it gives FALSE for a stored NaN in DuckDB
### 2.0.0, apparently because the file statistics leave NaN out. printf() cannot
### format an integer, so the other types are left alone.

.aggrCanHoldNaN <- function(x) {
    identical(unname(coltypes(x)), "double")
}

.aggrSQL <- function(value) dplyr::sql(sprintf("CAST('%s' AS DOUBLE)", value))

# The SQL for one aggregate, 'fun', of the single data column of 'x'. 'nan' is
# how a NaN counts when na.rm = FALSE: "keep" leaves SQL's own result, "na"
# makes the result NA and "nan" makes it NaN.
.aggrExpr <- function(x, y, fun, na.rm, nan = c("keep", "na", "nan")) {
    nan <- match.arg(nan)
    # fsum() is a DuckDB function with no na.rm argument; it skips NULL as sum()
    # does
    stat <- if (fun == "fsum") call(fun, y) else call(fun, y, na.rm = TRUE)
    if (na.rm) {
        return(stat)
    }
    count_of <- function(test) {
        call(">", call("coalesce", call("sum", call("as.integer", test), na.rm = TRUE), 0L), 0L)
    }
    can_nan <- .aggrCanHoldNaN(x)
    missing <- call("is.na", y)
    if (nan == "na" && can_nan) {
        missing <- call("|", missing, call("is.nan", y))
    } else if (nan == "nan" && can_nan) {
        stat <- call("ifelse", count_of(call("is.nan", y)), .aggrSQL("NaN"), stat)
    }
    call("ifelse", count_of(missing), NA, stat)
}

# Compute the aggregates in 'specs', a named list of list(fun, nan, empty), over
# the single data column of 'x' in one query. 'empty' is the result when no
# value is left; it is applied here and not in SQL, which would change the type
# of an integer result.
#' @importFrom dplyr collect summarize
.aggregate <- function(x, specs, na.rm = FALSE) {
    if (length(x@datacols) != 1L) {
        stop("aggregation requires a single datacols")
    }
    if (!isTRUE(na.rm) && !isFALSE(na.rm)) {
        stop("'na.rm' must be TRUE or FALSE")
    }
    y <- x@datacols[[1L]]
    if (na.rm && .aggrCanHoldNaN(x)) {
        y <- call("ifelse", call("is.nan", y), NA, y)
    }
    aggr <- lapply(specs, function(spec) .aggrExpr(x, y, spec$fun, na.rm, spec$nan))
    aggr[[".nonmissing"]] <- call("count", y)
    aggr[[".n"]] <- call("n")
    res <- as.data.frame(collect(summarize(tblconn(x, select = FALSE), !!!aggr)))
    nothing_left <- res[[".n"]] == 0L || (na.rm && res[[".nonmissing"]] == 0L)
    ans <- lapply(names(specs), function(nm) {
        value <- res[[nm]]
        if (nothing_left && is.na(value)) specs[[nm]]$empty else value
    })
    names(ans) <- names(specs)
    ans
}

.aggrSpec <- function(fun, nan = "keep", empty = NA_real_) {
    list(fun = fun, nan = nan, empty = empty)
}

# any() and all() of a logical column
.aggregateLogical <- function(x, which, na.rm) {
    if (length(x@datacols) != 1L) {
        stop("aggregation requires a single datacols")
    }
    y <- x@datacols[[1L]]
    n_of <- function(test) {
        call("coalesce", call("sum", call("as.integer", test), na.rm = TRUE), 0L)
    }
    if (which == "any") {
        hit <- call(">", n_of(y), 0L)
        value <- FALSE
    } else {
        hit <- call(">", n_of(call("!", y)), 0L)
        value <- TRUE
    }
    nas <- call(">", n_of(call("is.na", y)), 0L)
    decided <- if (which == "any") TRUE else FALSE
    expr <- if (na.rm) {
        if (which == "any") hit else call("!", hit)
    } else {
        call("ifelse", hit, decided, call("ifelse", nas, NA, value))
    }
    res <- collect(summarize(tblconn(x, select = FALSE), !!expr))
    res[[1L]]
}

#' @export
setMethod("Summary", "DuckDBTable", function(x, ..., na.rm = FALSE) {
    one <- function(spec) .aggregate(x, list(value = spec), na.rm)[["value"]]
    switch(.Generic,
           min = one(.aggrSpec("min", "nan", Inf)),
           max = one(.aggrSpec("max", "keep", -Inf)),
           sum = one(.aggrSpec("fsum", "keep", 0)),
           prod = one(.aggrSpec("prod", "keep", 1)),
           range = {
               ans <- .aggregate(x, list(min = .aggrSpec("min", "nan", Inf),
                                         max = .aggrSpec("max", "keep", -Inf)), na.rm)
               unlist(ans, use.names = FALSE)
           },
           any = .aggregateLogical(x, "any", na.rm),
           all = .aggregateLogical(x, "all", na.rm),
           stop("unsupported Summary operator: ", .Generic))
})

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Numerical methods
###

# A NaN is missing for is.na() and anyNA(), as in base R. Only a floating point
# column can hold one, and DuckDB's own isnan() is not used; see is.nan().
.isNaExpr <- function(j, type) {
    if (identical(type, "double")) {
        call("|", call("is.na", j), call("is.nan", j))
    } else {
        call("is.na", j)
    }
}

#' @export
#' @importFrom dplyr pull summarize
#' @importFrom S4Vectors mendoapply
setMethod("anyNA", "DuckDBTable", function(x, recursive = FALSE) {
    types <- coltypes(x)
    exprs <- mendoapply(.isNaExpr, x@datacols, types[names(x@datacols)])
    combined <- Reduce(function(a, b) call("|", a, b), exprs)
    aggr <- call("any", combined, na.rm = TRUE)
    pull(summarize(tblconn(x, select = FALSE), !!aggr))
})

# is.finite() and is.infinite() are never NA in base R, but isfinite() and
# isinf() are NULL for a missing value, so a missing value is FALSE.
.noNAexpr <- function(x, fun) {
    datacols <- x@datacols
    datacols <- as.expression(setNames(
        lapply(datacols, function(j) call("coalesce", call(fun, j), FALSE)),
        names(datacols)))
    replaceSlots(x, datacols = datacols, check = FALSE)
}

#' @export
setMethod("is.finite", "DuckDBTable", function(x) {
    .noNAexpr(x, "isfinite")
})

#' @export
setMethod("is.infinite", "DuckDBTable", function(x) {
    .noNAexpr(x, "isinf")
})

#' @export
#' @importFrom S4Vectors mendoapply
setMethod("is.na", "DuckDBTable", function(x) {
    types <- coltypes(x)
    datacols <- mendoapply(.isNaExpr, x@datacols, types[names(x@datacols)])
    replaceSlots(x, datacols = datacols, check = FALSE)
})

#' @export
setMethod("is.nan", "DuckDBTable", function(x) {
    # dbplyr writes is.nan() as a printf() comparison, which cannot format an
    # integer, and an integer cannot be NaN. DuckDB's own isnan() is not used:
    # on a Parquet column that has no NULL it returns FALSE for a stored NaN in
    # DuckDB 2.0.0, apparently because the file statistics leave NaN out.
    types <- coltypes(x)
    datacols <- x@datacols
    datacols <- as.expression(setNames(
        lapply(names(datacols), function(nm)
               if (identical(types[[nm]], "double"))
                   call("is.nan", datacols[[nm]]) else FALSE),
        names(datacols)))
    replaceSlots(x, datacols = datacols, check = FALSE)
})

#' @export
setMethod("mean", "DuckDBTable", function(x, na.rm = FALSE, ...) {
    .aggregate(x, list(value = .aggrSpec("mean", "keep", NaN)), na.rm)[["value"]]
})

#' @export
setMethod("var", "DuckDBTable", function(x, y = NULL, na.rm = FALSE, use)  {
    if (!is.null(y)) {
        stop("covariance is not supported")
    }
    .aggregate(x, list(value = .aggrSpec("var", "na")), na.rm)[["value"]]
})

#' @export
setMethod("sd", "DuckDBTable", function(x, na.rm = FALSE) {
    .aggregate(x, list(value = .aggrSpec("sd", "na")), na.rm)[["value"]]
})

#' @exportS3Method stats::median
#' @importFrom stats median
median.DuckDBTable <- function(x, na.rm = FALSE, ...) {
    .aggregate(x, list(value = .aggrSpec("median", "na")), na.rm)[["value"]]
}

#' @exportS3Method stats::quantile
#' @importFrom dplyr summarize
#' @importFrom S4Vectors isSingleNumber
#' @importFrom stats quantile
quantile.DuckDBTable <-
function(x, probs = seq(0, 1, 0.25), na.rm = FALSE, names = TRUE, type = 7, digits = 7, ...) {
    if (length(x@datacols) != 1L) {
        stop("aggregation requires a single datacols")
    }
    if (!isSingleNumber(type) || !(type %in% c(1L, 7L))) {
        stop("'type' must be 1 or 7")
    } else if (type == 1L) {
        fun <- "quantile_disc"
    } else {
        fun <- "quantile_cont"
    }
    aggr <- lapply(probs, function(p) call(fun, x@datacols[[1L]], p))
    ans <- unlist(as.data.frame(summarize(tblconn(x, select = FALSE), !!!aggr)),
                  use.names = FALSE)
    if (names) {
        stopifnot(isSingleNumber(digits), digits >= 1)
        names(ans) <- paste0(formatC(100 * probs, format = "fg", width = 1, digits = digits), "%")
    }
    ans
}

#' @export
setMethod("mad", "DuckDBTable",
function(x, center = median(x), constant = 1.4826, na.rm = FALSE, low = FALSE, high = FALSE) {
    constant * .pull.aggregagte(x, "mad")
})

#' @export
setMethod("IQR", "DuckDBTable", function(x, na.rm = FALSE, type = 7) {
    diff(quantile(x, c(0.25, 0.75), na.rm = na.rm, names = FALSE, type = type))
})

#' @importFrom stats setNames
.pmaxTwoDuckDBTables <- function(x, y) {
    if (!isTRUE(all.equal(x, y)) || ((ncol(x) > 1L) && (ncol(y) > 1L) && (ncol(x) != ncol(y)))) {
        stop("can only perform operations with compatible objects")
    }
    comb <- cbind(x, y)
    fin1 <- head(comb@datacols, ncol(x))
    fin2 <- tail(comb@datacols, ncol(y))
    fout <- if (ncol(x) >= ncol(y)) colnames(x) else colnames(y)
    datacols <- setNames(as.expression(Map(function(a, b) call("greatest", a, b), fin1, fin2)), fout)
    replaceSlots(comb, datacols = datacols, check = FALSE)
}

#' @export
setMethod("pmax", "DuckDBTable", function(..., na.rm = FALSE) {
    args <- list(...)
    ans <- args[[1L]]
    if (length(args) > 1L) {
        for (i in 2:length(args)) {
            if (is(args[[i]], "DuckDBTable")) {
                ans <- .pmaxTwoDuckDBTables(ans, args[[i]])
            } else if (is.atomic(args[[i]])) {
                if (length(args[[i]]) != 1L) {
                    stop("can only perform operations with scalar values")
                }
                datacols <- setNames(as.expression(Map(function(col) call("greatest", col, args[[i]]), ans@datacols)), colnames(ans))
                ans <- replaceSlots(ans, datacols = datacols, check = FALSE)
            } else {
                stop("all arguments must be DuckDBTable objects or scalar values")
            }
        }
    }
    ans
})

#' @importFrom stats setNames
.pminTwoDuckDBTables <- function(x, y) {
    if (!isTRUE(all.equal(x, y)) || ((ncol(x) > 1L) && (ncol(y) > 1L) && (ncol(x) != ncol(y)))) {
        stop("can only perform operations with compatible objects")
    }
    comb <- cbind(x, y)
    fin1 <- head(comb@datacols, ncol(x))
    fin2 <- tail(comb@datacols, ncol(y))
    fout <- if (ncol(x) >= ncol(y)) colnames(x) else colnames(y)
    datacols <- setNames(as.expression(Map(function(a, b) call("least", a, b), fin1, fin2)), fout)
    replaceSlots(comb, datacols = datacols, check = FALSE)
}

#' @export
setMethod("pmin", "DuckDBTable", function(..., na.rm = FALSE) {
    args <- list(...)
    ans <- args[[1L]]
    if (length(args) > 1L) {
        for (i in 2:length(args)) {
            if (is(args[[i]], "DuckDBTable")) {
                ans <- .pminTwoDuckDBTables(ans, args[[i]])
            } else if (is.atomic(args[[i]])) {
                if (length(args[[i]]) != 1L) {
                    stop("can only perform operations with scalar values")
                }
                datacols <- setNames(as.expression(Map(function(col) call("least", col, args[[i]]), ans@datacols)), colnames(ans))
                ans <- replaceSlots(ans, datacols = datacols, check = FALSE)
            } else {
                stop("all arguments must be DuckDBTable objects or scalar values")
            }
        }
    }
    ans
})

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Character methods
###

#' @export
#' @importMethodsFrom S4Vectors nchar
setMethod("nchar", "DuckDBTable", function(x, type = "chars", allowNA = FALSE, keepNA = NA) {
    sql_call(x, "length")
})

#' @export
#' @importMethodsFrom IRanges tolower
setMethod("tolower", "DuckDBTable", function(x) {
    sql_call(x, "lower")
})

#' @export
#' @importMethodsFrom IRanges toupper
setMethod("toupper", "DuckDBTable", function(x) {
    sql_call(x, "upper")
})

#' @export
#' @importMethodsFrom IRanges chartr
setMethod("chartr", signature(x = "DuckDBTable"), function(old, new, x) {
    if (missing(old) || missing(new)) {
        stop("'old' and 'new' are required")
    }
    sql_call(x, "translate", as.character(old), as.character(new))
})

#' @export
#' @importMethodsFrom S4Vectors substr
setMethod("substr", "DuckDBTable", function(x, start, stop) {
    if (missing(start) || missing(stop)) {
        stop("'start' and 'stop' are required")
    }
    sql_call(x, "substr", as.integer(start), as.integer(stop))
})

#' @export
#' @importMethodsFrom S4Vectors substring
setMethod("substring", "DuckDBTable", function(text, first, last = 1000000L) {
    if (missing(first)) {
        stop("'first' is required")
    }
    sql_call(text, "substr", as.integer(first), as.integer(last))
})

#' @export
setMethod("grepl", signature(x = "DuckDBTable"), function(pattern, x, ignore.case = FALSE, perl = FALSE, fixed = FALSE, useBytes = FALSE) {
    if (fixed) {
        if (ignore.case) {
            pattern_lower <- tolower(as.character(pattern))
            tbl <- sql_call(sql_call(x, "lower"), "contains", pattern_lower)
        } else {
            tbl <- sql_call(x, "contains", pattern)
        }
    } else {
        if (ignore.case) {
            tbl <- sql_call(x, "regexp_matches", paste0("(?i)", pattern))
        } else {
            tbl <- sql_call(x, "regexp_matches", pattern)
        }
    }
    coltypes(tbl) <- rep.int("logical", ncol(tbl))
    tbl
})

#' @export
#' @importMethodsFrom IRanges sub
setMethod("sub", signature(x = "DuckDBTable"), function(pattern, replacement, x, ignore.case = FALSE, perl = FALSE, fixed = FALSE, useBytes = FALSE) {
    if (fixed) {
        escaped_pattern <- base::gsub("([.*+?^${}()|[\\]\\\\])", "\\\\\\1", pattern)
        if (ignore.case) {
            sql_call(x, "regexp_replace", paste0("(?i)", escaped_pattern), replacement)
        } else {
            sql_call(x, "regexp_replace", escaped_pattern, replacement)
        }
    } else {
        if (ignore.case) {
            sql_call(x, "regexp_replace", paste0("(?i)", pattern), replacement)
        } else {
            sql_call(x, "regexp_replace", pattern, replacement)
        }
    }
})

#' @export
#' @importMethodsFrom IRanges gsub
setMethod("gsub", signature(x = "DuckDBTable"), function(pattern, replacement, x, ignore.case = FALSE, perl = FALSE, fixed = FALSE, useBytes = FALSE) {
    if (fixed) {
        if (ignore.case) {
            escaped_pattern <- base::gsub("([.*+?^${}()|[\\]\\\\])", "\\\\\\1", pattern)
            sql_call(x, "regexp_replace", paste0("(?i)", escaped_pattern), replacement, "g")
        } else {
            sql_call(x, "replace", pattern, replacement)
        }
    } else {
        if (ignore.case) {
            sql_call(x, "regexp_replace", paste0("(?i)", pattern), replacement, "g")
        } else {
            sql_call(x, "regexp_replace", pattern, replacement, "g")
        }
    }
})

#' @export
#' @importMethodsFrom IRanges startsWith
setMethod("startsWith", "DuckDBTable", function(x, prefix) {
    tbl <- sql_call(x, "starts_with", prefix)
    coltypes(tbl) <- rep.int("logical", ncol(tbl))
    tbl
})

#' @export
#' @importMethodsFrom IRanges endsWith
setMethod("endsWith", "DuckDBTable", function(x, suffix) {
    tbl <- sql_call(x, "suffix", suffix)
    coltypes(tbl) <- rep.int("logical", ncol(tbl))
    tbl
})

#' @export
setMethod("paste2", signature(x = "DuckDBTable", y = "DuckDBTable"), function(x, y) {
    if (!isTRUE(all.equal(x, y)) || ((ncol(x) > 1L) && (ncol(y) > 1L) && (ncol(x) != ncol(y)))) {
        stop("can only perform binary operations with compatible objects")
    }
    comb <- cbind(x, y)
    fin1 <- head(comb@datacols, ncol(x))
    fin2 <- tail(comb@datacols, ncol(y))
    if (ncol(x) >= ncol(y)) {
        fout <- colnames(x)
    } else {
        fout <- colnames(y)
    }
    datacols <- setNames(as.expression(Map(function(x, y) call("concat", x, y), fin1, fin2)), fout)
    replaceSlots(comb, datacols = datacols, check = FALSE)
})

#' @export
setMethod("paste2", signature(x = "DuckDBTable", y = "character"), function(x, y) {
    if (length(y) != 1L) {
        stop("can only perform binary operations with a scalar value")
    }
    datacols <- setNames(as.expression(Map(function(col) call("concat", col, y), x@datacols)), colnames(x))
    replaceSlots(x, datacols = datacols, check = FALSE)
})

#' @export
setMethod("paste2", signature(x = "character", y = "DuckDBTable"), function(x, y) {
    if (length(x) != 1L) {
        stop("can only perform binary operations with a scalar value")
    }
    datacols <- setNames(as.expression(Map(function(col) call("concat", x, col), y@datacols)), colnames(y))
    replaceSlots(y, datacols = datacols, check = FALSE)
})

#' @importFrom stats setNames
.pasteTwoDuckDBTables <- function(x, y, sep = " ") {
    if (!isTRUE(all.equal(x, y)) || ((ncol(x) > 1L) && (ncol(y) > 1L) && (ncol(x) != ncol(y)))) {
        stop("can only perform operations with compatible objects")
    }
    comb <- cbind(x, y)
    fin1 <- head(comb@datacols, ncol(x))
    fin2 <- tail(comb@datacols, ncol(y))
    fout <- if (ncol(x) >= ncol(y)) colnames(x) else colnames(y)
    datacols <- setNames(as.expression(Map(function(a, b) call("concat_ws", sep, a, b), fin1, fin2)), fout)
    replaceSlots(comb, datacols = datacols, check = FALSE)
}

#' @export
setMethod("paste", "DuckDBTable", function(..., sep = " ", collapse = NULL) {
    if (!is.null(collapse)) {
        stop("'collapse' is not supported for DuckDBTable")
    }
    args <- list(...)
    ans <- args[[1L]]
    if (length(args) > 1L) {
        for (i in 2:length(args)) {
            if (is(args[[i]], "DuckDBTable")) {
                ans <- .pasteTwoDuckDBTables(ans, args[[i]], sep = sep)
            } else if (is.atomic(args[[i]])) {
                if (length(args[[i]]) != 1L) {
                    stop("can only perform operations with scalar values")
                }
                datacols <- setNames(as.expression(Map(function(col) call("concat_ws", sep, col, args[[i]]), ans@datacols)), colnames(ans))
                ans <- replaceSlots(ans, datacols = datacols, check = FALSE)
            } else {
                stop("all arguments must be DuckDBTable objects or scalar values")
            }
        }
    }
    ans
})

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Set methods
###

#' @export
#' @importFrom dplyr distinct mutate row_number
setMethod("unique", "DuckDBTable",
function (x, incomparables = FALSE, fromLast = FALSE, ...)  {
    if (!isFALSE(incomparables)) {
        .NotYetUsed("incomparables != FALSE")
    }
    conn <- tblconn(x, select = FALSE, filter = FALSE)
    datacols <- x@datacols
    keycols <- tail(make.unique(c(colnames(conn), "row_number"), sep = "_"), 1L)
    keycols <- setNames(list(call("row_number")), keycols)
    conn <- distinct(conn, !!!as.list(datacols))
    conn <- mutate(conn, !!!keycols)
    keycols[[1L]] <- set_row_number(conn)
    replaceSlots(x, conn = conn, keycols = keycols, check = FALSE)
})

#' @export
setMethod("%in%", c(x = "DuckDBTable", table = "ANY"), function(x, table) {
    # Match base R: the result is never NA, NA matches only an NA in the table,
    # and NaN matches only a NaN. A plain SQL IN returns NULL for a missing
    # value and for a table that contains NULL.
    table <- unique(as.vector(table))
    is_nan <- if (is.double(table)) is.nan(table) else logical(length(table))
    has_na <- any(is.na(table) & !is_nan)
    has_nan <- any(is_nan)
    table <- table[!is.na(table)]
    # only a floating point column can hold a NaN; see the is.nan() method
    types <- coltypes(x)
    FUN <- function(j, can_nan) {
        expr <- call("coalesce", call("%in%", j, table), FALSE)
        if (has_na) {
            expr <- call("|", call("is.na", j), expr)
        }
        if (has_nan && can_nan) {
            expr <- call("|", call("coalesce", call("is.nan", j), FALSE), expr)
        }
        expr
    }
    datacols <- x@datacols
    datacols <- as.expression(setNames(
        lapply(names(datacols), function(nm)
               FUN(datacols[[nm]], identical(types[[nm]], "double"))),
        names(datacols)))
    replaceSlots(x, datacols = datacols, check = FALSE)
})

#' @export
#' @importFrom dplyr group_by n summarize
#' @importFrom stats setNames
setMethod("table", "DuckDBTable", function(x, ...) {
    if (...length() != 0L) {
        stop("\"table\" method for DuckDB data can only take one input object")
    }
    conn <- tblconn(x, select = FALSE)
    groups <- as.list(x@datacols)
    counts <- as.data.frame(summarize(group_by(conn, !!!groups), count = n(), .groups = "drop"))
    counts[seq_along(groups)] <- lapply(counts[seq_along(groups)], function(j) {
        ifelse(is.na(j), "<NA>", as.character(j))
    })
    dnames <- lapply(counts[seq_along(groups)], function(j) as.character(sort(unique(j))))
    ans <- array(0L, dim = lengths(dnames, use.names = FALSE), dimnames = dnames)
    ans[do.call(cbind, counts[seq_along(groups)])] <- as.integer(counts[["count"]])
    class(ans) <- "table"
    ans
})

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### List methods
###

#' @export
#' @importFrom S4Vectors elementNROWS
setMethod("elementNROWS", "DuckDBTable", function(x) {
    sql_call(sql_call(x, "len"), "as.integer")
})

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Sparsity methods
###

#' @importFrom bit64 as.integer64
.zeros <- list("logical" = FALSE,
               "integer" = 0L,
               "integer64" = as.integer64(0L),
               "double" = 0,
               "character" = "",
               "raw" = "")

#' @export
#' @importFrom SparseArray is_nonzero
setMethod("is_nonzero", "DuckDBTable", function(x) {
    datacols <- x@datacols
    ctypes <- coltypes(x)
    for (j in names(ctypes)) {
        datacols[[j]] <- switch(ctypes[j],
                                logical = datacols[[j]],
                                integer =,
                                integer64 =,
                                double =,
                                character =,
                                raw = call("!=", datacols[[j]], .zeros[[ctypes[j]]]),
                                TRUE)
    }
    replaceSlots(x, datacols = datacols, check = FALSE)
})

#' @export
#' @importFrom SparseArray nzcount
#' @importFrom stats setNames
setMethod("nzcount", "DuckDBTable", function(x) {
    tbl <- is_nonzero(x)
    coltypes(tbl) <- rep.int("integer", ncol(tbl))
    datacols <- setNames(as.expression(Reduce(function(x, y) call("+", x, y), tbl@datacols)), "nonzero")
    tbl <- replaceSlots(tbl, datacols = datacols, check = FALSE)
    cnt <- sum(tbl)
    if (is.na(cnt)) {
        cnt <- 0L
    }
    cnt
})

#' @export
#' @importFrom S4Arrays is_sparse
setMethod("is_sparse", "DuckDBTable", function(x) {
    TRUE
})
