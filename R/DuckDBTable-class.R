#' DuckDBTable objects
#'
#' @description
#' The DuckDBTable class extends the \linkS4class{RectangularData} virtual
#' class for DuckDB tables by wrapping a tbl_duckdb_connection object.
#'
#' @details
#' The DuckDBTable class provides a way to define a DuckDB table as a
#' \linkS4class{RectangularData} object. It supports \emph{standard 2D API}
#' such as \code{dim()}, \code{nrow()}, \code{ncol()}, \code{dimnames()},
#' \code{x[i, j]} and \code{cbind()}, but does not support \code{rbind()}.
#'
#' @section Constructor:
#' \describe{
#'   \item{\code{DuckDBTable(conn, datacols = colnames(conn), keycols = NULL, dimtbls = NULL, type = NULL, collevels = NULL)}:}{
#'     Creates a DuckDBTable object.
#'     \describe{
#'       \item{\code{conn}}{
#'         Either a character vector containing the paths to parquet, csv, or
#'         gzipped csv data files; a string that defines a duckdb \code{read_*}
#'         data source; a DuckDBDataFrame object; or a tbl_duckdb_connection
#'         object.
#'       }
#'       \item{\code{datacols}}{
#'         Either a character vector of column names from \code{conn} or a
#'         named \code{expression} that will be evaluated in the context of
#'         \code{conn} that defines the data.
#'       }
#'       \item{\code{keycols}}{
#'         An optional character vector of column names from \code{conn} that
#'         will define the set of foreign keys in the underlying table, or a
#'         named list of character vectors where the names of the list define
#'         the foreign keys and the character vectors set the distinct values
#'         for those keys. If missing, a \code{row_number} column is created
#'         as an identifier.
#'       }
#'       \item{\code{dimtbls}}{
#'         Either NULL, a named \code{DataFrameList} object, or an environment
#'         containing a named \code{DataFrameList} \code{"dimtbls"} element that
#'         specifies the dimension tables associated with the \code{keycols}.
#'         The name of the list elements match the names of the \code{keycols}
#'         list. Additionally, the \code{DataFrame} objects have row names that
#'         match the distinct values of the corresponding \code{keycols} list
#'         element and columns that define partitions in the data table for
#'         efficient querying.
#'       }
#'       \item{\code{type}}{
#'         An optional named character vector where the names specify the
#'         column names and the values specify the column type; one of
#'         \code{"logical"}, \code{"integer"}, \code{"integer64"},
#'         \code{"double"}, or \code{"character"}.
#'       }
#'       \item{\code{collevels}}{
#'         An optional named list, keyed by data column name, that restores
#'         \code{factor} columns on materialization. Each element is a list with
#'         a character \code{levels} vector and a \code{TRUE}/\code{FALSE}
#'         \code{ordered} flag; columns not named are left unchanged. Primarily
#'         used by \code{readParquet()} to recover factors recorded in a
#'         product's schema.
#'       }
#'     }
#'   }
#' }
#'
#' @section Accessors:
#' In the code snippets below, \code{x} is a DuckDBTable object:
#' \describe{
#'   \item{\code{dim(x)}:}{
#'     Length two integer vector defined as \code{c(nrow(x), ncol(x))}.
#'   }
#'   \item{\code{nrow(x)}, \code{ncol(x)}:}{
#'     Get the number of rows and columns, respectively.
#'   }
#'   \item{\code{NROW(x)}, \code{NCOL(x)}:}{
#'     Same as \code{nrow(x)} and \code{ncol(x)}, respectively.
#'   }
#'   \item{\code{dimnames(x)}:}{
#'     Length two list of character vectors defined as
#'     \code{list(rownames(x), colnames(x))}.
#'   }
#'   \item{\code{rownames(x)}, \code{colnames(x)}:}{
#'     Get the names of the rows and columns, respectively.
#'   }
#'   \item{\code{coltypes(x)}, \code{coltypes(x) <- value}:}{
#'     Get or set the data type of the columns. Getter returns one of
#'     \code{"logical"}, \code{"integer"}, \code{"integer64"}, \code{"double"},
#'     \code{"character"}, or complex type strings like \code{"list<integer>"},
#'     \code{"array<numeric,128>"}, \code{"struct"}, \code{"map"}, \code{"blob"},
#'     or \code{"geometry"}. Setter accepts atomic types only.
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
#'   \item{\code{as.data.frame(x)}:}{
#'     Coerces \code{x} to a data.frame.
#'   }
#' }
#'
#' @section Subsetting:
#' In the code snippets below, \code{x} is a DuckDBTable object:
#' \describe{
#'   \item{\code{x[i, j]}:}{
#'     Return a new DuckDBTable of the same class as \code{x} made of the
#'     selected rows and columns.
#'   }
#'   \item{\code{head(x, n = 6L)}:}{
#'     If \code{n} is non-negative, returns the first n rows of \code{x}.
#'     If \code{n} is negative, returns all but the last \code{abs(n)} rows of
#'     \code{x}.
#'   }
#'   \item{\code{tail(x, n = 6L)}:}{
#'     If \code{n} is non-negative, returns the last n rows of \code{x}.
#'     If \code{n} is negative, returns all but the first \code{abs(n)} rows of
#'     \code{x}.
#'   }
#' }
#'
#' @return
#' Objects of class \code{DuckDBTable} extend \link[S4Vectors]{RectangularData}.
#'
#' @author Patrick Aboyoun
#'
#' @examples
#' # Create a data.frame from the Titanic data
#' df <- do.call(expand.grid, c(dimnames(Titanic), stringsAsFactors = FALSE))
#' df$fate <- as.integer(Titanic[as.matrix(df)])
#'
#' # Write data to a parquet file
#' tf <- tempfile(fileext = ".parquet")
#' on.exit(unlink(tf))
#' arrow::write_parquet(df, tf)
#'
#' tbl <- DuckDBTable(tf, datacols = "fate", keycols = c("Class", "Sex", "Age", "Survived"))
#'
#' @aliases DuckDBTable-class
#'
#' @aliases .set_row_number
#' @aliases dbconn,DuckDBTable-method
#' @aliases tblconn,DuckDBTable-method
#' @aliases .keycols
#' @aliases .keycols,DuckDBTable-method
#' @aliases .has_row_number
#' @aliases .has_row_number,DuckDBTable-method
#' @aliases nrow,DuckDBTable-method
#' @aliases ncol,DuckDBTable-method
#' @aliases rownames,DuckDBTable-method
#' @aliases colnames,DuckDBTable-method
#' @aliases colnames<-,DuckDBTable-method
#' @aliases coltypes
#' @aliases coltypes,DuckDBTable-method
#' @aliases coltypes<-
#' @aliases coltypes<-,DuckDBTable-method
#' @aliases dimtbls
#' @aliases dimtbls,DuckDBTable-method
#' @aliases dimtbls<-
#' @aliases dimtbls<-,DuckDBTable-method
#'
#' @aliases DuckDBTable
#'
#' @aliases all.equal.DuckDBTable
#'
#' @aliases [,DuckDBTable,ANY,ANY,ANY-method
#' @aliases extractROWS,DuckDBTable,ANY-method
#' @aliases extractCOLS,DuckDBTable-method
#' @aliases head,DuckDBTable-method
#' @aliases tail,DuckDBTable-method
#' @aliases subset,DuckDBTable-method
#'
#' @aliases bindROWS,DuckDBTable-method
#' @aliases bindCOLS,DuckDBTable-method
#'
#' @aliases as.data.frame,DuckDBTable-method
#' @aliases as.env,DuckDBTable-method
#'
#' @aliases show,DuckDBTable-method
#'
#' @seealso
#' \itemize{
#'   \item \code{\link{DuckDBTable-utils}} for the utilities
#'   \item \code{\link[S4Vectors]{RectangularData}} for the base class
#' }
#'
#' @include DuckDBConnection.R
#' @include keynames.R
#' @include tblconn.R
#'
#' @keywords classes methods
#'
#' @name DuckDBTable-class
NULL

