#' DuckDBTable row / column summarization methods
#'
#' @description
#' Row / column summarization methods for \linkS4class{DuckDBTable} objects.
#'
#' @section Row / Column Summarization Methods:
#' In the code snippets below, \code{x} is a DuckDBTable object:
#' \describe{
#'   \item{\code{rowCounts(x, value = TRUE)}:}{
#'     Calculates the row counts of \code{x} that are equal to \code{value}.
#'     \describe{
#'       \item{\code{value}}{The value to count.}
#'     }
#'   }
#'   \item{\code{colCounts(x, value = TRUE)}:}{
#'     Calculates the column counts of \code{x} that are equal to \code{value}.
#'     \describe{
#'       \item{\code{value}}{The value to count.}
#'     }
#'   }
#'   \item{\code{rowMaxs(x)}:}{
#'     Calculates the row maxima of \code{x}.
#'   }
#'   \item{\code{colMaxs(x)}:}{
#'     Calculates the column maxima of \code{x}.
#'   }
#'   \item{\code{rowMeans(x, dims = 1)}:}{
#'     Calculates the row means of \code{x}.
#'     \describe{
#'       \item{\code{dims}}{An integer specifying which dimensions to average over,
#'         namely \code{dims + 1}, \ldots.}
#'     }
#'   }
#'   \item{\code{colMeans(x, dims = 1)}:}{
#'     Calculates the column means of \code{x}.
#'     \describe{
#'       \item{\code{dims}}{An integer specifying which dimensions to average over,
#'         namely \code{1:dims}.}
#'     }
#'   }
#'   \item{\code{rowMins(x)}:}{
#'     Calculates the row minima of \code{x}.
#'   }
#'   \item{\code{colMins(x)}:}{
#'     Calculates the column minima of \code{x}.
#'   }
#'   \item{\code{rowSums(x, dims = 1)}:}{
#'     Calculates the row sums of \code{x}.
#'     \describe{
#'       \item{\code{dims}}{An integer specifying which dimensions to sum over,
#'         namely \code{dims + 1}, \ldots.}
#'     }
#'   }
#'   \item{\code{colSums(x, dims = 1)}:}{
#'     Calculates the column sums of \code{x}.
#'     \describe{
#'       \item{\code{dims}}{An integer specifying which dimensions to sum over,
#'         namely \code{1:dims}.}
#'     }
#'   }
#'   \item{\code{rowSds(x)}:}{
#'     Calculates the row standard deviations of \code{x}.
#'   }
#'   \item{\code{colSds(x)}:}{
#'     Calculates the column standard deviations of \code{x}.
#'   }
#'   \item{\code{rowVars(x)}:}{
#'     Calculates the row variances of \code{x}.
#'   }
#'   \item{\code{colVars(x)}:}{
#'     Calculates the column variances of \code{x}.
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
#' rowCounts,DuckDBTable-method
#' colCounts,DuckDBTable-method
#' rowMaxs,DuckDBTable-method
#' colMaxs,DuckDBTable-method
#' rowMeans,DuckDBTable-method
#' colMeans,DuckDBTable-method
#' rowMins,DuckDBTable-method
#' colMins,DuckDBTable-method
#' rowSums,DuckDBTable-method
#' colSums,DuckDBTable-method
#' rowSds,DuckDBTable-method
#' colSds,DuckDBTable-method
#' rowVars,DuckDBTable-method
#' colVars,DuckDBTable-method
#'
#' @include DuckDBTable-class.R
#' @include DuckDBTable-utils.R
#' @include sql_call.R
#'
#' @keywords utilities methods
#'
#' @name DuckDBTable-matrixStats
NULL

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### matrixStats methods
###

#' @importFrom S4Vectors isSingleNumber
.marginSetup <- function(x, dims = 1, margin = c("row", "col")) {
    margin <- match.arg(margin)
    nk <- nkey(x)
    if (nk < 2L) {
        stop("'x' must be an array of at least two dimensions")
    }
    if (!isSingleNumber(dims) || dims < 1L || dims >= nk) {
        stop("invalid 'dims'")
    }
    if (length(x@datacols) != 1L) {
        stop("requires a single datacols")
    }
    if (margin == "row") {
        keycols <- head(x@keycols, dims)
        along <- tail(x@keycols, -dims)
    } else {
        keycols <- tail(x@keycols, -dims)
        along <- head(x@keycols, dims)
    }
    k <- prod(lengths(along, use.names = FALSE))
    along <- lapply(names(along), as.name)
    groups <- lapply(names(keycols), as.name)
    list(keycols = keycols, groups = groups, along = along, k = k)
}

