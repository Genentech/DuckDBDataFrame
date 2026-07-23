#' DuckDBEmbeddings objects
#'
#' @description
#' The DuckDBEmbeddings class extends \linkS4class{RectangularData} and
#' \linkS4class{DuckDBColumn} to represent a single dimensionality reduction
#' embedding (e.g., PCA, UMAP, tSNE) stored in DuckDB using an ARRAY[] column.
#'
#' @details
#' DuckDBEmbeddings provides a DuckDB-backed container for storing a single
#' embedding as a 2D rectangular object where rows represent cells and
#' columns represent dimensions within that embedding. The embedding is
#' stored as a single ARRAY[] column in the underlying DuckDB table,
#' enabling efficient storage and lazy evaluation.
#'
#' @section Accessors:
#' In the code snippets below, \code{x} is a DuckDBEmbeddings object:
#' \describe{
#'   \item{\code{dim(x)}:}{
#'     Returns integer vector of length 2: \code{c(nrow(x), ncol(x))} where
#'     nrow is the number of cells and ncol is the ARRAY size (number of
#'     dimensions in the embedding).
#'   }
#'   \item{\code{nrow(x)}, \code{ncol(x)}:}{
#'     Get the number of rows (cells) and columns (dimensions), respectively.
#'   }
#'   \item{\code{NROW(x)}, \code{NCOL(x)}:}{
#'     Same as \code{nrow(x)} and \code{ncol(x)}, respectively.
#'   }
#'   \item{\code{dimnames(x)}:}{
#'     Returns list of length 2: \code{list(rownames(x), colnames(x))}.
#'   }
#'   \item{\code{rownames(x)}, \code{colnames(x)}:}{
#'     Get the names of the rows (cell IDs) and columns (dimension names),
#'     respectively.
#'   }
#'   \item{\code{length(x)}:}{
#'     Get the number of cells (same as \code{nrow(x)}).
#'   }
#'   \item{\code{names(x)}:}{
#'     Get the cell IDs (same as \code{rownames(x)}).
#'   }
#'   \item{\code{type(x)}:}{
#'     Get the ARRAY data type. Returns enhanced format \code{"array<double,50>"}
#'     or raw DuckDB format \code{"DOUBLE[50]"} depending on schema detection.
#'   }
#'   \item{\code{coltypes(x)}:}{
#'     Get the R element type (e.g., \code{"numeric"} for DOUBLE arrays,
#'     \code{"integer"} for INTEGER arrays). Handles both type formats.
#'   }
#'   \item{\code{dimtbls(x, drop = TRUE)}, \code{dimtbls(x) <- value}:}{
#'     Get or set the list of dimension tables used to define partitions for
#'     efficient queries. If \code{drop = TRUE}, then it returns a named
#'     \code{DataFrameList} object, else it returns an environment containing
#'     a \code{dimtbls} named \code{DataFrameList} element.
#'   }
#' }
#'
#' @section Subsetting:
#' In the code snippets below, \code{x} is a DuckDBEmbeddings object:
#' \describe{
#'   \item{\code{x[i, j, drop=TRUE]}:}{
#'     Subset cells (rows) and/or dimensions (columns). When both \code{i}
#'     and \code{j} are missing, returns \code{x}. When \code{drop=TRUE}
#'     and the result is a single cell or single dimension, returns a
#'     vector. Otherwise returns a matrix or DuckDBEmbeddings object.
#'   }
#'   \item{\code{x[i]}:}{
#'     Subset cells (rows), returns a DuckDBEmbeddings object with the
#'     selected cells.
#'   }
#'   \item{\code{head(x, n = 6L)}:}{
#'     Returns the first n cells of the embedding.
#'   }
#'   \item{\code{tail(x, n = 6L)}:}{
#'     Returns the last n cells of the embedding.
#'   }
#' }
#'
#' @section Coercion:
#' \describe{
#'   \item{\code{as.matrix(x)}:}{
#'     Coerces the embedding to a matrix with cells as rows and
#'     dimensions as columns.
#'   }
#'   \item{\code{realize(x, BACKEND = getAutoRealizationBackend())}:}{
#'     Realize an object into memory or on disk using the equivalent of
#'     \code{realize(as.matrix(x), BACKEND)}.
#'   }
#' }
#'
#' @return
#' Objects of class \code{DuckDBEmbeddings} extend \link[S4Vectors]{RectangularData}.
#'
#' @author Patrick Aboyoun
#'
#' @aliases DuckDBEmbeddings-class
#'
#' @aliases nrow,DuckDBEmbeddings-method
#' @aliases ncol,DuckDBEmbeddings-method
#' @aliases rownames,DuckDBEmbeddings-method
#' @aliases rownames<-,DuckDBEmbeddings-method
#' @aliases colnames,DuckDBEmbeddings-method
#' @aliases colnames<-,DuckDBEmbeddings-method
#'
#' @aliases extractCOLS,DuckDBEmbeddings-method
#' @aliases [,DuckDBEmbeddings,ANY,ANY,ANY-method
#'
#' @aliases as.matrix,DuckDBEmbeddings-method
#' @aliases as.list,DuckDBEmbeddings-method
#' @aliases realize,DuckDBEmbeddings-method
#'
#' @aliases show,DuckDBEmbeddings-method
#' @aliases showAsCell,DuckDBEmbeddings-method
#'
#' @seealso
#' \itemize{
#'   \item \code{\link{DuckDBNumericList-class}} for the base class
#'   \item \code{\link{DuckDBTable-class}} for the underlying table representation
#' }
#'
#' @examples
#' tf <- tempfile(fileext = ".parquet")
#' on.exit(unlink(tf))
#' n <- 10L
#' mat <- matrix(rnorm(n * 5), nrow = n)
#' df <- data.frame(
#'     cell_id = sprintf("cell_%02d", seq_len(n)),
#'     pca = I(asplit(mat, 1L)),
#'     stringsAsFactors = FALSE
#' )
#' arrow::write_parquet(df, tf)
#' emb <- DuckDBDataFrame(tf, keycol = "cell_id")[["pca"]]
#' emb
#' dim(emb)
#' head(emb, 3)
#'
#' @include DuckDBColumn-class.R
#' @include DuckDBTable-class.R
#' @include DuckDBTable-utils.R
#'
#' @keywords classes methods
#'
#' @name DuckDBEmbeddings-class
NULL