#' @import methods BiocGenerics
setOldClass("tbl_duckdb_connection")

replaceSlots <- BiocGenerics:::replaceSlots

#' @export
#' @importFrom bit64 NA_integer64_
#' @importFrom dplyr n pull summarize
.set_row_number <- function(conn) {
    c(NA_integer64_, - pull(summarize(conn, n = n())))
}

#' @export
#' @importClassesFrom BiocGenerics OutOfMemoryObject
#' @importClassesFrom IRanges DataFrameList
#' @importClassesFrom S4Vectors RectangularData
#' @importFrom IRanges DataFrameList
#' @importFrom stats setNames
setClass("DuckDBTable", contains = c("RectangularData", "OutOfMemoryObject"),
    slots = c(conn = "tbl_duckdb_connection", datacols = "expression", keycols = "list",
              dimtbls = "environment", collevels = "list"),
    prototype = prototype(conn = structure(list(),
                                           class = c("tbl_duckdb_connection", "tbl_dbi",
                                                     "tbl_sql", "tbl_lazy", "tbl")),
                          datacols = setNames(expression(), character()),
                          keycols = setNames(list(), character()),
                          collevels = setNames(list(), character()),
                          dimtbls = {
                            env <- new.env(parent = emptyenv())
                            env[["dimtbls"]] <- setNames(DataFrameList(), character())
                            lockEnvironment(env)
                            env
                          }))

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Accessors
###

#' @export
setMethod("dbconn", "DuckDBTable", function(x) x@conn$src$con)

#' @importFrom dbplyr lazy_select_query
#' @importFrom dplyr mutate
#' @importFrom rlang new_quosure
#' @importFrom stats setNames
#' @importFrom tibble tibble
.mutate_datacols <- function(conn, datacols) {
    lazy_query <- conn[["lazy_query"]]
    k <- length(datacols)
    if (k > 1L) {
        if (!inherits(lazy_query, "lazy_select_query")) {
            lazy_query <- lazy_select_query(lazy_query,
                                            select_operation = "select")
        }
        slist <- lazy_query[["select"]]

        # Create the tibble for the mutation
        env <- setNames(slist[["expr"]], slist[["name"]])
        expr <- lapply(unname(as.list(datacols)), function(y) {
            new_quosure(do.call(substitute, list(y, env)), emptyenv())
        })
        klist <- tibble(name = names(datacols),
                        expr = expr,
                        group_vars = rep.int(list(character()), k),
                        order_vars = rep.int(list(NULL), k),
                        frame = rep.int(list(NULL), k))

        # Combine the original select and mutate lists
        slist <- slist[!(slist[["name"]] %in% klist[["name"]]), ]
        slist <- rbind(slist, klist)
        lazy_query[["select"]] <- slist

        conn[["lazy_query"]] <- lazy_query
    } else {
        conn <- mutate(conn, !!!as.list(datacols))
    }

    # Return the updated connection
    conn
}

#' @importFrom dplyr select
#' @importFrom stats setNames
.select_tblconn <- function(conn, keycols, datacols) {
    dcols <- names(datacols)
    kcols <- names(keycols)

    shared <- intersect(dcols, kcols)
    if (length(shared) > 0L) {
        modified <- make.unique(c(dcols, kcols), sep = "_")
        names(kcols) <- tail(modified, length(kcols))
        kcols <- setNames(names(kcols), kcols)
        expr <- setNames(lapply(shared, as.name), kcols[shared])
        kcols <- unname(kcols)
        conn <- mutate(conn, !!!expr)
    }

    conn <- .mutate_datacols(conn, datacols)

    # Select datacols first, then keycols
    conn <- select(conn, !!!lapply(c(dcols, kcols), as.name))

    conn
}

# Find contiguous integer ranges in a sorted integer vector
# Returns a list of c(start, end) pairs
.find_contiguous_ranges <- function(x) {
    if (length(x) == 0L) return(list())
    x <- sort(unique(x))
    if (length(x) == 1L) return(list(c(x, x)))

    # Find break points where values are not consecutive
    breaks <- which(diff(x) != 1L)
    starts <- c(1L, breaks + 1L)
    ends <- c(breaks, length(x))

    mapply(function(s, e) c(x[s], x[e]), starts, ends, SIMPLIFY = FALSE)
}

# Build a filter expression using BETWEEN for contiguous ranges
# More efficient than IN lists for DuckDB row group pruning
#' @importFrom DBI dbQuoteLiteral
#' @importFrom dplyr between sql
#' @importFrom bit64 is.integer64
.build_range_filter <- function(conn, col_name, ranges) {
    if (length(ranges) == 0L) return(NULL)

    col_sym <- as.name(col_name)
    db_con <- conn$src$con

    # integer64 bounds must be rendered as bare SQL integer literals
    quote_bound <- function(v) {
        if (is.integer64(v)) {
            sql(as.character(v))
        } else {
            dbQuoteLiteral(db_con, v)
        }
    }

    # Build OR'd BETWEEN expressions for each range
    exprs <- lapply(ranges, function(r) {
        left <- quote_bound(r[1L])
        right <- quote_bound(r[2L])
        if (r[1L] == r[2L]) {
            # Single value - use equality
            call("==", col_sym, left)
        } else {
            # Range - use between
            call("between", col_sym, left, right)
        }
    })

    # Combine with OR if multiple ranges
    if (length(exprs) == 1L) {
        exprs[[1L]]
    } else {
        Reduce(function(a, b) call("|", a, b), exprs)
    }
}

