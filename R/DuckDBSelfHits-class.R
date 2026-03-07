#' DuckDBSelfHits objects
#'
#' @description
#' The DuckDBSelfHits class extends the \linkS4class{SelfHits} class from
#' S4Vectors for DuckDB tables.
#'
#' @details
#' DuckDBSelfHits provides lazy evaluation for large graph structures (e.g., =
#' KNN graphs, similarity matrices) by storing edge lists in DuckDB-backed
#' tables. This enables efficient storage and querying of pairwise relationships
#' without materializing all edges in memory.
#'
#' The class stores the parallel slots (`from`, `to`, and any metadata columns)
#' in a \linkS4class{DuckDBDataFrame}, while keeping the scalar `nLnode` and
#' `nRnode` slots materialized for fast validation.
#'
#' @section Constructor:
#' \describe{
#'   \item{\code{DuckDBSelfHits(conn, from, to, nnode, mcols = NULL,
#'     keycol = NULL, dimtbl = NULL)}:}{
#'     Creates a DuckDBSelfHits object.
#'     \describe{
#'       \item{\code{conn}}{
#'         Either a character vector containing the paths to parquet, csv, or
#'         gzipped csv data files; a string that defines a duckdb \code{read_*}
#'         data source; a DuckDBDataFrame object; or a tbl_duckdb_connection
#'         object.
#'       }
#'       \item{\code{from}}{
#'         Either \code{NULL} or a string specifying the column from
#'         \code{conn} that defines the query/left nodes (1-indexed).
#'       }
#'       \item{\code{to}}{
#'         Either \code{NULL} or a string specifying the column from
#'         \code{conn} that defines the subject/right nodes (1-indexed).
#'       }
#'       \item{\code{nnode}}{
#'         Single integer specifying the number of nodes in the graph.
#'         Must be positive. This is the only slot that remains materialized.
#'       }
#'       \item{\code{mcols}}{
#'         Optional character vector specifying additional columns that define
#'         edge metadata (e.g., "weight", "distance", "x").
#'       }
#'       \item{\code{keycol}}{
#'         An optional string specifying the column name from \code{conn} that
#'         will define the foreign key in the underlying table, or a named list
#'         containing a character vector where the name of the list element
#'         defines the foreign key and the character vector sets the distinct
#'         values for that key. If missing, a \code{row_number} column is
#'         created as an identifier for each edge.
#'       }
#'       \item{\code{dimtbl}}{
#'         An optional named \code{DataFrameList} that specifies the dimension
#'         table associated with the \code{keycol}. The name of the list
#'         element must match the name of the \code{keycol} list. Additionally,
#'         the \code{DataFrame} object must have row names that match the
#'         distinct values of the \code{keycol} list element.
#'       }
#'     }
#'   }
#' }
#'
#' @section Accessors:
#' In the code snippets below, \code{x} is a DuckDBSelfHits object:
#' \describe{
#'   \item{\code{length(x)}:}{
#'     Get the number of edges (hits).
#'   }
#'   \item{\code{from(x)}, \code{queryHits(x)}:}{
#'     Get the query/left node indices as a \linkS4class{DuckDBColumn}.
#'   }
#'   \item{\code{to(x)}, \code{subjectHits(x)}:}{
#'     Get the subject/right node indices as a \linkS4class{DuckDBColumn}.
#'   }
#'   \item{\code{nnode(x)}, \code{nLnode(x)}, \code{nRnode(x)}:}{
#'     Get the number of nodes. All three return the same value for SelfHits.
#'   }
#'   \item{\code{queryLength(x)}, \code{subjectLength(x)}:}{
#'     Get the number of left/right nodes. For SelfHits, both return
#'     \code{nnode(x)}.
#'   }
#'   \item{\code{countLnodeHits(x)}, \code{countQueryHits(x)}:}{
#'     Count the number of hits for each left/query node. Returns an integer
#'     vector of length \code{nLnode(x)}. This operation materializes the
#'     \code{from} column.
#'   }
#'   \item{\code{countRnodeHits(x)}, \code{countSubjectHits(x)}:}{
#'     Count the number of hits for each right/subject node. Returns an integer
#'     vector of length \code{nRnode(x)}. This operation materializes the
#'     \code{to} column.
#'   }
#'   \item{\code{mcols(x)}, \code{mcols(x) <- value}:}{
#'     Get or set the edge metadata columns.
#'   }
#' }
#'
#' @section Coercion:
#' \describe{
#'   \item{\code{as(from, "DuckDBDataFrame")}:}{
#'     Creates a \linkS4class{DuckDBDataFrame} object with from, to, and mcols.
#'   }
#'   \item{\code{as.data.frame(x)}:}{
#'     Coerces \code{x} to a data.frame.
#'   }
#'   \item{\code{as(from, "SelfHits")}:}{
#'     Converts a DuckDBSelfHits object to a materialized SelfHits object.
#'     This will load all edges into memory.
#'   }
#'   \item{\code{as(from, "dgCMatrix")}:}{
#'     Converts to a sparse matrix. Equivalent to
#'     \code{as(as(from, "SelfHits"), "dgCMatrix")}.
#'   }
#'   \item{\code{realize(x, BACKEND = getAutoRealizationBackend())}:}{
#'     Realize an object into memory or on disk using the equivalent of
#'     \code{realize(as(x, "SelfHits"), BACKEND)}.
#'   }
#' }
#'
#' @section Subsetting:
#' In the code snippets below, \code{x} is a DuckDBSelfHits object:
#' \describe{
#'   \item{\code{x[i]}:}{
#'     Returns a DuckDBSelfHits object containing edges where both from and to
#'     nodes are in the subset. Node indices are automatically remapped.
#'   }
#'   \item{\code{head(x, n = 6L)}:}{
#'     If \code{n} is non-negative, returns the first n edges.
#'     If \code{n} is negative, returns all but the last \code{abs(n)} edges.
#'   }
#'   \item{\code{tail(x, n = 6L)}:}{
#'     If \code{n} is non-negative, returns the last n edges.
#'     If \code{n} is negative, returns all but the first \code{abs(n)} edges.
#'   }
#' }
#'
#' @section Operations:
#' \describe{
#'   \item{\code{sort(x, decreasing = FALSE)}:}{
#'     Returns a DuckDBSelfHits with edges sorted by from node, then by to node.
#'     The sorting is performed lazily using SQL ORDER BY.
#'   }
#'   \item{\code{t(x)}:}{
#'     Transpose the graph by swapping from and to columns.
#'   }
#'   \item{\code{c(x, ...)}:}{
#'     Concatenate multiple DuckDBSelfHits objects.
#'   }
#' }
#'
#' @section Displaying:
#' The \code{show()} method for DuckDBSelfHits objects obeys global options
#' \code{showHeadLines} and \code{showTailLines} for controlling the number of
#' edges to display.
#'
#' @author Patrick Aboyoun
#'
#' @examples
#' # Create an example edge list:
#' edges <- data.frame(
#'   from = c(1, 1, 2, 3, 4, 4, 5),
#'   to = c(2, 5, 3, 4, 2, 5, 1),
#'   weight = c(0.8, 0.6, 0.9, 0.7, 0.85, 0.75, 0.65),
#'   distance = c(1.2, 2.3, 1.5, 1.8, 1.4, 2.1, 2.5)
#' )
#' tf <- tempfile(fileext = ".parquet")
#' on.exit(unlink(tf))
#' arrow::write_parquet(edges, tf)
#'
#' # Create the DuckDBSelfHits object
#' hits <- DuckDBSelfHits(tf, from = "from", to = "to", nnode = 5,
#'                        mcols = c("weight", "distance"))
#' hits
#'
#' # Access edge data
#' from(hits)
#' to(hits)
#' mcols(hits)
#'
#' # Convert to sparse matrix (materializes)
#' mat <- as(hits, "dgCMatrix")
#'
#' @aliases
#' DuckDBSelfHits-class
#'
#' dbconn,DuckDBSelfHits-method
#' tblconn,DuckDBSelfHits-method
#' .keycols,DuckDBSelfHits-method
#' .has_row_number,DuckDBSelfHits-method
#' dimtbls,DuckDBSelfHits-method
#' dimtbls<-,DuckDBSelfHits-method
#' length,DuckDBSelfHits-method
#' from,DuckDBSelfHits-method
#' to,DuckDBSelfHits-method
#' countLnodeHits,DuckDBSelfHits-method
#' countRnodeHits,DuckDBSelfHits-method
#' elementMetadata,DuckDBSelfHits-method
#' elementMetadata<-,DuckDBSelfHits-method
#'
#' DuckDBSelfHits
#'
#' extractROWS,DuckDBSelfHits,ANY-method
#' [,DuckDBSelfHits,ANY,ANY,ANY-method
#' head,DuckDBSelfHits-method
#' tail,DuckDBSelfHits-method
#'
#' coerce,DuckDBSelfHits,DuckDBDataFrame-method
#' coerce,DuckDBSelfHits,DFrame-method
#' as.data.frame,DuckDBSelfHits-method
#' coerce,DuckDBSelfHits,SelfHits-method
#' coerce,DuckDBSelfHits,dgCMatrix-method
#' realize,DuckDBSelfHits-method
#'
#' show,DuckDBSelfHits-method
#'
#' @seealso
#' \itemize{
#'   \item \code{\link[S4Vectors]{SelfHits}} for the base class
#'   \item \code{\link[SingleCellExperiment]{colPairs}} for usage in SingleCellExperiment
#'   \item \code{\linkS4class{DuckDBDataFrame}} for the underlying storage
#' }
#'
#' @keywords classes methods
#'
#' @name DuckDBSelfHits-class
NULL