#' @export
#' @importClassesFrom S4Vectors RectangularData
setClass("DuckDBEmbeddings",
         contains = c("RectangularData", "DuckDBNumericList"),
         slots = c(ncol = "integer"))

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Accessors
###

# dbconn method inherited from DuckDBNumericList
# tblconn method inherited from DuckDBNumericList
# .keycols method inherited from DuckDBNumericList
# .has_row_number method inherited from DuckDBNumericList
# dimtbls method inherited from DuckDBNumericList
# dimtbls<- method inherited from DuckDBNumericList
# length method inherited from DuckDBNumericList
# names method inherited from DuckDBNumericList
# names<- method inherited from DuckDBNumericList
# type method inherited from DuckDBNumericList
# elementType method inherited from DuckDBNumericList
# as.list method inherited from DuckDBNumericList

### RectangularData methods

#' @export
setMethod("nrow", "DuckDBEmbeddings", function(x) length(x))

#' @export
setMethod("ncol", "DuckDBEmbeddings", function(x) x@ncol)

#' @export
setMethod("rownames", "DuckDBEmbeddings", function(x) names(x))

#' @export
setReplaceMethod("rownames", "DuckDBEmbeddings", function(x, value) {
    names(x) <- value
    x
})

#' @export
setMethod("colnames", "DuckDBEmbeddings", function(x) NULL)

#' @export
setReplaceMethod("colnames", "DuckDBEmbeddings", function(x, value) {
    x
})

# dimnames method inherited from RectangularData

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Validity
###

#' @importFrom S4Vectors isSingleInteger setValidity2
setValidity2("DuckDBEmbeddings", function(x) {
    msg <- NULL
    table <- x@table
    if (length(table@conn) > 0L) {
        if (!isSingleInteger(x@ncol) || x@ncol < 0L) {
            msg <- c(msg, "'ncol' must be a single non-negative integer")
        }
    }
    msg %||% TRUE
})

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Internal constructor (called by DuckDBDataFrame column extraction)
###

#' @importFrom S4Vectors new2
.new_DuckDBEmbeddings <- function(table, type, ncol = NULL, metadata = list()) {
    type <- tolower(type)
    if (!grepl("^array<(double|float|real|decimal),\\d+>$", type)) {
        stop("DuckDBEmbeddings requires numeric array, got: ", type)
    }
    if (is.null(ncol)) {
        ncol <- as.integer(sub("^.*,(\\d+)>$", "\\1", type))
    }
    list_type <- sub("^array<([^,]+),.*>$", "list<\\1>", type)
    list_obj <- .new_DuckDBAtomicList(table, list_type, metadata)
    new2("DuckDBEmbeddings", list_obj, ncol = ncol, check = FALSE)
}

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Subsetting
###

# extractROWS method inherited from DuckDBNumericList

#' @export
#' @importFrom S4Vectors extractCOLS new2 normalizeSingleBracketSubscript
setMethod("extractCOLS", "DuckDBEmbeddings", function(x, i) {
    if (missing(i)) {
        return(x)
    }

    xstub <- setNames(seq_len(x@ncol), colnames(x))
    i <- normalizeSingleBracketSubscript(i, xstub)

    if (anyDuplicated(i)) {
        stop("cannot extract duplicate dimensions in a DuckDBEmbeddings")
    }

    tbl <- x@table
    datacols <- tbl@datacols

    extracts <- lapply(i, function(idx) call("array_extract", datacols[[1L]], idx))
    datacols[[1L]] <- as.call(c(as.name("array_value"), extracts))
    tbl <- replaceSlots(tbl, datacols = datacols, check = FALSE)
    replaceSlots(x, table = tbl, ncol = length(i), check = FALSE)
})