# Register an in-memory key vector as a virtual DuckDB table for join-based
# filtering, returning a lazy tbl over it. Used for large key sets, where a
# semi-/anti-join is cheaper to compile and execute than a giant IN list.
#' @importFrom dplyr tbl
#' @importFrom duckdb duckdb_register
.register_key_table <- function(conn, col_name, set) {
    db_con <- conn$src$con
    temp_suffix <- basename(tempfile(pattern = ""))
    temp_name <- sprintf("temp_filter_%s_%s", col_name, temp_suffix)
    temp_df <- data.frame(key = set)
    names(temp_df) <- col_name
    duckdb_register(db_con, temp_name, temp_df)
    tbl(db_con, temp_name)
}

# Above this many keys, filtering switches from an inline IN list to a temporary-
# table SEMI/ANTI JOIN: large inline IN lists dominate DuckDB's SQL compile time.
.KEY_FILTER_JOIN_THRESHOLD <- 256L

# Apply key filter using the best strategy based on set size.
# For large sets (see .KEY_FILTER_JOIN_THRESHOLD) a temp-table SEMI/ANTI JOIN is
# used instead of an IN list. NA-valued keys are handled explicitly: SQL
# 'x [NOT] IN (..., NULL)' evaluates to UNKNOWN (not TRUE/FALSE), which silently
# drops rows -- and for the complement a single NA in 'set' turns
# 'NOT IN (..., NULL)' into UNKNOWN for *every* row, wiping the result. We
# therefore never emit a NULL inside an IN list, and reproduce base-R `%in%`
# semantics for NA-valued keys.
#' @importFrom dplyr anti_join filter semi_join
#' @importFrom bit64 is.integer64
.apply_key_filter <- function(conn, col_name, set, complement = FALSE) {
    col_sym <- as.name(col_name)

    # is.na() (not anyNA()) so integer64's NA encoding is detected correctly.
    na <- is.na(set)
    set_has_na <- any(na)
    set <- set[!na]
    k <- length(set)

    if (complement) {
        # base R: `!(x %in% set)` is TRUE for an NA key iff NA is *not* in 'set'.
        if (k > .KEY_FILTER_JOIN_THRESHOLD) {
            # A hash anti-join keeps NA-keyed rows (NULL never matches), matching
            # the NA-not-in-set case; drop them explicitly when NA is in 'set'.
            conn <- anti_join(conn, .register_key_table(conn, col_name, set),
                              by = col_name)
            if (set_has_na) {
                conn <- filter(conn, !is.na(!!col_sym))
            }
        } else if (set_has_na) {
            conn <- filter(conn, !is.na(!!col_sym) & !(!!col_sym %in% set))
        } else {
            conn <- filter(conn, is.na(!!col_sym) | !(!!col_sym %in% set))
        }
    } else {
        # Membership: an NA-valued key is never selected by a value set.
        if (k > .KEY_FILTER_JOIN_THRESHOLD) {
            conn <- semi_join(conn, .register_key_table(conn, col_name, set),
                              by = col_name)
        } else {
            conn <- filter(conn, !!col_sym %in% set)
        }
    }

    conn
}

# Map database keycol values to potentially aliased R rownames
#' @importFrom stats setNames
.map_keycol_names <- function(keycol, values) {
    if (is.null(names(keycol))) {
        values
    } else {
        mapping <- setNames(names(keycol), keycol)
        mapping[as.character(values)]
    }
}

# Determine if a stored key set and a query result's materialized names form a
# clean 1:1 correspondence (same multiset, no duplicates on either side)
.storedKeysBijective <- function(keys, nm) {
    length(keys) == length(nm) &&
        !anyDuplicated(keys) && !anyDuplicated(nm) &&
        setequal(keys, nm)
}

# Reorder a query-materialized, query-labeled result into an object's canonical
# (stored-key) row order WITHOUT relabelling.
.reindexByStoredKeys <- function(result, keys) {
    if (.storedKeysBijective(keys, names(result))) {
        result[keys]
    } else {
        result
    }
}

#' @importFrom dplyr filter
.filter_tblconn <- function(conn, keycols, dimtbls) {
    for (i in names(keycols)) {
        set <- unique(keycols[[i]])
        k <- length(set)

        # For integer keys, try to use BETWEEN predicates (enables row group pruning)
        range_filter <- NULL
        if ((is.integer(set) || is.integer64(set)) && k > 0L) {
            ranges <- .find_contiguous_ranges(set)
            # Use range predicates if they're more efficient than IN list
            # Heuristic: use ranges if total range count is small relative to set size
            if (length(ranges) <= max(10L, k / 10L)) {
                range_filter <- .build_range_filter(conn, i, ranges)
            }
        }

        if (i %in% names(dimtbls)) {
            # Filter with dimension tables
            dimtbl <- dimtbls[[i]]
            comp <- setdiff(rownames(dimtbl) %||% seq_len(nrow(dimtbl)), set)
            ncomp <- length(comp)
            if (ncomp > 0L) {
                # Add the dimension table filters
                sectbl <- dimtbl[set, , drop = FALSE]
                for (j in colnames(sectbl)) {
                    part <- unique(sectbl[[j]])
                    comp2 <- setdiff(unique(dimtbl[[j]]), part)
                    ncomp2 <- length(comp2)
                    if (ncomp2 > 0L) {
                        if (ncomp2 >= length(part)) {
                            conn <- filter(conn, !!as.name(j) %in% part)
                        } else {
                            conn <- filter(conn, !(!!as.name(j) %in% comp2))
                        }
                    }
                }

                # Add the key filter
                if (!is.null(range_filter)) {
                    conn <- filter(conn, !!range_filter)
                } else if (ncomp >= k) {
                    conn <- .apply_key_filter(conn, i, set)
                } else {
                    conn <- .apply_key_filter(conn, i, comp, complement = TRUE)
                }
            }
        } else {
            # Filter without dimension tables
            if (!is.null(range_filter)) {
                conn <- filter(conn, !!range_filter)
            } else {
                conn <- .apply_key_filter(conn, i, set)
            }
        }
    }

    conn
}