.datacols_selfhits <- expression(from = NULL, to = NULL)

#' @export
#' @import methods BiocGenerics
#' @importClassesFrom S4Vectors SelfHits
#' @importFrom S4Vectors new2
setClass("DuckDBSelfHits", contains = "SelfHits",
         slots = c(frame = "DuckDBDataFrame"),
         prototype = prototype(
             frame = new2("DuckDBDataFrame", datacols = .datacols_selfhits, check = FALSE),
             nLnode = 0L,
             nRnode = 0L
         ))

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Accessors
###

#' @export
setMethod("dbconn", "DuckDBSelfHits", function(x) callGeneric(x@frame))

#' @export
setMethod("tblconn", "DuckDBSelfHits", function(x, select = TRUE, filter = TRUE) {
    callGeneric(x@frame, select = select, filter = filter)
})

#' @export
setMethod(".keycols", "DuckDBSelfHits", function(x) callGeneric(x@frame))

#' @export
setMethod(".has_row_number", "DuckDBSelfHits", function(x) callGeneric(x@frame))

#' @export
setMethod("dimtbls", "DuckDBSelfHits", function(x, drop = TRUE) {
    callGeneric(x@frame, drop = drop)
})

#' @export
setReplaceMethod("dimtbls", "DuckDBSelfHits", function(x, value) {
    replaceSlots(x, frame = callGeneric(x@frame, value), check = FALSE)
})

