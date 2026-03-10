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
#'     keycol = NULL, dimtbl = NULL, nodes = NULL)}:}{
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
#'       \item{\code{nodes}}{
#'         An optional integer vector specifying the node ids. If \code{NULL}
#'         (default), uses implicit encoding \code{c(NA_integer_, -nnode)}
#'         representing 1:nnode. Can be an explicit integer vector for
#'         non-contiguous node subsets, optionally named for node aliases.
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
#'     vector of length \code{nLnode(x)}. When nodes are implicit (1:nnode),
#'     returns an unnamed vector with positional indexing. When nodes are
#'     explicit, returns a named vector where names are the node IDs as
#'     characters. This operation materializes the \code{from} column.
#'   }
#'   \item{\code{countRnodeHits(x)}, \code{countSubjectHits(x)}:}{
#'     Count the number of hits for each right/subject node. Returns an integer
#'     vector of length \code{nRnode(x)}. When nodes are implicit (1:nnode),
#'     returns an unnamed vector with positional indexing. When nodes are
#'     explicit, returns a named vector where names are the node IDs as
#'     characters. This operation materializes the \code{to} column.
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
#'   \item{\code{x[i]} or \code{extractROWS(x, i)}:}{
#'     Returns a DuckDBSelfHits object with edge-based subsetting (subsets
#'     edges directly by index, does NOT filter by nodes).
#'   }
#'   \item{\code{extractNODES(x, i)}:}{
#'     Returns a DuckDBSelfHits object with node-based subsetting. Updates
#'     the \code{nodes} slot to track the subset, and filters edges lazily
#'     via SQL to include only edges where BOTH from and to are in the node
#'     subset. Filtering is applied when data is materialized via
#'     \code{tblconn()}, \code{as.data.frame()}, or coercion methods.
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
#' extractNODES
#' extractNODES,DuckDBSelfHits-method
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
         slots = c(frame = "DuckDBDataFrame", nodes = "integer"),
         prototype = prototype(
             frame = new2("DuckDBDataFrame", datacols = .datacols_selfhits, check = FALSE),
             nodes = integer(0L),
             nLnode = 0L,
             nRnode = 0L
         ))

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Accessors
###

#' @export
setMethod("dbconn", "DuckDBSelfHits", function(x) callGeneric(x@frame))

#' @export
#' @importFrom dplyr filter
setMethod("tblconn", "DuckDBSelfHits", function(x, select = TRUE, filter = TRUE) {
    conn <- callGeneric(x@frame, select = select, filter = filter)

    if (filter && !.has_implicit_nodes(x) && length(conn) > 0L) {
        nodes <- .nodes(x)
        dcnms <- names(.datacols_selfhits)
        from <- as.name(dcnms[1L])
        to <- as.name(dcnms[2L])

        conn <- filter(conn, !!from %in% !!nodes & !!to %in% !!nodes)
    }

    conn
})

#' @export
setMethod(".keycols", "DuckDBSelfHits", function(x) {
    frame <- as(x, "DuckDBDataFrame")
    callGeneric(frame)
})

#' @export
setMethod(".has_row_number", "DuckDBSelfHits", function(x) callGeneric(x@frame))

setGeneric(".has_implicit_nodes", function(x) {
    standardGeneric(".has_implicit_nodes")
})

setMethod(".has_implicit_nodes", "DuckDBSelfHits", function(x) {
    length(x@nodes) == 2L && is.na(x@nodes[1L]) && x@nodes[2L] < 0L
})

setGeneric(".nodes", function(x) standardGeneric(".nodes"))

#' @importFrom S4Vectors nnode
setMethod(".nodes", "DuckDBSelfHits", function(x) {
    if (.has_implicit_nodes(x)) {
        seq_len(nnode(x))
    } else {
        x@nodes
    }
})

#' @export
setMethod("dimtbls", "DuckDBSelfHits", function(x, drop = TRUE) {
    callGeneric(x@frame, drop = drop)
})

#' @export
setReplaceMethod("dimtbls", "DuckDBSelfHits", function(x, value) {
    replaceSlots(x, frame = callGeneric(x@frame, value), check = FALSE)
})

#' @export
setMethod("length", "DuckDBSelfHits", function(x) {
    frame <- as(x, "DuckDBDataFrame")
    nrow(frame)
})

#' @export
#' @importFrom S4Vectors from
setMethod("from", "DuckDBSelfHits", function(x) {
    frame <- as(x, "DuckDBDataFrame")
    frame[[names(.datacols_selfhits)[1L]]]
})