#' @export
setMethod("[", "DuckDBEmbeddings", function(x, i, j, ..., drop = TRUE) {
    if (!missing(i)) {
        x <- extractROWS(x, i)
    }
    if (!missing(j)) {
        x <- extractCOLS(x, j)
    }
    if (missing(drop)) {
        drop <- (ncol(x) == 1L)
    }
    if (drop && (ncol(x) == 1L)) {
        tbl <- x@table
        datacols <- tbl@datacols
        datacols[[1L]] <- datacols[[1L]][[2L]]
        tbl <- replaceSlots(tbl, datacols = datacols, check = FALSE)
        x <- new2("DuckDBColumn", table = tbl, metadata = metadata(x), check = FALSE)
    }
    x
})

# head method inherited from DuckDBNumericList
# tail method inherited from DuckDBNumericList

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Coercion
###

#' @export
setMethod("as.matrix", "DuckDBEmbeddings", function(x, ...) {
    df <- as.data.frame(x@table, optional = TRUE)
    mat <- df[[1L]]

    # Columns from SQL are ordered: datacols first, then keycols.
    # Only for a real (named) key -- a row_number key has no cell names, and its
    # integer64 column would be reinterpreted as garbage doubles by rownames<-.
    if (!.has_row_number(x@table)) {
        rnames <- .map_keycol_names(x@table@keycols[[1L]], df[[ncol(df)]])
        rownames(mat) <- rnames
    }

    mat
})

#' @export
setMethod("as.list", "DuckDBEmbeddings", function(x, ...) {
    mat <- as.matrix(x)
    result <- asplit(mat, 1L)
    names(result) <- rownames(mat)
    result
})

#' @export
#' @importFrom DelayedArray getAutoRealizationBackend realize
setMethod("realize", "DuckDBEmbeddings",
function(x, BACKEND = getAutoRealizationBackend()) {
    x <- as.matrix(x)
    if (!is.null(BACKEND)) {
        x <- callGeneric(x, BACKEND = BACKEND)
    }
    x
})

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Display
###

.makePrettyMatrixForDisplay_DuckDBEmbeddings <- function(x) {
    if (.has_row_number(x)) {
        nhead <- 5L
        ntail <- 0L
    } else {
        nhead <- 3L
        ntail <- 2L
    }

    x_ncol <- ncol(x)
    nleft <- 3L
    nright <- 2L
    is_wide <- (x_ncol > nleft + nright + 1L)
    if (is_wide) {
        x <- x[, c(seq_len(nleft), (x_ncol - nright + 1L):x_ncol), drop = FALSE]
    }

    x_nrow <- nrow(x)
    if (x_nrow <= nhead + ntail + 1L) {
        m <- as.matrix(x)
        x_rownames <- rownames(x)
        m <- format(m, justify = "right")
        if (!is.null(x_rownames)) {
            rownames(m) <- x_rownames
        }
    } else {
        x_head <- head(x, nhead)
        x_rownames <- rownames(x_head)
        if (ntail == 0L) {
            m <- rbind(format(as.matrix(x_head), justify = "right"), "...")
        } else {
            i <- c(seq_len(nhead), (x_nrow + 1L) - rev(seq_len(ntail)))
            mat_parts <- as.matrix(x[i, , drop = FALSE])
            m <- rbind(format(as.matrix(head(mat_parts, nhead)), justify = "right"),
                       "...",
                       format(as.matrix(tail(mat_parts, ntail)), justify = "right"))
            x_rownames <- c(x_rownames, rownames(tail(x, ntail)))
        }
        rownames(m) <- S4Vectors:::make_rownames_for_RectangularData_display(x_rownames, x_nrow, nhead, ntail)
    }

    if (is_wide) {
        m <- cbind(m[, seq_len(nleft), drop = FALSE],
                   "..." = "...",
                   m[, (nleft + 1L):ncol(m), drop = FALSE])
    }

    m
}

#' @export
#' @importFrom S4Vectors classNameForDisplay
setMethod("show", "DuckDBEmbeddings", function(object) {
    cat(sprintf("%s of size <%s>\n", classNameForDisplay(object),
                paste(dim(object), collapse = " x ")))

    if (any(dim(object) == 0L)) {
        return(invisible(NULL))
    }

    m <- .makePrettyMatrixForDisplay_DuckDBEmbeddings(object)
    print(m, quote = FALSE, right = TRUE)

    invisible(NULL)
})

#' @export
#' @importFrom S4Vectors showAsCell
setMethod("showAsCell", "DuckDBEmbeddings", function(object) {
    callGeneric(as.matrix(object))
})