#' @export
#' @importFrom dplyr filter select
#' @importFrom S4Vectors isTRUEorFALSE
setMethod("tblconn", "DuckDBTable", function(x, select = TRUE, filter = TRUE) {
    if (!isTRUEorFALSE(filter)) {
        stop("'filter' must be TRUE or FALSE")
    }

    conn <- x@conn

    if (length(conn) > 0L) {
        if (filter && !.has_row_number(x) && !.is_aggregated(conn)) {
            conn <- .filter_tblconn(conn, keycols = x@keycols, dimtbls = dimtbls(x))
        }

        if (select) {
            conn <- .select_tblconn(conn, keycols = x@keycols, datacols = x@datacols)
        }
    }

    conn
})

# Check if connection is already aggregated (has GROUP BY)
# Applying filters to aggregated connections creates HAVING clauses
.is_aggregated <- function(conn) {
    lazy_query <- conn[["lazy_query"]]
    if (is.null(lazy_query)) {
        return(FALSE)
    }
    # Check if this is a grouped query (has group_by applied)
    inherits(lazy_query, "lazy_select_query") &&
        !is.null(lazy_query[["group_by"]]) &&
        length(lazy_query[["group_by"]]) > 0L
}

#' @export
setGeneric(".keycols", function(x) standardGeneric(".keycols"))

#' @export
setMethod(".keycols", "DuckDBTable", function(x) x@keycols)

#' @export
setGeneric(".has_row_number", function(x) standardGeneric(".has_row_number"))

#' @export
#' @importFrom bit64 as.integer64 is.integer64
setMethod(".has_row_number", "DuckDBTable", function(x) {
    if (length(x@keycols) == 1L) {
        key1 <- x@keycols[[1L]]
        is.integer64(key1) && (length(key1) == 2L) && is.na(key1[1L]) && (key1[2L] <= as.integer64(0L))
    } else {
        FALSE
    }
})

#' @export
setMethod("nkey", "DuckDBTable", function(x) {
    if (.has_row_number(x)) 0L else length(x@keycols)
})

#' @export
setMethod("nkeydim", "DuckDBTable", function(x) {
    if (length(x@conn) == 0L) {
        0L
    } else if (.has_row_number(x)) {
        abs(x@keycols[[1L]][2L])
    } else {
        lengths(x@keycols, use.names = FALSE)
    }
})

#' @export
#' @importFrom bit64 as.integer64
setMethod("nrow", "DuckDBTable", function(x) {
    nr <- prod(as.integer64(nkeydim(x)))
    if (nr <= as.integer64(.Machine$integer.max)) {
        as.integer(nr)
    } else {
        nr
    }
})

#' @export
setMethod("ncol", "DuckDBTable", function(x) length(x@datacols))

#' @export
setMethod("keynames", "DuckDBTable", function(x) {
    if (.has_row_number(x)) character(0L) else names(x@keycols)
})

#' @export
#' @importFrom dplyr pull select
setMethod("keydimnames", "DuckDBTable", function(x) {
    if (.has_row_number(x)) {
        list(as.character(pull(select(x@conn, !!as.name(names(x@keycols))))))
    } else {
        lapply(x@keycols, function(y) names(y) %||% as.character(y))
    }
})

#' @export
setReplaceMethod("keydimnames", "DuckDBTable", function(x, value) {
    if (is.null(value)) {
        value <- lapply(x@keycols, function(y) NULL)
    } else if (!is.list(value)) {
        stop("'value' must be a list of vectors")
    }

    keycols <- x@keycols
    if (is.null(names(value))) {
        if (length(value) != length(keycols)) {
            stop("if 'value' is unnamed, then it must match length of 'keycols'")
        }
        names(value) <- names(keycols)
    }

    for (i in names(value)) {
        if (!is.null(value[[i]])) {
            names(keycols[[i]]) <- value[[i]]
        }
    }

    replaceSlots(x, keycols = keycols, check = FALSE)
})

#' @export
setMethod("rownames", "DuckDBTable", function(x, do.NULL = TRUE, prefix = "row") {
    if (length(x@conn) == 0L) {
        NULL
    } else if (length(x@keycols) == 1L) {
        keydimnames(x)[[1L]]
    } else {
        stop("rownames is not supported for multi-dimensional keys")
    }
})

#' @export
setMethod("colnames", "DuckDBTable", function(x, do.NULL = TRUE, prefix = "col") {
    names(x@datacols)
})

#' @export
setReplaceMethod("colnames", "DuckDBTable", function(x, value) {
    datacols <- x@datacols
    rename <- setNames(value, names(datacols))
    names(datacols) <- value
    collevels <- .sync_collevels(x@collevels, datacols, rename = rename)
    replaceSlots(x, datacols = datacols, collevels = collevels, check = FALSE)
})

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### R-based type detection (for atomic types)
###

#' @importFrom bit64 is.integer64
.get_type <- function(column) {
    if (is.integer64(column)) {
        "integer64"
    } else if (inherits(column, "Date")) {
        "Date"
    } else if (inherits(column, "POSIXct")) {
        "POSIXct"
    } else if (is.list(column)) {
        "raw" # one of DuckDB LIST/ARRAY/GEOMETRY/MAP/STRUCT/BLOB
    } else {
        DelayedArray::type(column)
    }
}

.duckdb_type_to_r <- function(duckdb_type) {
    type <- tolower(duckdb_type)
    if (grepl("^(list<.*>|struct[<(].*[>)]|map<.*,.*>)$", type)) {
        "list"
    } else if (grepl("^array<.*,\\d+>$", type)) {
        "matrix"
    } else if (grepl("^geometry(\\(.*\\))?$", type)) {
        "geometry"
    } else {
        switch(type,
               "boolean" = "logical",
               "tinyint" =,
               "smallint" =,
               "integer" =,
               "utinyint" =,
               "usmallint" = "integer",
               "uinteger" =,
               "bigint" =,
               "ubigint" = "integer64",
               "float" =,
               "double" =,
               "real" =,
               "decimal" =,
               "hugeint" =,
               "uhugeint" = "double",
               "varchar" =,
               "char" =,
               "bpchar" =,
               "text" =,
               "string" = "character",
               "date" = "Date",
               "timestamp" =,
               "time" = "POSIXct",
               "interval" = "difftime",
               "blob" = "raw",
               "geometry_type" = "character",
               stop("unsupported DuckDB type: ", duckdb_type))
    }
}