#' @export
setMethod("length", "DuckDBSelfHits", function(x) nrow(x@frame))

#' @export
#' @importFrom S4Vectors from
setMethod("from", "DuckDBSelfHits", function(x) x@frame[[names(.datacols_selfhits)[1L]]])

#' @export
#' @importFrom S4Vectors to
setMethod("to", "DuckDBSelfHits", function(x) x@frame[[names(.datacols_selfhits)[2L]]])

# nLnode is inherited from Hits

# nRnode is inherited from Hits

#' @export
#' @importFrom S4Vectors countLnodeHits nLnode
setMethod("countLnodeHits", "DuckDBSelfHits", function(x) {
    tbl <- table(from(x))
    counts <- integer(nLnode(x))
    counts[as.integer(names(tbl))] <- as.integer(tbl)
    counts
})

#' @export
#' @importFrom S4Vectors countRnodeHits nRnode
setMethod("countRnodeHits", "DuckDBSelfHits", function(x) {
    tbl <- table(to(x))
    counts <- integer(nRnode(x))
    counts[as.integer(names(tbl))] <- as.integer(tbl)
    counts
})

#' @export
#' @importFrom S4Vectors elementMetadata
setMethod("elementMetadata", "DuckDBSelfHits", function(x) {
    nms <- setdiff(colnames(x@frame), names(.datacols_selfhits))
    if (length(nms) == 0L) {
        return(NULL)
    }
    x@frame[, nms, drop = FALSE]
})