#' @importFrom dplyr group_by n_distinct summarize
#' @importFrom S4Vectors new2
.marginCounts <-
function(x, value = TRUE, dims = 1, fill = 0, margin = c("row", "col")) {
    lst <- .marginSetup(x, dims = dims, margin = margin)
    keycols <- lst$keycols; groups <- lst$groups; along <- lst$along; k <- lst$k
    datacols <- x@datacols
    if (value != fill) {
        aggr <- sapply(datacols, function(y) call("countif", call("==", call("(", y), value)),
                       simplify = FALSE)
    } else {
        aggr <- sapply(datacols, function(y)
                       call("+",
                            call("countif", call("==", call("(", y), value)),
                            call("(", call("-", k, as.call(c(list(as.name("n_distinct")), along))))),
                       simplify = FALSE)
    }
    conn <- summarize(group_by(tblconn(x, select = FALSE), !!!groups), !!!aggr)
    datacols <- as.expression(sapply(names(aggr), as.name, simplify = FALSE))
    new2("DuckDBTable", conn = conn, datacols = datacols, keycols = keycols, check = FALSE)
}

#' @export
#' @importFrom MatrixGenerics rowCounts
setMethod("rowCounts", "DuckDBTable",
function(x, value = TRUE, na.rm = FALSE, dims = 1, fill = 0, ..., useNames = TRUE) {
    .marginCounts(x, value = value, dims = dims, fill = fill, margin = "row")
})

#' @export
#' @importFrom MatrixGenerics colCounts
setMethod("colCounts", "DuckDBTable",
function(x, value = TRUE, na.rm = FALSE, dims = 1, fill = 0, ..., useNames = TRUE) {
    .marginCounts(x, value = value, dims = dims, fill = fill, margin = "col")
})

#' @importFrom dplyr group_by n_distinct summarize
#' @importFrom S4Vectors new2
.marginMaxs <- function(x, dims = 1, fill = 0, margin = c("row", "col")) {
    lst <- .marginSetup(x, dims = dims, margin = margin)
    keycols <- lst$keycols; groups <- lst$groups; along <- lst$along; k <- lst$k
    datacols <- x@datacols
    nfill <- call("(", call("-", k, as.call(c(list(as.name("n_distinct")), along))))
    aggr <- sapply(datacols, function(y) {
        stat <- call("max", y, na.rm = TRUE)
        call("if", call("==", nfill, 0L), stat, call("greatest", stat, fill))
    }, simplify = FALSE)
    conn <- summarize(group_by(tblconn(x, select = FALSE), !!!groups), !!!aggr)
    datacols <- as.expression(sapply(names(aggr), as.name, simplify = FALSE))
    new2("DuckDBTable", conn = conn, datacols = datacols, keycols = keycols, check = FALSE)
}

#' @export
#' @importFrom MatrixGenerics rowMaxs
setMethod("rowMaxs", "DuckDBTable",
function(x, na.rm = FALSE, dims = 1, fill = 0, ..., useNames = TRUE) {
    .marginMaxs(x, dims = dims, fill = fill, margin = "row")
})

#' @export
#' @importFrom MatrixGenerics colMaxs
setMethod("colMaxs", "DuckDBTable",
function(x, na.rm = FALSE, dims = 1, fill = 0, ..., useNames = TRUE) {
    .marginMaxs(x, dims = dims, fill = fill, margin = "col")
})

#' @importFrom dplyr group_by n_distinct summarize
#' @importFrom S4Vectors new2
.marginMeans <- function(x, dims = 1, fill = 0, margin = c("row", "col")) {
    lst <- .marginSetup(x, dims = dims, margin = margin)
    keycols <- lst$keycols; groups <- lst$groups; along <- lst$along; k <- lst$k
    datacols <- x@datacols
    if (fill == 0) {
        aggr <- sapply(datacols, function(y) call("/", call("sum", y, na.rm = TRUE), k),
                       simplify = FALSE)
    } else {
        aggr <- sapply(datacols, function(y)
                       call("/",
                            call("(",
                                 call("+",
                                      call("sum", y, na.rm = TRUE),
                                      call("*",
                                           fill,
                                           call("(", call("-", k, as.call(c(list(as.name("n_distinct")), along))))))),
                            k),
                       simplify = FALSE)
    }
    conn <- summarize(group_by(tblconn(x, select = FALSE), !!!groups), !!!aggr)
    datacols <- as.expression(sapply(names(aggr), as.name, simplify = FALSE))
    new2("DuckDBTable", conn = conn, datacols = datacols, keycols = keycols, check = FALSE)
}