# Warn once per construction when a column's DuckDB type maps to an R type that
# cannot represent it faithfully: 128-bit integers and wide decimals collapse to
# 'double'; unsigned 64-bit collapses to (signed) 'integer64'. Narrow integer and
# float widths are intentionally NOT warned: base R has no type to preserve them.
.warn_lossy_widetypes <- function(schema) {
    if (length(schema) == 0L) {
        return(invisible(NULL))
    }
    type <- toupper(schema)
    lossy <- character(0L)
    for (col in names(type)) {
        t <- type[[col]]
        if (grepl("^U?HUGEINT", t)) {
            lossy[[col]] <- "128-bit integer -> double"
        } else if (grepl("^UBIGINT", t)) {
            lossy[[col]] <- "unsigned 64-bit -> signed integer64"
        } else if (grepl("^DECIMAL", t)) {
            p <- suppressWarnings(as.integer(sub("^DECIMAL\\((\\d+).*", "\\1", t)))
            if (is.na(p)) p <- 18L  # bare DECIMAL defaults to DECIMAL(18,3)
            if (p > 15L) {
                lossy[[col]] <- sprintf("DECIMAL(%d) -> double", p)
            }
        }
    }
    if (length(lossy) > 0L) {
        warning(sprintf("possible precision loss reading column(s): %s",
                        paste(sprintf("'%s' (%s)", names(lossy), unlist(lossy)),
                              collapse = ", ")),
                call. = FALSE)
    }
    invisible(NULL)
}

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Schema-based type detection (for complex types)
###

#' @importFrom DBI dbGetQuery
#' @importFrom dbplyr sql_render
#' @importFrom dplyr select
.get_duckdb_schema <- function(conn, datacols) {
    if (!inherits(conn, "tbl_duckdb_connection")) {
        return(character(0L))
    }

    tryCatch({
        conn <- .mutate_datacols(conn, datacols)
        conn <- select(conn, !!!as.list(names(datacols)))
        sql <- sql_render(conn)

        db_conn <- conn$src$con
        schema <- dbGetQuery(db_conn, sprintf("DESCRIBE (%s)", sql))
        setNames(schema$column_type, schema$column_name)
    }, error = function(e) {
        character(0L)
    })
}

.duckdb_element_type <- function(type) {
    type <- tolower(type)
    if (grepl("^array<", type)) {
        sub("^array<([^,]+),.*>$", "\\1", type)
    } else if (grepl("^list<", type)) {
        sub("^list<(.*)>$", "\\1", type)
    } else if (grepl("\\[\\d+\\]$", type)) {
        sub("\\[\\d+\\]$", "", type)
    } else if (grepl("\\[any\\]$", type)) {
        sub("\\[any\\]$", "", type)
    } else if (grepl("\\[\\]$", type)) {
        sub("\\[\\]$", "", type)
    } else if (grepl("\\[.*\\]$", type)) {
        sub("\\[.*\\]$", "", type)
    } else {
        type
    }
}

.duckdb_container_type <- function(type) {
    if (is.null(type) || is.na(type)) {
        NA_character_ # trigger R-based inspection
    } else {
        type <- tolower(gsub("\\s+", " ", trimws(type)))
        if (grepl("\\[\\]$", type)) {
            element_type <- .duckdb_element_type(type)
            sprintf("list<%s>", element_type)
        } else if (grepl("\\[\\d+\\]$", type)) {
            element_type <- .duckdb_element_type(type)
            array_size <- sub(".*\\[(\\d+)\\]$", "\\1", type)
            sprintf("array<%s,%s>", element_type, array_size)
        } else if (grepl("\\[any\\]$", type)) {
            element_type <- .duckdb_element_type(type)
            sprintf("array<%s,0>", element_type)
        } else if (grepl("^geometry(\\(.*\\))?$", type)) {
            "geometry"
        } else if (grepl("^map\\(", type)) {
            "map"
        } else if (grepl("^struct\\(", type)) {
            "struct"
        } else {
            tolower(trimws(sub("\\(.*\\)$", "", type)))
        }
    }
}

#' @importFrom DBI dbQuoteIdentifier
#' @importFrom dplyr collect distinct mutate select
.get_array_length <- function(conn, datacols) {
    if (!inherits(conn, "tbl_duckdb_connection") || length(datacols) != 1L) {
        return(NA_integer_)
    }
    tryCatch({
        col <- list(len = call("len", datacols[[1L]]))
        conn <- head(distinct(select(mutate(conn, !!!col), as.name("len"))), 2L)
        result <- collect(conn)
        lengths <- result[["len"]]
        if (length(lengths) == 1L) {
            as.integer(lengths)
        } else {
            NA_integer_
        }
    }, error = function(e) {
        NA_integer_
    })
}

.cast_cols <- function(datacols, value) {
    if (is.null(names(value)) && (length(value) == length(datacols))) {
        names(value) <- names(datacols)
    }
    for (j in names(value)) {
        cast <- switch(value[j],
                       logical = "as.logical",
                       integer = "as.integer",
                       integer64 = "as.integer64",
                       double = "as.double",
                       character = "as.character",
                       stop("'type' must be one of 'logical', 'integer', 'integer64', 'double', or 'character'"))
        datacols[[j]] <- call(cast, datacols[[j]])
    }
    datacols
}

#' @export
setGeneric("coltypes", function(x) standardGeneric("coltypes"))

#' @export
setMethod("coltypes", "DuckDBTable", function(x) {
    schema <- .get_duckdb_schema(x@conn, x@datacols)
    types <- setNames(rep.int("raw", length(x@datacols)), names(x@datacols))
    for (col in names(x@datacols)) {
        type <- schema[[col]]
        if (!is.null(type) && !is.na(type)) {
            type <- .duckdb_container_type(type)
            if (!is.na(type)) {
                types[col] <- .duckdb_type_to_r(type)
            }
        }
    }
    types
})

#' @export
setGeneric("coltypes<-", function(x, value) standardGeneric("coltypes<-"))

#' @export
setReplaceMethod("coltypes", "DuckDBTable", function(x, value) {
    datacols <- .cast_cols(x@datacols, value)
    # A recast column is no longer a factor: drop any recorded levels for it.
    changed <- names(value)
    if (is.null(changed) && (length(value) == length(x@datacols))) {
        changed <- names(x@datacols)
    }
    collevels <- x@collevels[setdiff(names(x@collevels), changed)]
    replaceSlots(x, datacols = datacols, collevels = collevels, check = FALSE)
})

#' @importClassesFrom IRanges DataFrameList
#' @importFrom IRanges DataFrameList
.create_dimtbls <- function(x) {
    if (!is.environment(x)) {
        value <- x
        x <- new.env(parent = emptyenv())
        x[["dimtbls"]] <- value
    }
    if (length(x[["dimtbls"]]) == 0L) {
        x[["dimtbls"]] <- setNames(DataFrameList(), character())
    } else if (!is(x[["dimtbls"]], "DataFrameList")) {
        x[["dimtbls"]] <- as(x[["dimtbls"]], "DataFrameList")
    }
    if (!bindingIsLocked("dimtbls", x)) {
        x[["dimtbls"]] <- x[["dimtbls"]][nrows(x[["dimtbls"]]) > 0L]
        lockEnvironment(x, bindings = TRUE)
    }
    x
}