#' @export
#' @importFrom S4Vectors to
setMethod("to", "DuckDBSelfHits", function(x) {
    frame <- as(x, "DuckDBDataFrame")
    frame[[names(.datacols_selfhits)[2L]]]
})

# nLnode is inherited from Hits

# nRnode is inherited from Hits

#' @export
#' @importFrom S4Vectors countLnodeHits nLnode
setMethod("countLnodeHits", "DuckDBSelfHits", function(x) {
    tbl <- table(from(x))
    counts <- integer(nLnode(x))
    if (.has_implicit_nodes(x)) {
        counts[as.integer(names(tbl))] <- as.integer(tbl)
    } else {
        names(counts) <- as.character(.nodes(x))
        counts[names(tbl)] <- as.integer(tbl)
    }
    counts
})

#' @export
#' @importFrom S4Vectors countRnodeHits nRnode
setMethod("countRnodeHits", "DuckDBSelfHits", function(x) {
    tbl <- table(to(x))
    counts <- integer(nRnode(x))
    if (.has_implicit_nodes(x)) {
        counts[as.integer(names(tbl))] <- as.integer(tbl)
    } else {
        names(counts) <- as.character(.nodes(x))
        counts[names(tbl)] <- as.integer(tbl)
    }
    counts
})

#' @export
#' @importFrom S4Vectors elementMetadata
setMethod("elementMetadata", "DuckDBSelfHits", function(x) {
    frame <- as(x, "DuckDBDataFrame")
    nms <- setdiff(colnames(frame), names(.datacols_selfhits))
    if (length(nms) == 0L) {
        return(NULL)
    }
    frame[, nms, drop = FALSE]
})