#' @export
#' @importFrom S4Vectors elementMetadata<-
setReplaceMethod("elementMetadata", "DuckDBSelfHits", function(x, ..., value) {
    if (!is.null(value)) {
        if (!is(value, "DuckDBDataFrame")) {
            stop("'elementMetadata' must be a DuckDBDataFrame object or NULL")
        }
        if (nrow(value) != length(x)) {
            stop("'nrow(value)' must equal 'length(x)'")
        }
        # Combine from/to with new mcols
        frame <- cbind(x@frame[, names(.datacols_selfhits), drop = FALSE], value)
    } else {
        # Remove all mcols, keep only from/to
        frame <- x@frame[, names(.datacols_selfhits), drop = FALSE]
    }
    replaceSlots(x, frame = frame, check = FALSE)
})

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Validity
###

#' @importFrom S4Vectors setValidity2
setValidity2("DuckDBSelfHits", function(x) {
    msg <- NULL

    # Check that frame has from/to columns
    if (!all(names(.datacols_selfhits) %in% colnames(x@frame))) {
        msg <- c(msg, sprintf("frame must have '%s' and '%s' columns",
                              names(.datacols_selfhits)[1L],
                              names(.datacols_selfhits)[2L]))
    }

    # Check that nLnode and nRnode are equal (SelfHits constraint)
    if (x@nLnode != x@nRnode) {
        msg <- c(msg, "'nLnode' must equal 'nRnode' for SelfHits")
    }

    # Check that nLnode is a single non-negative integer
    if (length(x@nLnode) != 1L || !is.integer(x@nLnode) || x@nLnode < 0L) {
        msg <- c(msg, "'nLnode' must be a single non-negative integer")
    }

    msg %||% TRUE
})

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Constructor
###

#' @export
#' @importFrom dplyr mutate select
#' @importFrom S4Vectors isSingleNumber isSingleString new2
DuckDBSelfHits <-
function(conn, from, to, nnode, mcols = NULL, keycol = NULL, dimtbl = NULL)
{

    if (!isSingleNumber(nnode) || nnode < 0L) {
        stop("'nnode' must be a single non-negative integer")
    }

    if (!is.integer(nnode)) {
        nnode <- as.integer(nnode)
    }

    datacols <- .datacols_selfhits
    datacol_names <- names(.datacols_selfhits)

    stringAsName <- function(x) if (isSingleString(x)) as.name(x) else x

    datacols[[datacol_names[1L]]] <- stringAsName(from)
    datacols[[datacol_names[2L]]] <- stringAsName(to)

    if (is.null(datacols[[datacol_names[1L]]]) ||
        is.null(datacols[[datacol_names[2L]]])) {
        stop(sprintf("'%s' and '%s' must be specified",
                     datacol_names[1L], datacol_names[2L]))
    }

    datacols <- datacols[datacol_names]
    if (length(mcols) > 0L) {
        if (is.character(mcols)) {
            mcols <- sapply(mcols, as.name, simplify = FALSE)
        }
        mcols <- as.expression(mcols)
        datacols <- c(datacols, mcols)
    }

    frame <- DuckDBDataFrame(conn, datacols = datacols, keycol = keycol,
                             dimtbl = dimtbl)

    new2("DuckDBSelfHits", frame = frame, nLnode = nnode, nRnode = nnode,
         check = FALSE)
}

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Subsetting
###

#' @export
#' @importFrom S4Vectors extractROWS
setMethod("extractROWS", "DuckDBSelfHits", function(x, i) {
    if (missing(i)) {
        return(x)
    }
    replaceSlots(x, frame = callGeneric(x@frame, i = i), check = FALSE)
})

#' @export
#' @importFrom S4Vectors extractROWS
setMethod("[", "DuckDBSelfHits", function(x, i, j, ..., drop = TRUE) {
    if (!missing(j)) {
        stop("two-dimensional indexing not supported for DuckDBSelfHits")
    }
    extractROWS(x, i)
})

#' @export
#' @importFrom S4Vectors head
setMethod("head", "DuckDBSelfHits", function(x, n = 6L, ...) {
    replaceSlots(x, frame = callGeneric(x@frame, n = n, ...), check = FALSE)
})