#' @export
setGeneric("dimtbls", function(x, drop = TRUE) standardGeneric("dimtbls"))

#' @export
setMethod("dimtbls", "DuckDBTable", function(x, drop = TRUE) {
    if (drop) {
        x@dimtbls[["dimtbls"]]
    } else {
        x@dimtbls
    }
})

#' @export
setGeneric("dimtbls<-", function(x, value) standardGeneric("dimtbls<-"))

#' @export
setReplaceMethod("dimtbls", "DuckDBTable", function(x, value) {
    replaceSlots(x, dimtbls = .create_dimtbls(value), check = FALSE)
})

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Validity
###

#' @importFrom S4Vectors setValidity2
setValidity2("DuckDBTable", function(x) {
    msg <- NULL

    if (is.null(names(x@keycols))) {
        msg <- c(msg, "'keycols' slot must be a named list")
    }
    if (!all(names(x@keycols) %in% colnames(x@conn))) {
        msg <- c(msg, "all names in 'keycols' slot must match column names in 'conn'")
    }
    for (i in seq_along(x@keycols)) {
        if (!is.atomic(x@keycols[[i]])) {
            msg <- c(msg, "all elements in 'keycols' slot must be atomic")
            break
        }
    }

    if (!exists("dimtbls", x@dimtbls) || !is(dimtbls(x), "DataFrameList")) {
        msg <- c(msg, "'dimtbls' slot must be an environment with a 'dimtbls' DataFrameList element")
    } else {
        if (is.null(names(dimtbls(x)))) {
            msg <- c(msg, "'dimtbls' must contain a 'dimtbls' named DataFrameList element")
        }
        if (!all(names(dimtbls(x)) %in% names(x@keycols))) {
            msg <- c(msg, "all names in 'dimtbls' must match names in 'keycols' slot")
        }
    }

    if (is.null(names(x@datacols))) {
        msg <- c(msg, "'datacols' slot must be a named expression")
    }

    if (length(x@collevels) > 0L) {
        if (is.null(names(x@collevels)) ||
            !all(names(x@collevels) %in% names(x@datacols))) {
            msg <- c(msg, "'collevels' slot must be a named list keyed by 'datacols' names")
        }
        for (i in seq_along(x@collevels)) {
            entry <- x@collevels[[i]]
            if (!is.list(entry) || !is.character(entry[["levels"]]) ||
                !isTRUEorFALSE(entry[["ordered"]])) {
                msg <- c(msg, "each 'collevels' entry must be list(levels = <character>, ordered = <TRUE/FALSE>)")
                break
            }
        }
    }

    msg %||% TRUE
})

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Factor level bookkeeping
###

# Coerce a user/reader-supplied 'collevels' into the canonical sparse form: a
# named list keyed by datacol name, each entry list(levels=<character>,
# ordered=<TRUE/FALSE>). Entries not naming a current datacol are dropped, as are
# NULL/empty entries (a missing key means "not a factor").
.normalize_collevels <- function(datacols, collevels) {
    if (is.null(collevels) || length(collevels) == 0L) {
        return(setNames(list(), character()))
    }
    collevels <- collevels[intersect(names(collevels), names(datacols))]
    keep <- vapply(collevels, function(entry) {
        is.list(entry) && length(entry[["levels"]]) > 0L
    }, logical(1L))
    collevels <- collevels[keep]
    lapply(collevels, function(entry) {
        list(levels = as.character(entry[["levels"]]),
             ordered = isTRUE(entry[["ordered"]]))
    })
}

# Keep 'collevels' in sync with a (possibly renamed/subset) 'datacols' after a
# structural column operation: retain only entries whose column survives. When
# 'rename' is supplied (old -> new names), the entries are re-keyed accordingly.
.sync_collevels <- function(collevels, datacols, rename = NULL) {
    if (length(collevels) == 0L) {
        return(collevels)
    }
    if (!is.null(rename)) {
        hit <- names(collevels) %in% names(rename)
        names(collevels)[hit] <- rename[names(collevels)[hit]]
    }
    collevels[intersect(names(collevels), names(datacols))]
}

# Restore factor columns of a just-collected data.frame from 'collevels'. Gated
# on the collected column being physically 'character': a factor column that has
# been cast/transformed materializes as a non-character type and is left as-is.
.apply_collevels <- function(df, collevels) {
    for (col in intersect(names(collevels), names(df))) {
        if (is.character(df[[col]])) {
            entry <- collevels[[col]]
            df[[col]] <- factor(df[[col]], levels = entry[["levels"]],
                                ordered = entry[["ordered"]])
        }
    }
    df
}

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Constructor
###

.wrapFile <- function(x, read) {
    x <- sprintf("'%s'", x)
    if (length(x) > 1L) {
        x <- sprintf("[%s]", paste(x, collapse = ", "))
    }
    sprintf("%s(%s)", read, x)
}

#' @importFrom S4Vectors isSingleString
.wrapConn <- function(x) {
    if (all(grepl("(?i)\\.(csv|tsv)(\\.gz)?$", x))) {
        x <- .wrapFile(x, "read_csv")
    } else if (all(grepl("(?i)\\.(parquet|pq)$", x))) {
        x <- .wrapFile(x, "read_parquet")
    } else if (isSingleString(x) && .isRemotePath(x)) {
            configureCloud(acquireDuckDBConn())
            x <- .wrapFile(file.path(x, "**"), "read_parquet")
    } else if (isSingleString(x) && dir.exists(x)) {
            files <- list.files(x, recursive = TRUE)
            if (any(all(grepl("(?i)\\.(parquet|pq)$", files)))) {
                x <- .wrapFile(file.path(x, "**"), "read_parquet")
            }
        }
    x
}