#' @export
#' @importFrom S4Vectors elementMetadata<-
setReplaceMethod("elementMetadata", "DuckDBSelfHits", function(x, ..., value) {
    frame <- as(x, "DuckDBDataFrame")
    if (!is.null(value)) {
        if (!is(value, "DuckDBDataFrame")) {
            stop("'elementMetadata' must be a DuckDBDataFrame object or NULL")
        }
        if (nrow(value) != length(x)) {
            stop("'nrow(value)' must equal 'length(x)'")
        }
        # Combine from/to with new mcols
        frame <- cbind(frame[, names(.datacols_selfhits), drop = FALSE], value)
    } else {
        # Remove all mcols, keep only from/to
        frame <- frame[, names(.datacols_selfhits), drop = FALSE]
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
function(conn, from, to, nnode, mcols = NULL, keycol = NULL, dimtbl = NULL, nodes = NULL)
{

    if (!isSingleNumber(nnode) || nnode < 0L) {
        stop("'nnode' must be a single non-negative integer")
    }

    if (!is.integer(nnode)) {
        nnode <- as.integer(nnode)
    }

    if (is.null(nodes)) {
        nodes <- c(NA_integer_, - nnode)
    } else if (!is.numeric(nodes)) {
        stop("'nodes' must be a numeric vector")
    } else {
        if (!is.integer(nodes)) {
            nodes <- as.integer(nodes)
        }
        if (anyDuplicated(nodes)) {
            stop("'nodes' must contain unique values")
        }
    }

    datacols <- .datacols_selfhits
    dcnms <- names(.datacols_selfhits)

    stringAsName <- function(x) if (isSingleString(x)) as.name(x) else x

    datacols[[dcnms[1L]]] <- stringAsName(from)
    datacols[[dcnms[2L]]] <- stringAsName(to)

    if (is.null(datacols[[dcnms[1L]]]) ||
        is.null(datacols[[dcnms[2L]]])) {
        stop(sprintf("'%s' and '%s' must be specified",
                     dcnms[1L], dcnms[2L]))
    }

    datacols <- datacols[dcnms]
    if (length(mcols) > 0L) {
        if (is.character(mcols)) {
            mcols <- sapply(mcols, as.name, simplify = FALSE)
        }
        mcols <- as.expression(mcols)
        datacols <- c(datacols, mcols)
    }

    frame <- DuckDBDataFrame(conn, datacols = datacols, keycol = keycol,
                             dimtbl = dimtbl)

    new2("DuckDBSelfHits", frame = frame, nodes = nodes, nLnode = nnode,
         nRnode = nnode, check = FALSE)
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
    frame <- as(x, "DuckDBDataFrame")
    replaceSlots(x, frame = callGeneric(frame, i = i), check = FALSE)
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
setGeneric("extractNODES", function(x, i) standardGeneric("extractNODES"))

#' @export
#' @importFrom S4Vectors extractROWS nnode
setMethod("extractNODES", "DuckDBSelfHits", function(x, i) {
    nodes <- extractROWS(.nodes(x), i)
    nnode <- length(nodes)
    replaceSlots(x, nodes = nodes, nLnode = nnode, nRnode = nnode,
                 check = FALSE)
})

#' @export
#' @importFrom S4Vectors head
setMethod("head", "DuckDBSelfHits", function(x, n = 6L, ...) {
    frame <- as(x, "DuckDBDataFrame")
    replaceSlots(x, frame = callGeneric(frame, n = n, ...), check = FALSE)
})

#' @export
#' @importFrom S4Vectors tail
setMethod("tail", "DuckDBSelfHits", function(x, n = 6L, ...) {
    frame <- as(x, "DuckDBDataFrame")
    replaceSlots(x, frame = callGeneric(frame, n = n, ...), check = FALSE)
})

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Coercion
###

#' @export
#' @importFrom dplyr pull select
setAs("DuckDBSelfHits", "DuckDBDataFrame", function(from) {
    conn <- tblconn(from, select = TRUE, filter = TRUE)

    keycols <- from@frame@keycols
    if (!.has_implicit_nodes(from)) {
        keys <- pull(select(conn, !!as.name(names(keycols)[1L])))
        keycols[[1L]] <- intersect(keycols[[1L]], keys)
    }

    replaceSlots(from@frame, conn = conn, keycols = keycols, check = FALSE)
})

#' @export
#' @importFrom S4Vectors DataFrame
setAs("DuckDBSelfHits", "DFrame", function(from) {
    as(as(from, "DuckDBDataFrame"), "DFrame")
})

#' @export
setMethod("as.data.frame", "DuckDBSelfHits",
function(x, row.names = NULL, optional = FALSE, ...) {
    df <- as(x, "DuckDBDataFrame")
    as.data.frame(df, row.names = row.names, optional = optional, ...)
})

#' @export
#' @importClassesFrom S4Vectors SelfHits
#' @importFrom S4Vectors SelfHits mcols<- nnode
setAs("DuckDBSelfHits", "SelfHits", function(from) {
    df <- as.data.frame(from, optional = TRUE)
    dcnms <- names(.datacols_selfhits)

    # Perform node remapping if nodes are explicit
    if (!.has_implicit_nodes(from)) {
        node_ids <- .nodes(from)
        node_map <- setNames(seq_along(node_ids), as.character(node_ids))

        df[[dcnms[1L]]] <- node_map[as.character(df[[dcnms[1L]]])]
        df[[dcnms[2L]]] <- node_map[as.character(df[[dcnms[2L]]])]
    }

    # Validate from/to indices are within bounds (after remapping)
    nnode_val <- nnode(from)
    if (nrow(df) > 0L) {
        if (any(df[[dcnms[1L]]] < 1L | df[[dcnms[1L]]] > nnode_val)) {
            stop(sprintf("'%s' indices out of bounds [1, nnode]", dcnms[1L]))
        }
        if (any(df[[dcnms[2L]]] < 1L | df[[dcnms[2L]]] > nnode_val)) {
            stop(sprintf("'%s' indices out of bounds [1, nnode]", dcnms[2L]))
        }
    }

    hits <- SelfHits(df[[dcnms[1L]]], df[[dcnms[2L]]], nnode = nnode_val)

    # Add mcols if present
    mcnms <- setdiff(colnames(df), dcnms)
    if (length(mcnms) > 0L) {
        mcols(hits) <- df[, mcnms, drop = FALSE]
    }

    hits
})

#' @export
#' @importClassesFrom Matrix dgCMatrix
#' @importClassesFrom S4Vectors SelfHits
#' @importFrom Matrix sparseMatrix
#' @importFrom S4Vectors nnode
setAs("DuckDBSelfHits", "dgCMatrix", function(from) {
    df <- as.data.frame(from, optional = TRUE)
    dcnms <- names(.datacols_selfhits)
    mcnms <- setdiff(colnames(df), dcnms)
    if (length(mcnms) > 0L) {
        x <- df[[mcnms[1L]]]
    } else {
        x <- rep.int(TRUE, nrow(df))
    }
    sparseMatrix(i = df[[dcnms[1L]]], j = df[[dcnms[2L]]],
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
