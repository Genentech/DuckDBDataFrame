#' DuckDBAtomicList objects
#'
#' @description
#' The DuckDBAtomicList class extends \linkS4class{AtomicList} and
#' \linkS4class{DuckDBColumn} to represent list columns extracted from a
#' \linkS4class{DuckDBDataFrame} object.
#'
#' @section Accessors:
#' In the code snippets below, \code{x} is a DuckDBAtomicList object:
#' \describe{
#'   \item{\code{length(x)}:}{
#'     Get the number of list elements in \code{x}.
#'   }
#'   \item{\code{names(x)}:}{
#'     Get the names of the list elements of \code{x}.
#'   }
#'   \item{\code{elementNROWS(x)}:}{
#'     Get the length of each list element in \code{x}.
#'   }
#'   \item{\code{elementType(x)}:}{
#'     Get the type of the list elements; one of \code{"logical"},
#'     \code{"integer"}, \code{"integer64"}, \code{"numeric"},
#'     \code{"character"}, or \code{"factor"}.
#'   }
#'   \item{\code{dimtbls(x, drop = TRUE)}, \code{dimtbls(x) <- value}:}{
#'     Get or set the list of dimension tables used to define partitions for
#'     efficient queries. If \code{drop = TRUE}, then it returns a named
#'     \code{DataFrameList} object, else it returns an environment containing
#'     a \code{dimtbls} named \code{DataFrameList} element.
#'   }
#' }
#'
#' @section Coercion:
#' \describe{
#'   \item{\code{as.list(x)}:}{
#'     Coerces \code{x} to a list.
#'   }
#'   \item{\code{realize(x, BACKEND = getAutoRealizationBackend())}:}{
#'     Realize an object into memory or on disk using the equivalent of
#'     \code{realize(as.list(x), BACKEND)}.
#'   }
#' }
#'
#' @section Subsetting:
#' In the code snippets below, \code{x} is a DuckDBAtomicList object:
#' \describe{
#'   \item{\code{x[i]}:}{
#'     Returns a DuckDBAtomicList object containing the selected list elements.
#'   }
#'   \item{\code{x[[i]]}:}{
#'     Extracts the list element at position \code{i} as an atomic vector.
#'   }
#'   \item{\code{head(x, n = 6L)}:}{
#'     If \code{n} is non-negative, returns the first n list elements of \code{x}.
#'     If \code{n} is negative, returns all but the last \code{abs(n)} list
#'     elements of \code{x}.
#'   }
#'   \item{\code{tail(x, n = 6L)}:}{
#'     If \code{n} is non-negative, returns the last n list elements of \code{x}.
#'     If \code{n} is negative, returns all but the first \code{abs(n)} list
#'     elements of \code{x}.
#'   }
#' }
#'
#' @return
#' Objects of class \code{DuckDBAtomicList} extend \link[IRanges]{AtomicList}.
#'
#' @author Patrick Aboyoun
#'
#' @aliases DuckDBAtomicList-class
#' @aliases DuckDBLogicalList-class
#' @aliases DuckDBIntegerList-class
#' @aliases DuckDBInteger64List-class
#' @aliases DuckDBNumericList-class
#' @aliases DuckDBCharacterList-class
#' @aliases DuckDBFactorList-class
#'
#' @aliases elementNROWS,DuckDBAtomicList-method
#'
#' @aliases extractROWS,DuckDBAtomicList,ANY-method
#' @aliases getListElement,DuckDBAtomicList-method
#' @aliases head,DuckDBAtomicList-method
#' @aliases tail,DuckDBAtomicList-method
#'
#' @aliases as.list,DuckDBAtomicList-method
#' @aliases realize,DuckDBAtomicList-method
#'
#' @aliases show,DuckDBAtomicList-method
#' @aliases showAsCell,DuckDBAtomicList-method
#'
#' @seealso
#' \itemize{
#'   \item \code{\link{DuckDBColumn-class}} for atomic columns
#'   \item \code{\link[IRanges]{AtomicList}} for the base class
#'   \item \code{\link[S4Vectors]{List}} for the List class hierarchy
#' }
#'
#' @examples
#' tf <- tempfile(fileext = ".parquet")
#' on.exit(unlink(tf))
#' df <- data.frame(
#'     id = sprintf("gene%02d", 1:5),
#'     int_list = I(lapply(1:5, function(i) seq_len(i)))
#' )
#' arrow::write_parquet(df, tf)
#' ddf <- DuckDBDataFrame(tf, keycol = "id")
#' lst <- ddf[["int_list"]]
#' lst
#' elementNROWS(lst)
#'
#' @include DuckDBColumn-class.R
#' @include DuckDBTable-class.R
#' @include DuckDBTable-utils.R
#'
#' @keywords classes methods
#'
#' @name DuckDBAtomicList-class
NULL

#' @export
#' @importClassesFrom IRanges AtomicList LogicalList IntegerList NumericList CharacterList FactorList
#' @importClassesFrom S4Vectors List
setClass("DuckDBAtomicList",
         contains = c("AtomicList", "DuckDBColumn", "VIRTUAL"))

#' @export
setClass("DuckDBLogicalList",
         prototype = prototype(elementType = "logical"),
         contains = c("LogicalList", "DuckDBAtomicList"))

#' @export
setClass("DuckDBIntegerList",
         prototype = prototype(elementType = "integer"),
         contains = c("IntegerList", "DuckDBAtomicList"))

#' @export
setClass("DuckDBInteger64List",
         prototype = prototype(elementType = "integer64"),
         contains = c("IntegerList", "DuckDBAtomicList"))

#' @export
setClass("DuckDBNumericList",
         prototype = prototype(elementType = "numeric"),
         contains = c("NumericList", "DuckDBAtomicList"))

