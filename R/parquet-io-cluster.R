### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Cluster-on-write: order rows by a clustering key so row-group zonemaps prune
###
### `writeParquet(x, path, cluster_by = ...)` physically orders the written rows
### by a clustering key so each Parquet row group's per-column min/max (zonemap)
### is tight and DuckDB prunes groups that cannot match a range predicate. The
### key is one of:
###   * a character vector of columns  -> lexicographic ORDER BY (the 1-D case;
###     what the writer already did for `__index__`), or
###   * `zorder(cols)`  -> a Morton (Z-order) space-filling code over N numeric
###     columns, lowered to a generated bit-interleave SQL expression (N-D,
###     needs no extension), or
###   * `hilbert(cols)` -> the native DuckDB `spatial` `ST_Hilbert` (2-D only,
###     better locality, requires the spatial extension).
### Both space-filling curves compute per-column extents with one cheap
### `MIN/MAX` scan and bake them into a pushed-down `ORDER BY` expression -- no
### full materialization. A single physical order clusters ONE key: supplying
### `cluster_by` overrides the default `__index__` ordering (you optimize the
### queries you cluster for).

#' Cluster-on-write keys and helpers
#'
#' Clustering keys for \code{\link[BiocDuckDB]{writeParquet}}'s
#' \code{cluster_by} argument, plus the in-memory reorder they imply. Writing
#' with a clustering key physically orders rows so each Parquet row group covers
#' a tight region, letting DuckDB's row-group zonemaps prune groups outside a
#' range query.
#'
#' \code{zorder()} orders by a Morton (Z-order) code over \code{cols} (any
#' number of numeric columns), lowered SQL-side to a generated bit-interleave
#' \code{ORDER BY} (no extension needed). \code{hilbert()} orders by the native
#' DuckDB \code{spatial} \code{ST_Hilbert} curve (exactly two numeric columns,
#' better locality, requires the spatial extension). A plain character vector is
#' a lexicographic ordering (best for the leading column). \code{clusterSort()}
#' is the in-memory counterpart used by the materializing \code{data.frame} /
#' \code{DataFrame} write path (Hilbert falls back to Morton there). Its
#' double-precision Morton code is exact only for
#' \code{length(cols) * bits <= 52}; the lazy SQL path (unsigned 64-bit) is
#' exact to 62, so for a total above 52 bits the two write paths may order rows
#' differently. Keep \code{length(cols) * bits} at or below 52 when both paths
#' must agree byte-for-byte.
#'
#' \code{by} adds a \emph{composite} key: the named (typically low-cardinality
#' categorical) columns are ordered lexicographically \emph{before} the
#' space-filling curve, i.e. \code{ORDER BY by..., curve(cols)}. This keeps each
#' \code{by}-group's rows contiguous so the group's own zonemaps / run-length
#' encoding stay tight (e.g. \code{zorder(c("x","y"), by = "gene")} for a
#' viewport+gene workload, or \code{zorder(c("x","y"), by = "__sample__")} to
#' keep a COO assay's sample-slice pruning). The prefix columns are \strong{not}
#' interleaved into the Morton code, so they cost none of the \code{bits}
#' budget.
#'
#' @param cols Character vector of numeric column names to cluster by.
#'   \code{hilbert()} requires exactly two.
#' @param bits Grid resolution per axis (default 16; a \eqn{2^{16}} grid).
#'   Higher = finer; keep \code{length(cols) * bits <= 62} so the Morton code
#'   fits a 64-bit integer.
#' @param by Optional character vector of columns ordered lexicographically
#'   before the curve (a composite categorical-prefix key); \code{NULL} for a
#'   pure space-filling key.
#' @param df A \code{data.frame} or \link[S4Vectors:DataFrame]{DataFrame}
#'   (\code{clusterSort}).
#' @param cluster_by A \code{zorder()}/\code{hilbert()} spec or a character
#'   vector of columns (\code{clusterSort}).
#'
#' @return
#' \describe{
#'   \item{\code{zorder}, \code{hilbert}}{A \code{DuckDBClusterSpec} for
#'     \code{writeParquet(cluster_by=)}.}
#'   \item{\code{clusterSort}}{\code{df} reordered by the clustering key (same
#'     class, same columns); a no-op when \code{cluster_by} is \code{NULL},
#'     \code{df} is empty, or a key column is absent.}
#' }
#'
#' @examples
#' zorder(c("x", "y"))
#' hilbert(c("x", "y"), bits = 12L)
#' clusterSort(data.frame(x = c(9, 1, 5), y = c(9, 1, 5)), zorder(c("x", "y")))
#'
#' @name parquet-io-cluster
NULL

#' @rdname parquet-io-cluster
#' @export
zorder <- function(cols, bits = 16L, by = NULL) .clusterSpec("zorder", cols, bits, by)

#' @rdname parquet-io-cluster
#' @export
hilbert <- function(cols, bits = 16L, by = NULL) .clusterSpec("hilbert", cols, bits, by)

