#' DuckDBColumn objects
#'
#' @description
#' The DuckDBColumn class extends \linkS4class{Vector} to represent a column
#' extracted from a \linkS4class{DuckDBDataFrame} object.
#'
#' @section Accessors:
#' In the code snippets below, \code{x} is a DuckDBColumn object:
#' \describe{
#'   \item{\code{length(x)}:}{
#'     Get the number of elements in \code{x}.
#'   }
#'   \item{\code{names(x)}:}{
#'     Get the names of the elements of \code{x}.
#'   }
#'   \item{\code{dimtbls(x, drop = TRUE)}, \code{dimtbls(x) <- value}:}{
#'     Get or set the list of dimension tables used to define partitions for
#'     efficient queries. If \code{drop = TRUE}, then it returns a named
#'     \code{DataFrameList} object, else it returns an environment containing
#'     a \code{dimtbls} named \code{DataFrameList} element.
#'   }
#'   \item{\code{type(x)}, \code{type(x) <- value}:}{
#'     Get or set the data type of the elements; one of \code{"logical"},
#'     \code{"integer"}, \code{"integer64"}, \code{"double"}, or
#'     \code{"character"}.
#'   }
#' }
#'
#' @section Coercion:
#' \describe{
#'   \item{\code{as.vector(x)}:}{
#'     Coerces \code{x} to a vector.
#'   }
#'   \item{\code{realize(x, BACKEND = getAutoRealizationBackend())}:}{
#'     Realize an object into memory or on disk using the equivalent of
#'     \code{realize(as.vector(x), BACKEND)}.
#'   }
#' }
#'
#' @section Subsetting:
#' In the code snippets below, \code{x} is a DuckDBColumn object:
#' \describe{
#'   \item{\code{x[i]}:}{
#'     Returns a DuckDBColumn object containing the selected elements.
#'   }
#'   \item{\code{head(x, n = 6L)}:}{
#'     If \code{n} is non-negative, returns the first n elements of \code{x}.
#'     If \code{n} is negative, returns all but the last \code{abs(n)} elements
#'     of \code{x}.
#'   }
#'   \item{\code{tail(x, n = 6L)}:}{
#'     If \code{n} is non-negative, returns the last n elements of \code{x}.
#'     If \code{n} is negative, returns all but the first \code{abs(n)} elements
#'     of \code{x}.
#'   }
#' }
#'
#' @return
#' Objects of class \code{DuckDBColumn} extend \link[S4Vectors]{Vector}.
#'
#' @author Patrick Aboyoun
#'
#' @aliases DuckDBColumn-class
#'
#' @aliases dbconn,DuckDBColumn-method
#' @aliases tblconn,DuckDBColumn-method
#' @aliases .keycols,DuckDBColumn-method
#' @aliases .has_row_number,DuckDBColumn-method
#' @aliases dimtbls,DuckDBColumn-method
#' @aliases dimtbls<-,DuckDBColumn-method
#' @aliases length,DuckDBColumn-method
#' @aliases names,DuckDBColumn-method
#' @aliases names<-,DuckDBColumn-method
#' @aliases type,DuckDBColumn-method
#' @aliases type<-,DuckDBColumn-method
#'
#' @aliases extractROWS,DuckDBColumn,ANY-method
#' @aliases head,DuckDBColumn-method
#' @aliases tail,DuckDBColumn-method
#'
#' @aliases as.vector,DuckDBColumn-method
#' @aliases realize,DuckDBColumn-method
#'
#' @aliases show,DuckDBColumn-method
#' @aliases showAsCell,DuckDBColumn-method
#'
#' @seealso
#' \itemize{
#'   \item \code{\link{DuckDBColumn-utils}} for the utilities
#'   \item \code{\link[S4Vectors]{Vector}} for the base class
#' }
#'
#' @examples
#' tf <- tempfile(fileext = ".parquet")
#' on.exit(unlink(tf))
#' arrow::write_parquet(cbind(model = rownames(mtcars), mtcars), tf)
#' df <- DuckDBDataFrame(tf, datacols = colnames(mtcars), keycol = "model")
#' cyl <- df[["cyl"]]
#' cyl
#' length(cyl)
#' mean(cyl)
#' head(cyl, 3)
#'
#' @include DuckDBTable-class.R
#'
#' @keywords classes methods
#'
#' @name DuckDBColumn-class
NULL

#' @export
#' @importClassesFrom S4Vectors Vector
setClass("DuckDBColumn", contains = "Vector", slots = c(table = "DuckDBTable"))

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Accessors
###

#' @export
setMethod("dbconn", "DuckDBColumn", function(x) callGeneric(x@table))

#' @export
setMethod("tblconn", "DuckDBColumn", function(x, select = TRUE, filter = TRUE) {
    callGeneric(x@table, select = select, filter = filter)
})

#' @export
setMethod(".keycols", "DuckDBColumn", function(x) callGeneric(x@table))

#' @export
setMethod(".has_row_number", "DuckDBColumn", function(x) callGeneric(x@table))

#' @export
setMethod("dimtbls", "DuckDBColumn", function(x, drop = TRUE) {
    callGeneric(x@table, drop = drop)
})

#' @export
setReplaceMethod("dimtbls", "DuckDBColumn", function(x, value) callGeneric(x@table, value))

#' @export
setMethod("length", "DuckDBColumn", function(x) nrow(x@table))

#' @export
setMethod("names", "DuckDBColumn", function(x) {
    table <- x@table
    if (length(table@conn) == 0L) {
        NULL
    } else {
        keydimnames(table)[[1L]]
    }
})