#' @export
setClass("DuckDBCharacterList",
         prototype = prototype(elementType = "character"),
         contains = c("CharacterList", "DuckDBAtomicList"))

#' @export
setClass("DuckDBFactorList",
         prototype = prototype(elementType = "factor"),
         contains = c("FactorList", "DuckDBAtomicList"))

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Accessors
###

# dbconn method inherited from DuckDBColumn
# tblconn method inherited from DuckDBColumn
# .keycols method inherited from DuckDBColumn
# .has_row_number method inherited from DuckDBColumn
# dimtbls method inherited from DuckDBColumn
# dimtbls<- method inherited from DuckDBColumn
# length method inherited from DuckDBColumn
# names method inherited from DuckDBColumn
# names<- method inherited from DuckDBColumn

#' @export
#' @importFrom S4Vectors elementNROWS new2
#' @importFrom stats setNames
setMethod("elementNROWS", "DuckDBAtomicList", function(x) {
    y <- new2("DuckDBColumn", table = elementNROWS(x@table), check = FALSE)
    setNames(as.vector(y), names(x))
})

# elementType method inherited from List

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Validity
###

#' @importFrom S4Vectors setValidity2
setValidity2("DuckDBAtomicList", function(x) {
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
### Internal constructor (called by DuckDBDataFrame column extraction)
###

#' @importFrom S4Vectors new2
.new_DuckDBAtomicList <- function(table, type, metadata = list()) {
    if (!grepl("^list<.*>$", type)) {
        stop("expected LIST type string like 'list<integer>', got: ", type)
    }

    duckdbType <- .duckdb_element_type(type)
    elementType <- .duckdb_type_to_r(duckdbType)
    Class <- switch(elementType,
        "logical" = "DuckDBLogicalList",
        "integer" = "DuckDBIntegerList",
        "integer64" = "DuckDBInteger64List",
        "double" = "DuckDBNumericList",
        "character" = "DuckDBCharacterList",
        "factor" = "DuckDBFactorList",
        stop("unsupported LIST element type: ", duckdbType))

    new2(Class, table = table, elementType = elementType, metadata = metadata,
         check = FALSE)
}

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Subsetting
###

#' @export
setMethod("extractROWS", "DuckDBAtomicList", function(x, i) {
    if (missing(i)) {
        return(x)
    }
    if (is(i, "DuckDBColumn")) {
        i <- i@table
    }
    i <- setNames(list(i), names(x@table@keycols))
    table <- .subset_DuckDBTable(x@table, i = i)
    replaceSlots(x, table = table, check = FALSE)
})

# head method inherited from DuckDBColumn
# tail method inherited from DuckDBColumn

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Element access
###

#' @export
#' @importFrom S4Vectors getListElement normalizeDoubleBracketSubscript
setMethod("getListElement", "DuckDBAtomicList", function(x, i, exact = TRUE) {
    i <- normalizeDoubleBracketSubscript(i, x, exact = exact, allow.nomatch = TRUE)
    if (is.na(i)) {
        return(NULL)
    }

    # Extract single row using DuckDBTable infrastructure
    row_subset <- extractROWS(x, i)

    # Materialize to data.frame and extract list element
    df <- as.data.frame(row_subset@table, optional = TRUE)
    list_col <- colnames(row_subset@table)
    result <- df[[list_col]]

    # DuckDB returns list column as R list with one element
    if (is.list(result) && length(result) == 1L) {
        result[[1L]]
    } else {
        result
    }
})

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Coercion
###

#' @export
#' @importFrom stats setNames
setMethod("as.list", "DuckDBAtomicList", function(x, use.names = TRUE) {
    df <- as.data.frame(x@table, optional = TRUE)

    # Columns are ordered: datacol (column 1), then keycol (column 2)
    names <- .map_keycol_names(x@table@keycols[[1L]], df[[2L]])
    result <- setNames(df[[1L]], names)
    result <- result[rownames(x@table)]

    if (!use.names) {
        names(result) <- NULL
    }
    result
})

#' @export
#' @importFrom DelayedArray getAutoRealizationBackend realize
setMethod("realize", "DuckDBAtomicList",
function(x, BACKEND = getAutoRealizationBackend()) {
    x <- as.list(x)
    if (!is.null(BACKEND)) {
        x <- callGeneric(x, BACKEND = BACKEND)
    }
    x
})

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Display
###

#' @export
#' @importFrom S4Vectors classNameForDisplay elementType
setMethod("show", "DuckDBAtomicList", function(object) {
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
        lst <- as.list(object)
    } else {
        if (n2 == 0L) {
            lst <- as.list(head(object, n1))
            lst <- c(lst, "..." = "...")
        } else {
            i <- c(seq_len(n1), (len + 1L) - rev(seq_len(n2)))
            lst <- as.list(object[i])
            lst <- c(head(lst, n1), "..." = "...", tail(lst, n2))
        }
    }
    # Format list elements for display
    formatted <- vapply(lst, function(elem) {
        if (identical(elem, "...")) {
            return("...")
        }
        if (length(elem) == 0L) {
            return(sprintf("%s(0)", elementType(object)))
        }
        if (length(elem) <= 3L) {
            paste(format(elem), collapse = " ")
        } else {
            paste(c(format(head(elem, 3L)), "..."), collapse = " ")
        }
    }, character(1L), USE.NAMES = TRUE)
    print(formatted, quote = FALSE)
    invisible(NULL)
})

#' @export
#' @importFrom S4Vectors showAsCell
setMethod("showAsCell", "DuckDBAtomicList", function(object) {
    callGeneric(as.list(object))
})