#' @export
#' @importClassesFrom IRanges DataFrameList
#' @importFrom arrow open_dataset
#' @importFrom DBI dbQuoteIdentifier
#' @importFrom dplyr distinct mutate pull row_number select sql tbl
#' @importFrom IRanges DataFrameList
#' @importFrom S4Vectors new2
#' @importFrom stats setNames
DuckDBTable <-
function(conn, datacols = colnames(conn), keycols = NULL, dimtbls = NULL, type = NULL,
         collevels = NULL) {
    # Acquire the connection if it is a string
    actual <- NULL
    if (is.character(conn)) {
        actual <- try(colnames(open_dataset(conn)), silent = TRUE)
        if (inherits(actual, "try-error")) {
            actual <- NULL
        }
        conn <- tbl(acquireDuckDBConn(), .wrapConn(conn))
    } else if (is(conn, "DuckDBTable")) {
        conn <- conn@conn
    } else if (!inherits(conn, "tbl_duckdb_connection")) {
        stop("'conn' must be a 'tbl_duckdb_connection' object")
    }

    # DuckDB table connection can change column names
    cols <- colnames(conn)
    cols <- setNames(cols, cols)
    if (!is.null(actual)) {
        if (k <- length(cols) - length(actual)) {
            actual <- c(actual, tail(cols, k))
        }
        cols <- setNames(cols, actual)
    }

    if (missing(datacols)) {
        datacols <- as.expression(lapply(cols, as.name))
    }

    # Ensure 'datacols' is a named expression
    if (length(datacols) == 0L) {
        datacols <- setNames(expression(), character())
    } else {
        if (is.character(datacols)) {
            datacols <- lapply(cols[datacols], as.name)
            if (!is.null(type)) {
                if (is.null(names(type)) || length(setdiff(names(type), names(datacols)))) {
                    stop("all names in 'type' must have a corresponding name in 'datacols'")
                }
                datacols <- .cast_cols(datacols, type)
            }
        }
        datacols <- as.expression(datacols)
        if (is.null(names(datacols))) {
            stop("'datacols' must be a named expression")
        }
    }

    # Warn on lossy wide-type -> R conversions (128-bit / unsigned 64-bit / wide
    # decimal), reusing the schema fetched just below.
    full_schema <- toupper(.get_duckdb_schema(conn, datacols))
    .warn_lossy_widetypes(full_schema)

    # Cast fixed-length LIST[] to ARRAY[] for embeddings
    schema <- full_schema
    pattern <- "^(DOUBLE|FLOAT|REAL|DECIMAL)\\[\\]$"
    schema <- schema[grepl(pattern, schema)]
    for (col in names(schema)) {
        len <- .get_array_length(conn, datacols[col])
        if (!is.na(len)) {
            conn <- mutate(conn, !!!as.list(datacols[col]))
            type <- sub(pattern, "\\1", schema[[col]])
            cast <- sql(sprintf("CAST(%s AS %s)",
                                dbQuoteIdentifier(conn$src$con, col),
                                sprintf("%s[%d]", type, len)))
            cast <- setNames(list(cast), col)
            conn <- mutate(conn, !!!cast)
            datacols[[col]] <- as.name(col)
        }
    }

    # Ensure 'keycols' is a named list of vectors
    if (length(keycols) == 0L) {
        keycols <- tail(make.unique(c(colnames(conn), "row_number"), sep = "_"), 1L)
        keycols <- setNames(list(call("row_number")), keycols)
        conn <- mutate(conn, !!!keycols)
        keycols[[1L]] <- .set_row_number(conn)
    } else {
        if (is.character(keycols)) {
            keycols <- unname(cols[keycols])
            keycols <- setNames(vector("list", length(keycols)), keycols)
        }
        if (!is.list(keycols) || is.null(names(keycols))) {
            stop("'keycols' must be a character vector or a named list of vectors")
        }
        for (k in names(keycols)) {
            if (is.null(keycols[[k]])) {
                keycols[[k]] <- pull(distinct(select(conn, !!as.name(k))))
            }
            if (!is.character(keycols[[k]])) {
                keycols[[k]] <- sort(keycols[[k]])
            }
        }
    }
    dimtbls <- .create_dimtbls(dimtbls)
    collevels <- .normalize_collevels(datacols, collevels)

    new2("DuckDBTable", conn = conn, datacols = datacols, keycols = keycols,
         dimtbls = dimtbls, collevels = collevels, check = FALSE)
}

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Comparison
###

#' @exportS3Method base::all.equal
all.equal.DuckDBTable <- function(target, current, check.datacols = FALSE, ...) {
    if (!is(current, "DuckDBTable")) {
        return("current is not a DuckDBTable")
    }
    target <- as(target, "DuckDBTable")
    current <- as(current, "DuckDBTable")
    if (!check.datacols) {
        target <- target[, integer()]
        current <- current[, integer()]
    }
    callGeneric(unclass(target), unclass(current), ...)
}

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Subsetting
###

# Helper function to recompute row_number after filtering
# This is needed because ROW_NUMBER() is computed before WHERE clauses in SQL,
# so after filtering, we need to reassign row numbers 1..N to the remaining rows
#' @importFrom dplyr select mutate
.recompute_row_number <- function(conn, keycol_name) {
    # Get all column names except the row_number keycol
    all_cols <- colnames(conn)
    data_cols <- setdiff(all_cols, keycol_name)

    # Select only data columns (dropping old row_number)
    select_exprs <- lapply(data_cols, as.name)
    conn <- select(conn, !!!select_exprs)

    # Add fresh row_number
    rownum_mutate <- setNames(list(call("row_number")), keycol_name)
    conn <- mutate(conn, !!!rownum_mutate)

    conn
}

#' @importClassesFrom S4Vectors NSBS
#' @importFrom bit64 as.integer64
#' @importFrom dplyr distinct filter pull select
.subset_DuckDBTable <- function(x, i, j, ..., drop = TRUE) {
    conn <- x@conn
    datacols <- x@datacols
    collevels <- x@collevels
    if (!missing(j)) {
        datacols <- datacols[j]
        collevels <- .sync_collevels(collevels, datacols)
    }

    keycols <- x@keycols
    if (!missing(i)) {
        if (!is.list(i) || is.null(names(i))) {
            stop("'i' must be a named list")
        }
        for (k in intersect(names(keycols), names(i))) {
            sub <- i[[k]]
            if (is(sub, "NSBS")) {
                sub <- as.integer(sub)
            }
            if (is.atomic(sub)) {
                if (.has_row_number(x)) {
                    if (is.numeric(sub)) {
                        keep <- call("%in%", as.name(k), as.integer64(sub))
                        conn <- filter(conn, !!keep)
                        keycols[[1L]] <- .set_row_number(conn)
                    } else {
                        stop("unsupported 'i' for row subsetting with row_number")
                    }
                } else if (is.character(sub) && is.null(names(keycols[[k]]))) {
                    keycols[[k]] <- sub
                } else {
                    keycols[[k]] <- keycols[[k]][sub]
                }
            } else if (is(sub, "DuckDBColumn") &&
                       is.logical(as.vector(head(sub, 0L))) &&
                       isTRUE(all.equal(as(x, "DuckDBTable"), sub@table))) {
                keep <- sub@table@datacols[[1L]]
                conn <- filter(conn, !!keep)
                if (.has_row_number(x)) {
                    # Recompute row_number after filtering so indices are 1..N
                    # instead of the original row numbers from before filtering
                    conn <- .recompute_row_number(conn, k)
                    keycols[[1L]] <- .set_row_number(conn)
                } else {
                    for (kname in names(keycols)) {
                        kdnames <- pull(distinct(select(conn, !!as.name(kname))))
                        keycols[[kname]] <- keycols[[kname]][match(kdnames, keycols[[kname]])]
                    }
                }
            } else {
                stop("unsupported 'i' for row subsetting")
            }
        }
    }

    replaceSlots(x, conn = conn, datacols = datacols, keycols = keycols,
                 collevels = collevels, ..., check = FALSE)
}