#' @export
setReplaceMethod("names", "DuckDBColumn", function(x, value) {
    if (.has_row_number(x)) {
        stop("cannot replace row numbers with rownames")
    }
    keydimnames(x@table) <- list(value)
    x
})

#' @export
setMethod("type", "DuckDBColumn", function(x) unname(coltypes(x@table)))

#' @export
setReplaceMethod("type", "DuckDBColumn", function(x, value) {
    table <- x@table
    coltypes(table) <- value
    replaceSlots(x, table = table, check = FALSE)
})

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Validity
###

#' @importFrom S4Vectors isTRUEorFALSE setValidity2
setValidity2("DuckDBColumn", function(x) {
    msg <- NULL
    table <- x@table
    if (length(table@conn) > 0L) {
        if (ncol(table) != 1L) {
            msg <- c(msg, "'table' slot must be a single-column DuckDBTable")
        }
        if (nkey(table) > 1L) {
            msg <- c(msg, "'table' slot must have a 'keycols' slot with at most one element")
        }
    }
    msg %||% TRUE
})

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Subsetting
###

#' @export
setMethod("extractROWS", "DuckDBColumn", function(x, i) {
    if (missing(i)) {
        return(x)
    }
    if (is(i, "DuckDBColumn")) {
        i <- i@table
    }
    i <- setNames(list(i), names(x@table@keycols))
    replaceSlots(x, table = .subset_DuckDBTable(x@table, i = i), check = FALSE)
})

#' @export
#' @importFrom S4Vectors head isSingleNumber
setMethod("head", "DuckDBColumn", function(x, n = 6L, ...) {
    if (!isSingleNumber(n)) {
        stop("'n' must be a single number")
    }
    if (.has_row_number(x)) {
        return(replaceSlots(x, table = .head_conn(x@table, n), check = FALSE))
    }
    n <- as.integer(n)
    len <- length(x)
    if (n < 0) {
        n <- max(0L, len + n)
    }
    if (n > len) {
        x
    } else {
        extractROWS(x, seq_len(n))
    }
})

#' @export
#' @importFrom S4Vectors isSingleNumber tail
setMethod("tail", "DuckDBColumn", function(x, n = 6L, ...) {
    if (!isSingleNumber(n)) {
        stop("'n' must be a single number")
    }
    if ((n > 0L) && .has_row_number(x)) {
        stop("tail requires a keycols to be efficient")
    }
    n <- as.integer(n)
    len <- length(x)
    if (n < 0) {
        n <- max(0L, len + n)
    }
    if (n > len) {
        x
    } else {
        extractROWS(x, (len + 1L) - rev(seq_len(n)))
    }
})

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Coercion
###

#' @export
#' @importFrom stats setNames
setMethod("as.vector", "DuckDBColumn", function(x, mode = "any") {
    df <- as.data.frame(x@table, optional = TRUE)

    # Columns are ordered: datacol (column 1), then keycol (column 2)
    names <- .map_keycol_names(x@table@keycols[[1L]], df[[2L]])
    vec <- setNames(df[[1L]], names)
    if (!.has_row_number(x@table)) {
        vec <- .reindexByStoredKeys(vec, rownames(x@table))
    }

    # Restore a factor column recorded in the schema (no-op when none). factor()
    # drops names, so re-attach them.
    entry <- x@table@collevels[[names(x@table@datacols)[1L]]]
    if (!is.null(entry) && is.character(vec)) {
        vec <- setNames(factor(vec, levels = entry[["levels"]],
                               ordered = entry[["ordered"]]), names(vec))
    }

    if (mode != "any") {
        storage.mode(vec) <- mode
    }
    vec
})

#' @export
#' @importFrom DelayedArray getAutoRealizationBackend realize
setMethod("realize", "DuckDBColumn",
function(x, BACKEND = getAutoRealizationBackend()) {
    x <- as.vector(x)
    if (!is.null(BACKEND)) {
        x <- callGeneric(x, BACKEND = BACKEND)
    }
    x
})

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Display
###

#' @export
#' @importFrom S4Vectors classNameForDisplay
setMethod("show", "DuckDBColumn", function(object) {
    len <- length(object)
    cat(sprintf("%s of length %s\n", classNameForDisplay(object), len))
    if (length(object@table@conn) == 0L) {
        return(invisible(NULL))
    }
    if (.has_row_number(object)) {
        n1 <- 5L
        n2 <- 0L
    } else {
        n1 <- 3L
        n2 <- 2L
    }
    if (len <= n1 + n2 + 1L) {
        vec <- as.vector(object)
    } else {
        if (n2 == 0L) {
            vec <- as.vector(head(object, n1))
            if (is.character(vec)) {
                vec <- setNames(sprintf("\"%s\"", vec), names(vec))
            }
            vec <- format(vec, justify = "right")
            vec <- c(vec, "..." = "...")
        } else {
            i <- c(seq_len(n1), (len + 1L) - rev(seq_len(n2)))
            vec <- as.vector(object[i])
            if (is.character(vec)) {
                vec <- setNames(sprintf("\"%s\"", vec), names(vec))
            }
            vec <- format(vec, justify = "right")
            vec <- c(head(vec, n1), "..." = "...", tail(vec, n2))
        }
    }
    print(vec, quote = FALSE)
    invisible(NULL)
})

#' @export
#' @importFrom S4Vectors showAsCell
setMethod("showAsCell", "DuckDBColumn", function(object) {
    callGeneric(as.vector(object))
})