.clusterSpec <- function(curve, cols, bits, prefix = NULL) {
    cols <- as.character(cols)
    if (length(cols) < 1L || anyNA(cols) || !all(nzchar(cols)))
        stop("'cols' must name at least one column")
    if (identical(curve, "hilbert") && length(cols) != 2L)
        stop("hilbert() clustering requires exactly two columns (ST_Hilbert is 2-D); ",
             "use zorder() for other dimensionalities")
    bits <- as.integer(bits)
    if (length(bits) != 1L || is.na(bits) || bits < 1L || bits > 20L)
        stop("'bits' must be a single integer in 1:20")
    if (length(cols) * bits > 62L)
        stop("length(cols) * bits must be <= 62 so the Morton code fits a 64-bit integer")
    prefix <- if (is.null(prefix)) character(0L) else as.character(prefix)
    if (anyNA(prefix) || !all(nzchar(prefix)))
        stop("'by' must name existing columns")
    structure(list(curve = curve, cols = cols, bits = bits, prefix = prefix),
              class = "DuckDBClusterSpec")
}

# The prefix (categorical/key columns ordered lexicographically before the
# space-filling curve); character(0) for none.
.clusterPrefix <- function(spec) {
    if (is.null(spec$prefix)) character(0L) else spec$prefix
}

# Normalize a user `cluster_by` into a spec: NULL passes through; a character /
# list is a lexicographic key; a DuckDBClusterSpec is returned as-is.
.asClusterSpec <- function(cluster_by) {
    if (is.null(cluster_by))
        return(NULL)
    if (inherits(cluster_by, "DuckDBClusterSpec"))
        return(cluster_by)
    cols <- as.character(unlist(cluster_by, use.names = FALSE))
    if (!length(cols))
        return(NULL)
    structure(list(curve = "lexicographic", cols = cols, bits = NA_integer_,
                   prefix = character(0L)),
              class = "DuckDBClusterSpec")
}

# Per-column [min, max] extents over a subquery, one cheap scalar pass
# (SQL-side).
#' @importFrom DBI dbGetQuery dbQuoteIdentifier
.columnExtents <- function(conn, subquery_sql, cols) {
    sel <- vapply(seq_along(cols), function(i) {
        q <- as.character(dbQuoteIdentifier(conn, cols[i]))
        sprintf("MIN(%s) AS mn%d, MAX(%s) AS mx%d", q, i, q, i)
    }, character(1L))
    sql <- sprintf("SELECT %s FROM (%s) AS _ext",
                   paste(sel, collapse = ", "), subquery_sql)
    res <- dbGetQuery(conn, sql)
    lapply(seq_along(cols), function(i)
        c(min = as.numeric(res[[paste0("mn", i)]][1L]),
          max = as.numeric(res[[paste0("mx", i)]][1L])))
}

# SQL to quantize a column onto the integer grid [0, 2^bits) using baked
# extents. A degenerate (constant / non-finite) axis collapses to the constant
# 0.
.quantizeSQL <- function(qcol, vmin, vmax, bits) {
    span <- bitwShiftL(1L, bits) - 1L
    if (!is.finite(vmin) || !is.finite(vmax) || vmax <= vmin)
        return("CAST(0 AS UBIGINT)")
    sprintf(paste0("CAST(LEAST(GREATEST(FLOOR((%s - %.17g) / %.17g * %d), 0), %d) ",
                   "AS UBIGINT)"),
            qcol, vmin, vmax - vmin, span, span)
}

# Morton (Z-order) ORDER BY expression: interleave the low `bits` of each
# quantized axis (axis j's bit i lands at position n*i + j). Pure integer
# bit-ops; no extension needed.
.mortonOrderSQL <- function(conn, cols, extents, bits) {
    n <- length(cols)
    quant <- vapply(seq_len(n), function(j) {
        qcol <- as.character(dbQuoteIdentifier(conn, cols[j]))
        .quantizeSQL(qcol, extents[[j]]["min"], extents[[j]]["max"], bits)
    }, character(1L))
    terms <- character()
    for (i in seq_len(bits) - 1L) {
        for (j in seq_len(n)) {
            terms <- c(terms,
                       sprintf("(((%s >> %d) & CAST(1 AS UBIGINT)) << %d)",
                               quant[j], i, n * i + (j - 1L)))
        }
    }
    sprintf("(%s)", paste(terms, collapse = " + "))
}