#' @export
#' @importFrom MatrixGenerics rowMeans
setMethod("rowMeans", "DuckDBTable", function(x, na.rm = FALSE, dims = 1, fill = 0, ...) {
    .marginMeans(x, dims = dims, fill = fill, margin = "row")
})

#' @export
#' @importFrom MatrixGenerics colMeans
setMethod("colMeans", "DuckDBTable", function(x, na.rm = FALSE, dims = 1, fill = 0, ...) {
    .marginMeans(x, dims = dims, fill = fill, margin = "col")
})

#' @importFrom dplyr group_by n_distinct summarize
#' @importFrom S4Vectors new2
.marginMins <- function(x, dims = 1, fill = 0, margin = c("row", "col")) {
    lst <- .marginSetup(x, dims = dims, margin = margin)
    keycols <- lst$keycols; groups <- lst$groups; along <- lst$along; k <- lst$k
    datacols <- x@datacols
    nfill <- call("(", call("-", k, as.call(c(list(as.name("n_distinct")), along))))
    aggr <- sapply(datacols, function(y) {
        stat <- call("min", y, na.rm = TRUE)
        call("if", call("==", nfill, 0L), stat, call("least", stat, fill))
    }, simplify = FALSE)
    conn <- summarize(group_by(tblconn(x, select = FALSE), !!!groups), !!!aggr)
    datacols <- as.expression(sapply(names(aggr), as.name, simplify = FALSE))
    new2("DuckDBTable", conn = conn, datacols = datacols, keycols = keycols, check = FALSE)
}

#' @export
#' @importFrom MatrixGenerics rowMins
setMethod("rowMins", "DuckDBTable",
function(x, na.rm = FALSE, dims = 1, fill = 0, ..., useNames = TRUE) {
    .marginMins(x, dims = dims, fill = fill, margin = "row")
})

#' @export
#' @importFrom MatrixGenerics colMins
setMethod("colMins", "DuckDBTable",
function(x, na.rm = FALSE, dims = 1, fill = 0, ..., useNames = TRUE) {
    .marginMins(x, dims = dims, fill = fill, margin = "col")
})

#' @importFrom dplyr group_by n_distinct summarize
#' @importFrom S4Vectors new2
.marginSums <- function(x, dims = 1, fill = 0, margin = c("row", "col")) {
    lst <- .marginSetup(x, dims = dims, margin = margin)
    keycols <- lst$keycols; groups <- lst$groups; along <- lst$along; k <- lst$k
    datacols <- x@datacols
    if (fill == 0) {
        aggr <- sapply(datacols, function(y) call("sum", y, na.rm = TRUE),
                       simplify = FALSE)
    } else {
        aggr <- sapply(datacols, function(y)
                       call("+",
                            call("sum", y, na.rm = TRUE),
                            call("*",
                                 fill,
                                 call("(", call("-", k, as.call(c(list(as.name("n_distinct")), along)))))),
                       simplify = FALSE)
    }
    conn <- summarize(group_by(tblconn(x, select = FALSE), !!!groups), !!!aggr)
    datacols <- as.expression(sapply(names(aggr), as.name, simplify = FALSE))
    new2("DuckDBTable", conn = conn, datacols = datacols, keycols = keycols, check = FALSE)
}

#' @export
#' @importFrom MatrixGenerics rowSums
setMethod("rowSums", "DuckDBTable", function(x, na.rm = FALSE, dims = 1, fill = 0, ...) {
    .marginSums(x, dims = dims, fill = fill, margin = "row")
})

#' @export
#' @importFrom MatrixGenerics colSums
setMethod("colSums", "DuckDBTable", function(x, na.rm = FALSE, dims = 1, fill = 0, ...) {
    .marginSums(x, dims = dims, fill = fill, margin = "col")
})