#' @export
setMethod("[", "DuckDBTable", .subset_DuckDBTable)

#' @export
#' @importFrom S4Vectors extractROWS
#' @importFrom stats setNames
setMethod("extractROWS", "DuckDBTable", function(x, i) {
    if (missing(i)) {
        return(x)
    }
    i <- setNames(list(i), names(x@keycols))
    .subset_DuckDBTable(x, i = i)
})

#' @export
#' @importFrom stats setNames
#' @importFrom S4Vectors extractCOLS mcols normalizeSingleBracketSubscript
setMethod("extractCOLS", "DuckDBTable", function(x, i) {
    if (missing(i)) {
        return(x)
    }
    xstub <- setNames(seq_along(x), names(x))
    i <- normalizeSingleBracketSubscript(i, xstub)
    if (anyDuplicated(i)) {
        stop("cannot extract duplicate columns in a DuckDBDataFrame")
    }
    mc <- extractROWS(mcols(x), i)
    .subset_DuckDBTable(x, j = i, elementMetadata = mc)
})

.head_conn <- function(x, n) {
    conn <- head(x@conn, n)
    keycols <- x@keycols
    keycols[[1L]] <- .set_row_number(conn)
    replaceSlots(x, conn = conn, keycols = keycols, check = FALSE)
}

#' @export
#' @importFrom S4Vectors head isSingleNumber
setMethod("head", "DuckDBTable", function(x, n = 6L, ...) {
    if (!isSingleNumber(n)) {
        stop("'n' must be a single number")
    }
    if (.has_row_number(x)) {
        return(.head_conn(x, n))
    }
    n <- as.integer(n)
    nr <- nrow(x)
    if (n < 0) {
        n <- max(0L, nr + n)
    }
    if (n > nr) {
        x
    } else {
        extractROWS(x, seq_len(n))
    }
})

#' @export
#' @importFrom S4Vectors isSingleNumber tail
setMethod("tail", "DuckDBTable", function(x, n = 6L, ...) {
    if (!isSingleNumber(n)) {
        stop("'n' must be a single number")
    }
    if ((n > 0L) && .has_row_number(x)) {
        stop("tail requires a keycols to be efficient")
    }
    n <- as.integer(n)
    nr <- nrow(x)
    if (n < 0) {
        n <- max(0L, nr + n)
    }
    if (n > nr) {
        x
    } else {
        extractROWS(x, (nr + 1L) - rev(seq_len(n)))
    }
})

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Binding
###

#' @export
#' @importFrom S4Vectors classNameForDisplay bindROWS
setMethod("bindROWS", "DuckDBTable",
function(x, objects = list(), use.names = TRUE, ignore.mcols = FALSE, check = TRUE) {
    stop(sprintf("binding rows to a %s is not supported", classNameForDisplay(x)))
})

#' @export
#' @importFrom S4Vectors bindCOLS
setMethod("bindCOLS", "DuckDBTable",
function(x, objects = list(), use.names = TRUE, ignore.mcols = FALSE, check = TRUE) {
    datacols <- x@datacols
    sources <- list(x)

    for (i in seq_along(objects)) {
        obj <- objects[[i]]
        if (!is(obj, "DuckDBTable")) {
            stop("all objects must be of class 'DuckDBTable'")
        }
        if (!isTRUE(all.equal(x, obj))) {
            stop("all objects must share a compatible 'DuckDBTable' structure")
        }
        newname <- names(objects)[i]
        if (!is.null(newname) && nzchar(newname)) {
            if (ncol(obj) > 1L) {
                colnames(obj) <- paste(newname, colnames(obj), sep = "_")
            }
            colnames(obj) <- newname
        }
        datacols <- c(datacols, obj@datacols)
        sources <- c(sources, list(obj))
    }
    names(datacols) <- make.unique(names(datacols), sep = "_")

    # Re-key factor levels onto the final (uniquified) names, positionally so
    # duplicate source names are handled correctly.
    pos_levels <- unlist(lapply(sources, function(s) {
        lapply(names(s@datacols), function(nm) s@collevels[[nm]])
    }), recursive = FALSE)
    names(pos_levels) <- names(datacols)
    collevels <- pos_levels[!vapply(pos_levels, is.null, logical(1L))]

    replaceSlots(x, datacols = datacols, collevels = collevels, check = FALSE)
})

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Coercion
###

#' @export
setMethod("as.data.frame", "DuckDBTable",
function(x, row.names = NULL, optional = FALSE, ..., limit.rows = TRUE) {
    datacols <- as.list(x@datacols)
    if (length(x@conn) == 0L) {
        df <- lapply(datacols, function(j) NULL)
        class(df) <- "data.frame"
        attr(df, "row.names") <- integer()
    } else {
        conn <- tblconn(x)

        if (limit.rows) {
            n <- as.integer(min(nrow(x), .Machine$integer.max))
            conn <- head(conn, n = n)
        }

        df <- as.data.frame(conn, optional = TRUE)
    }

    df
})

#' @export
#' @importFrom S4Vectors as.env
setMethod("as.env", "DuckDBTable",
function(x, enclos = parent.frame(2), tform = identity) {
    S4Vectors:::makeEnvForNames(x, colnames(x), enclos, tform)
})

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Display
###

#' @export
#' @importFrom S4Vectors classNameForDisplay
setMethod("show", "DuckDBTable", function(object) {
    if (nkey(object) == 0L) {
        cat(sprintf("%s object\n", classNameForDisplay(object)))
    } else {
        cat(sprintf("%s object with key (%s)\n",
                    classNameForDisplay(object),
                    paste(keynames(object), collapse = ", ")))
    }
    if (length(object@conn) > 0L) {
        print(object@conn)
        expr <- deparse(object@datacols,
                        width.cutoff = getOption("width", 60L) - 6L)
        expr <- sub("^[ \t\r\n]+", "      ", sub("\\)", "",
                    sub("^expression\\(", "", expr)))
        cat(sprintf("cols: %s\n", paste(expr, collapse = "\n")))
    }
    invisible(NULL)
})
