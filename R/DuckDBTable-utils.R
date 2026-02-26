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
#' @section Numerical Data Methods:
#' In the code snippets below, \code{x} is a DuckDBTable object:
#' \describe{
#'   \item{\code{is.finite(x)}:}{
#'     Returns a DuckDBTable containing logicals that indicate which values are
#'     finite.
#'   }
#'   \item{\code{is.infinite(x)}:}{
#'     Returns a DuckDBTable containing logicals that indicate which values are
#'     infinite.
#'   }
#'   \item{\code{is.nan(x)}:}{
#'     Returns a DuckDBTable containing logicals that indicate which values are
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
#'   \item{\code{sweep(x, MARGIN, STATS, FUN = "/")}:}{
#'     Sweeps out array summaries from \code{x}. Applies \code{FUN} to each
#'     element of \code{x} using the corresponding value from \code{STATS}
#'     based on \code{MARGIN}.
#'     \describe{
#'       \item{\code{MARGIN}}{integer specifying the dimension (1 for rows,
#'         2 for columns)}
#'       \item{\code{STATS}}{numeric vector with length equal to the extent
#'         of dimension \code{MARGIN}}
#'       \item{\code{FUN}}{function to be used to carry out the sweep}
#'     }
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
#' @section Spatial Methods:
#' In the code snippets below, \code{x} is a DuckDBTable object:
#' \describe{
#'   \item{\code{st_area(x)}:}{
#'     Returns a DuckDBTable containing the areas of geometries.
#'   }
#'   \item{\code{st_as_binary(x, hex = FALSE)}:}{
#'     Returns the DuckDBTable containing either WKB if \code{hex = FALSE} or
#'     HEXWKB if \code{hex = TRUE} representations of geometries.
#'   }
#'   \item{\code{st_as_sfc(x, ..., crs = NA_integer_, GeoJSON = FALSE, WKB = FALSE)}:}{
#'     Returns the DuckDBTable containing geometry types by parsing WKT
#'     (or GeoJSON if \code{GeoJSON = TRUE}, or WKB if \code{WKB = TRUE}).
#'   }
#'   \item{\code{st_as_text(x, geojson = FALSE)}:}{
#'     Returns the DuckDBTable containing either WKT if \code{geojson = FALSE} or
#'     GeoJSON if \code{geojson = TRUE} representations of geometries.
#'   }
#'   \item{\code{st_boundary(x)}:}{
#'     Returns a DuckDBTable containing the boundaries of geometries.
#'   }
#'   \item{\code{st_centroid(x)}:}{
#'     Returns a DuckDBTable containing the centroids of geometries.
#'   }
#'   \item{\code{st_convex_hull(x)}:}{
#'     Returns a DuckDBTable containing the convex hulls of geometries.
#'   }
#'   \item{\code{st_exterior_ring(x)}:}{
#'     Returns a DuckDBTable containing the exterior rings of geometries.
#'   }
#'   \item{\code{st_is_valid(x)}:}{
#'     Returns a DuckDBTable containing logicals that indicate if the
#'     geometries are valid.
#'   }
#'   \item{\code{st_line_merge(x, directed = FALSE)}:}{
#'     Returns a DuckDBTable containing the merged lines of geometries,
#'     optionally taking direction into account.
#'   }
#'   \item{\code{st_make_valid(x)}:}{
#'     Returns a DuckDBTable containing valid geometries.
#'   }
#'   \item{\code{st_normalize(x)}:}{
#'     Returns a DuckDBTable containing normalized geometries.
#'   }
#'   \item{\code{st_point_on_surface(x)}:}{
#'     Returns a DuckDBTable containing a point on the surface of the input
#'     geometry.
#'   }
#'   \item{\code{st_reverse(x)}:}{
#'     Returns a DuckDBTable containing geometries with the vertice order
#'     reversed.
#'   }
#' }
#'
#' @author Patrick Aboyoun
#'
#' @seealso
#' \itemize{
#'   \item \code{\link{DuckDBTable-class}} for the main class
#'   \item \code{\link[S4Vectors]{RectangularData}} for the base class
#' }
#'
#' @aliases
#' sql_call,DuckDBTable-method
#' sql_fun,DuckDBTable-method
#'
#' Ops,DuckDBTable,DuckDBTable-method
#' Ops,DuckDBTable,atomic-method
#' Ops,atomic,DuckDBTable-method
#' Ops,DuckDBTable,missing-method
#' !,DuckDBTable-method
#' Math,DuckDBTable-method
#' Summary,DuckDBTable-method
#'
#' is.finite,DuckDBTable-method
#' is.infinite,DuckDBTable-method
#' is.nan,DuckDBTable-method
#' mean,DuckDBTable-method
#' var,DuckDBTable,ANY-method
#' sd,DuckDBTable-method
#' median.DuckDBTable
#' quantile.DuckDBTable
#' mad,DuckDBTable-method
#' IQR,DuckDBTable-method
#' sweep,DuckDBTable-method
#'
#' unique,DuckDBTable-method
#' %in%,DuckDBTable,ANY-method
#' table,DuckDBTable-method
#'
#' elementNROWS,DuckDBTable-method
#'
#' is_nonzero,DuckDBTable-method
#' nzcount,DuckDBTable-method
#' is_sparse,DuckDBTable-method
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
#' @importFrom DBI dbGetQuery
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
        types_sql <- paste0("'", return_type, "'", collapse = ", ")
        predicate <- c(predicate, sprintf("return_type IN (%s)", types_sql))
    }

    if (length(function_type) > 0L) {
        allowed_ftypes <- c("scalar", "aggregate", "macro", "table", "pragma", "table_macro")
        ftypes <- match.arg(function_type, allowed_ftypes, several.ok = TRUE)
        ftypes_sql <- paste0("'", ftypes, "'", collapse = ", ")
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

#' @export
setMethod("Summary", "DuckDBTable", function(x, ..., na.rm = FALSE) {
    if (.Generic == "range") {
        if (length(x@datacols) != 1L) {
            stop("aggregation requires a single datacols")
        }
        aggr <- list(min = call("min", x@datacols[[1L]], na.rm = TRUE),
                     max = call("max", x@datacols[[1L]], na.rm = TRUE))
        unlist(as.data.frame(summarize(tblconn(x, select = FALSE), !!!aggr)),
               use.names = FALSE)
    } else if (.Generic == "sum") {
        .pull.aggregagte(x, "fsum")
    } else {
        .pull.aggregagte(x, .Generic, na.rm = TRUE)
    }
})

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Numerical methods
###

#' @export
setMethod("is.finite", "DuckDBTable", function(x) {
    sql_call(x, "isfinite")
})

#' @export
setMethod("is.infinite", "DuckDBTable", function(x) {
    sql_call(x, "isinf")
})

#' @export
setMethod("is.nan", "DuckDBTable", function(x) {
    sql_call(x, "isnan")
})

#' @export
setMethod("mean", "DuckDBTable", function(x, ...) {
    .pull.aggregagte(x, "mean", na.rm = TRUE)
})

#' @export
setMethod("var", "DuckDBTable", function(x, y = NULL, na.rm = FALSE, use)  {
    if (!is.null(y)) {
        stop("covariance is not supported")
    }
    .pull.aggregagte(x, "var", na.rm = TRUE)
})

#' @export
setMethod("sd", "DuckDBTable", function(x, na.rm = FALSE) {
    .pull.aggregagte(x, "sd", na.rm = TRUE)
})

#' @exportS3Method stats::median
#' @importFrom stats median
median.DuckDBTable <- function(x, na.rm = FALSE, ...) {
    .pull.aggregagte(x, "median", na.rm = TRUE)
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

#' @export
#' @importFrom DelayedArray sweep
#' @importFrom dplyr left_join
#' @importFrom S4Vectors endoapply isSingleNumber
#' @importFrom stats setNames
setMethod("sweep", "DuckDBTable",
function(x, MARGIN, STATS, FUN = "/", check.margin = TRUE, ...) {
    nk <- nkey(x)
    if (nk < 2L) {
        stop("'x' must be an array of at least two dimensions")
    }
    if (!isSingleNumber(MARGIN) || MARGIN < 1L || MARGIN > nk) {
        stop("'MARGIN' must be between 1 and ", nk)
    }
    if (length(x@datacols) != 1L) {
        stop("sweep requires a single datacols")
    }

    levels <- x@keycols[[MARGIN]]
    if (length(STATS) != length(levels)) {
        stop("length of 'STATS' (", length(STATS), ") must equal the extent ",
             "of dimension ", MARGIN, " (", length(levels), ")")
    }

    key <- names(x@keycols)[MARGIN]
    conn <- tblconn(x, select = FALSE)
    stats <- tail(make.unique(c(colnames(conn), "__sweep_stats__"), sep = "_"), 1L)
    df <- setNames(data.frame(levels, STATS), c(key, stats))

    conn <- left_join(conn, df, by = key, copy = TRUE)

    datacols <- endoapply(x@datacols, function(y) call(FUN, call("(", y), as.name(stats)))
    replaceSlots(x, conn = conn, datacols = datacols, check = FALSE)
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
    keycols[[1L]] <- .set_row_number(conn)
    replaceSlots(x, conn = conn, keycols = keycols, check = FALSE)
})

#' @export
setMethod("%in%", c(x = "DuckDBTable", table = "ANY"), function(x, table) {
    sql_call(x, "%in%", table)
})

#' @export
#' @importFrom dplyr group_by n summarize
#' @importFrom stats setNames
setMethod("table", "DuckDBTable", function(...) {
    args <- list(...)
    if (length(args) != 1L) {
        stop("\"table\" method for DuckDB data can only take one input object")
    }
    x <- args[[1L]]
    conn <- tblconn(x, select = FALSE)
    groups <- as.list(x@datacols)
    counts <- as.data.frame(summarize(group_by(conn, !!!groups), count = n(), .groups = "drop"))
    dnames <- lapply(counts[seq_along(groups)], function(j) as.character(sort(unique(j))))
    ans <- array(0L, dim = lengths(dnames, use.names = FALSE), dimnames = dnames)
    ans[do.call(cbind, lapply(counts[seq_along(groups)], as.character))] <- as.integer(counts[["count"]])
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