#' @importFrom dplyr group_by left_join n_distinct summarize
#' @importFrom S4Vectors new2
.marginVars <- function(x, dims = 1, fill = 0, margin = c("row", "col")) {
    lst <- .marginSetup(x, dims = dims, margin = margin)
    keycols <- lst$keycols; groups <- lst$groups; along <- lst$along; k <- lst$k
    datacols <- x@datacols
    nfill <- call("(", call("-", k, as.call(c(list(as.name("n_distinct")), along))))

    # For fill == 0 (sparse matrices), use single-pass VAR_SAMP optimization
    # Formula: (VAR_SAMP(y) * (n-1) + sum_y² * (1/n - 1/k)) / (k-1)
    # This leverages DuckDB's numerically stable VAR_SAMP and reduces Parquet scans
    if (fill == 0) {
        conn <- tblconn(x, select = FALSE)
        aggr <- sapply(names(datacols), function(nm) {
            y <- datacols[[nm]]
            n <- as.call(c(list(as.name("n_distinct")), along))
            sum_y <- call("sum", y, na.rm = TRUE)
            var_samp <- call("var_samp", y)

            # (VAR_SAMP * (n-1) + sum_y² * (1/n - 1/k)) / (k-1)
            # COALESCE handles edge case where n=1 (VAR_SAMP returns NULL)
            var_samp_term <- call("*", call("coalesce", var_samp, 0),
                                  call("(", call("-", n, 1L)))
            sum_sq_term <- call("*", call("*", sum_y, sum_y),
                               call("(", call("-", call("/", 1, n), call("/", 1, k))))
            call("/", call("(", call("+", var_samp_term, sum_sq_term)), k - 1L)
        }, simplify = FALSE)

        conn <- summarize(group_by(conn, !!!groups), !!!aggr)
        datacols <- as.expression(sapply(names(aggr), as.name, simplify = FALSE))
        return(new2("DuckDBTable", conn = conn, datacols = datacols, keycols = keycols, check = FALSE))
    }

    # For fill != 0, use two-pass approach (original implementation)
    aggr <- sapply(datacols, function(y)
                   call("/",
                        call("(",
                             call("+",
                                  call("sum", y, na.rm = TRUE),
                                  call("*", fill, nfill))),
                        k),
                   simplify = FALSE)
    conn <- tblconn(x, select = FALSE)
    mean_names <- vapply(names(aggr), function(nm) {
        tail(make.unique(c(colnames(conn), paste0(nm, "_mean")), sep = "_"), 1L)
    }, character(1L))
    names(aggr) <- mean_names

    conn <- left_join(conn, summarize(group_by(conn, !!!groups), !!!aggr), by = names(keycols))

    aggr <- sapply(names(datacols), function(nm) {
        y <- datacols[[nm]]
        y_mean <- as.name(mean_names[[nm]])
        y_mean_agg <- call("any_value", y_mean)
        dev <- call("(", call("-", y, y_mean))
        sum_dev_sq <- call("sum", call("*", dev, dev), na.rm = TRUE)
        fill_dev <- call("(", call("-", fill, y_mean_agg))
        zero_contrib <- call("*", call("(", call("*", fill_dev, fill_dev)), nfill)
        call("/", call("(", call("+", sum_dev_sq, zero_contrib)), k - 1L)
    }, simplify = FALSE)

    conn <- summarize(group_by(conn, !!!groups), !!!aggr)
    datacols <- as.expression(sapply(names(aggr), as.name, simplify = FALSE))
    new2("DuckDBTable", conn = conn, datacols = datacols, keycols = keycols, check = FALSE)
}

.marginSds <- function(x, dims = 1, fill = 0, margin = c("row", "col")) {
    margin <- match.arg(margin)
    ans <- .marginVars(x, dims = dims, fill = fill, margin = margin)
    sql_call(ans, "sqrt")
}

#' @export
#' @importFrom MatrixGenerics rowSds
setMethod("rowSds", "DuckDBTable",
function(x, na.rm = FALSE, dims = 1, fill = 0, ..., useNames = TRUE) {
    .marginSds(x, dims = dims, fill = fill, margin = "row")
})

#' @export
#' @importFrom MatrixGenerics colSds
setMethod("colSds", "DuckDBTable",
function(x, na.rm = FALSE, dims = 1, fill = 0, ..., useNames = TRUE) {
    .marginSds(x, dims = dims, fill = fill, margin = "col")
})

#' @export
#' @importFrom MatrixGenerics rowVars
setMethod("rowVars", "DuckDBTable",
function(x, na.rm = FALSE, dims = 1, fill = 0, ..., useNames = TRUE) {
    .marginVars(x, dims = dims, fill = fill, margin = "row")
})

#' @export
#' @importFrom MatrixGenerics colVars
setMethod("colVars", "DuckDBTable",
function(x, na.rm = FALSE, dims = 1, fill = 0, ..., useNames = TRUE) {
    .marginVars(x, dims = dims, fill = fill, margin = "col")
})