# Hilbert ORDER BY expression via the native DuckDB spatial ST_Hilbert (2-D).
# Requires the spatial extension on the connection (loaded by DuckDBSpatial /
# configureExtensionAutoloading). ST_Hilbert(DOUBLE, DOUBLE, BOX_2D) needs a
# BOX_2D bounds, so the envelope is wrapped in ST_Extent (ST_MakeEnvelope
# returns a GEOMETRY).
.hilbertOrderSQL <- function(conn, cols, extents) {
    qx <- as.character(dbQuoteIdentifier(conn, cols[1L]))
    qy <- as.character(dbQuoteIdentifier(conn, cols[2L]))
    sprintf(paste0("ST_Hilbert(%s, %s, ",
                   "ST_Extent(ST_MakeEnvelope(%.17g, %.17g, %.17g, %.17g)))"),
            qx, qy,
            extents[[1L]]["min"], extents[[2L]]["min"],
            extents[[1L]]["max"], extents[[2L]]["max"])
}

# Lower a cluster spec + subquery into ORDER BY fragment(s) for
# buildParquetCopySQL(order_cols=). `available` is the subquery's output column
# names, for validation.
.clusterOrderSQL <- function(conn, subquery_sql, spec, available = NULL) {
    if (is.null(spec))
        return(NULL)
    prefix <- .clusterPrefix(spec)
    if (!is.null(available)) {
        miss <- setdiff(c(prefix, spec$cols), available)
        if (length(miss))
            stop("cluster_by column(s) not found in the table: ",
                 paste(miss, collapse = ", "))
    }
    if (identical(spec$curve, "lexicographic"))
        return(vapply(spec$cols,
                      function(c) as.character(dbQuoteIdentifier(conn, c)),
                      character(1L)))
    extents <- .columnExtents(conn, subquery_sql, spec$cols)
    if (identical(spec$curve, "zorder")) {
        curve_sql <- .mortonOrderSQL(conn, spec$cols, extents, spec$bits)
    } else {
        # Hilbert needs the DuckDB spatial extension (ST_Hilbert). Pre-check so a
        # missing extension gives a guided error rather than a raw catalog error.
        have <- tryCatch(
            nrow(DBI::dbGetQuery(conn, paste0("SELECT 1 FROM duckdb_functions() ",
                "WHERE function_name = 'ST_Hilbert' LIMIT 1"))) > 0L,
            error = function(e) FALSE)
        if (!have)
            stop("hilbert clustering requires the DuckDB spatial extension ",
                 "(ST_Hilbert); load it (e.g. via DuckDBSpatial) or use zorder()")
        curve_sql <- .hilbertOrderSQL(conn, spec$cols, extents)
    }
    # A `by` prefix orders lexicographically before the curve: ORDER BY cat...,
    # (curve). Prefix identifiers do not enter the Morton code, so they cost
    # none of the 62-bit budget.
    prefix_sql <- vapply(prefix,
                         function(c) as.character(dbQuoteIdentifier(conn, c)),
                         character(1L))
    c(prefix_sql, curve_sql)
}

#' @rdname parquet-io-cluster
#' @export
clusterSort <- function(df, cluster_by) {
    .clusterSortHost(df, .asClusterSpec(cluster_by))
}

# Host-side row reorder by a cluster spec, for the materializing (data.frame /
# DataFrame) write path that has no SQL ORDER BY. Morton only (offline, no
# connection); Hilbert falls back to Morton host-side. A no-op when the spec is
# NULL or a column is missing.
.clusterSortHost <- function(df, spec) {
    if (is.null(spec) || !nrow(df))
        return(df)
    prefix <- .clusterPrefix(spec)
    cols <- spec$cols
    if (!all(c(prefix, cols) %in% colnames(df)))
        return(df)
    if (identical(spec$curve, "lexicographic"))
        return(df[do.call(order, as.list(as.data.frame(df)[cols])), ,
                  drop = FALSE])
    code <- .mortonCodeHost(lapply(cols, function(c) as.numeric(df[[c]])),
                            if (is.na(spec$bits)) 16L else spec$bits)
    # order() sorts by the prefix columns first, then the Morton code within
    # each group -- the composite categorical-prefix + space-filling key.
    keys <- c(as.list(as.data.frame(df)[prefix]), list(code))
    df[do.call(order, keys), , drop = FALSE]
}

# Host-side N-D Morton code (double precision, exact for
# length(cols)*bits <= 52), mirroring the SQL generator so the two paths agree.
.mortonCodeHost <- function(col_list, bits = 16L) {
    n <- length(col_list)
    quant <- lapply(col_list, function(v) {
        finite <- v[is.finite(v)]
        if (!length(finite)) return(rep(0, length(v)))
        vmin <- min(finite); vmax <- max(finite)
        if (vmax <= vmin) return(rep(0, length(v)))
        v[!is.finite(v)] <- vmin
        floor(pmin(pmax((v - vmin) / (vmax - vmin) * (2^bits - 1), 0),
                   2^bits - 1))
    })
    code <- numeric(length(col_list[[1L]]))
    for (i in seq_len(bits) - 1L) {
        bit <- 2^i
        for (j in seq_len(n))
            code <- code + ((quant[[j]] %/% bit) %% 2) * (2^(n * i + (j - 1L)))
    }
    code
}