#' @export
#' @importFrom S4Vectors tail
setMethod("tail", "DuckDBSelfHits", function(x, n = 6L, ...) {
    replaceSlots(x, frame = callGeneric(x@frame, n = n, ...), check = FALSE)
})

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Coercion
###

#' @export
setAs("DuckDBSelfHits", "DuckDBDataFrame", function(from) {
    from@frame
})

#' @export
setAs("DuckDBSelfHits", "DFrame", function(from) {
    as(from@frame, "DFrame")
})

#' @export
setMethod("as.data.frame", "DuckDBSelfHits",
function(x, row.names = NULL, optional = FALSE, ...) {
    callGeneric(x@frame, row.names = row.names, optional = optional, ...)
})

#' @export
#' @importClassesFrom S4Vectors SelfHits
#' @importFrom S4Vectors SelfHits mcols<- nnode
setAs("DuckDBSelfHits", "SelfHits", function(from) {
    df <- as.data.frame(from, optional = TRUE)
    datacol_names <- names(.datacols_selfhits)

    # Validate from/to indices are within bounds
    nnode_val <- nnode(from)
    if (any(df[[datacol_names[1L]]] < 1L | df[[datacol_names[1L]]] > nnode_val)) {
        stop(sprintf("'%s' indices out of bounds [1, nnode]", datacol_names[1L]))
    }
    if (any(df[[datacol_names[2L]]] < 1L | df[[datacol_names[2L]]] > nnode_val)) {
        stop(sprintf("'%s' indices out of bounds [1, nnode]", datacol_names[2L]))
    }

    hits <- SelfHits(df[[datacol_names[1L]]], df[[datacol_names[2L]]], nnode = nnode_val)

    # Add mcols if present
    mcol_names <- setdiff(colnames(df), datacol_names)
    if (length(mcol_names) > 0L) {
        mcols(hits) <- df[, mcol_names, drop = FALSE]
    }

    hits
})

#' @export
#' @importClassesFrom Matrix dgCMatrix
#' @importClassesFrom S4Vectors SelfHits
#' @importFrom Matrix sparseMatrix
#' @importFrom S4Vectors nnode
setAs("DuckDBSelfHits", "dgCMatrix", function(from) {
    hits <- as(from, "SelfHits")
    df <- as.data.frame(from, optional = TRUE)
    datacol_names <- names(.datacols_selfhits)
    mcol_names <- setdiff(colnames(df), datacol_names)
    if (length(mcol_names) > 0L) {
        x <- df[[mcol_names[1L]]]
    } else {
        x <- rep.int(TRUE, nrow(df))
    }
    sparseMatrix(i = df[[datacol_names[1L]]], j = df[[datacol_names[2L]]],
                 x = x, dims = rep(nnode(from), 2L), use.last.ij = TRUE)
})

#' @export
#' @importClassesFrom S4Vectors SelfHits
#' @importFrom DelayedArray getAutoRealizationBackend realize
setMethod("realize", "DuckDBSelfHits",
function(x, BACKEND = getAutoRealizationBackend()) {
    x <- as(x, "SelfHits")
    if (!is.null(BACKEND)) {
        x <- callGeneric(x, BACKEND = BACKEND)
    }
    x
})

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Display
###

#' @export
#' @importFrom S4Vectors nnode
setMethod("show", "DuckDBSelfHits", function(object) {
    cat("DuckDBSelfHits object with ", length(object), " hit",
        if (length(object) != 1L) "s" else "", " and ",
        nnode(object), " node", if (nnode(object) != 1L) "s" else "", ":\n",
        sep = "")

    if (length(object) > 0L) {
        # Display edge list with mcols
        m <- .makePrettyCharacterMatrixForDisplay(as(object, "DuckDBDataFrame"))

        # Mark from/to columns
        nc <- ncol(m)
        k <- length(setdiff(colnames(object@frame), names(.datacols_selfhits)))
        if (k > 0L) {
            h <- nc - k
            m <- cbind(m[, 1:h, drop = FALSE],
                       `|` = ifelse(rownames(m) == "...", ".", "|"),
                       m[, (h + 1L):nc, drop = FALSE])
        }
        print(m, quote = FALSE, right = TRUE)
    }
})
