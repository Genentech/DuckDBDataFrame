#' Parquet I/O utilities for the DuckDB package suite
#'
#' Shared append validation, SQL \code{COPY TO} helpers, and lazy
#' \linkS4class{DuckDBTable} export used by \pkg{BiocDuckDB} and
#' \pkg{DuckDBArray}. End users should call
#' \code{\link[BiocDuckDB]{writeParquet}} or
#' \code{\link[DuckDBArray]{writeCoordArray}} rather than these functions
#' directly.
#'
#' @param offset Non-negative integer scalar; global index shift for flat
#'   table append (\code{\link{validateAppendOffset}}).
#' @param path Directory containing Parquet files or hive partitions.
#' @param columns Character vector of column names required in an existing
#'   dataset schema.
#' @param arrowtypes Named list of \code{\link[arrow]{DataType}} objects or
#'   length-one character Arrow type names (names must match \code{columns}).
#'   \code{NULL} elements adopt the on-disk type; non-\code{NULL} elements must
#'   match the existing type exactly (\code{\link{reconcileParquetSchema}}).
#' @param indexcols Character vector of index column names for hive layout.
#' @param grid_suffix Partition directory suffix (e.g. \code{"group__"}).
#' @param grid \link[S4Arrays]{ArrayGrid} for the current write slab.
#' @param along Integer index of the append dimension along which
#'   \code{group_offset} applies.
#' @param group_offset Partition-group offset along \code{along} for hive
#'   append.
#' @param part Non-negative integer; flat \code{part-<n>.parquet} index.
#' @param part_digits Zero-padding width for \code{part} in the filename.
#' @param append Logical; enable flat multi-part append
#'   (\code{\link{setupFlatParquetWrite}}).
#' @param indexcol Optional index column name; when set, \code{offset} is
#'   validated in \code{\link{setupFlatParquetWrite}}.
#' @param reconcile_columns Character vector of columns to pin on append via
#'   \code{\link{reconcileParquetSchema}}.
#' @param create Logical; create \code{path} when missing
#'   (\code{\link{setupFlatParquetWrite}}).
#' @param conn DBI connection for \code{\link{quoteSQLColumns}}.
#' @param cols Character vector of column names to quote.
#' @param query_sql Inner \code{SELECT} (or \code{SELECT ... WHERE ...}) for
#'   \code{\link{buildParquetCopySQL}}.
#' @param target_path Destination file or directory path for
#'   \code{\link{buildParquetCopySQL}}.
#' @param order_cols Optional character vector of \code{ORDER BY} expressions
#'   (pre-quoted identifiers or SQL expressions).
#' @param partition_by Optional character vector of hive partition column names
#'   (pre-quoted identifiers) for \code{PARTITION_BY}.
#' @param row_group_size Optional integer \code{ROW_GROUP_SIZE} (coord arrays).
#' @param x A \linkS4class{DuckDBTable} object
#'   (\code{\link{writeDuckDBTableParquet}}).
#' @param indexcol Optional index column name for lazy table export.
#' @param keycol Optional primary-key column name for lazy table export.
#' @param dimtbl Optional single-row \linkS4class{DataFrame} of partition columns.
#'
#' @return
#' \describe{
#'   \item{\code{validateAppendOffset}}{Integer scalar.}
#'   \item{\code{readParquetSchema}}{\code{\link[arrow]{Schema}} object.}
#'   \item{\code{reconcileParquetSchema}}{Named list of resolved
#'     \code{DataType} objects.}
#'   \item{\code{checkHiveAppendPartitions}, \code{checkAppendPart}}{
#'     \code{NULL}, invisibly.}
#'   \item{\code{parquetPartPath}}{Character path to a \code{part-*.parquet} file.}
#'   \item{\code{validateWriteParquetPart}}{Integer scalar or \code{NULL}.}
#'   \item{\code{setupFlatParquetWrite}}{Named list with validated flat-write
#'     parameters (\code{path}, \code{part}, \code{offset}, \code{pq_path},
#'     \code{flat_part}, \code{subsequent_part}).}
#'   \item{\code{escapeSQLPath}}{Escaped path string.}
#'   \item{\code{quoteSQLColumns}}{Character vector of quoted identifiers.}
#'   \item{\code{buildParquetCopySQL}}{Complete \code{COPY TO} SQL string.}
#'   \item{\code{writeDuckDBTableParquet}}{List with \code{path}, \code{dir},
#'     \code{nrow}, \code{sample_df}, \code{colnames}, \code{part},
#'     \code{append}, and \code{subsequent_part}.}
#' }
#'
#' @details
#' These functions implement the shared append contract (fail before write,
#' no silent overwrite):
#' \itemize{
#'   \item Flat sample/feature tables use \code{part-*.parquet} files;
#'     \code{checkAppendPart} and \code{reconcileParquetSchema} apply.
#'   \item Hive-partitioned coord arrays use
#'     \code{<index><suffix>=<n>/} directories;
#'     \code{checkHiveAppendPartitions} guards partition collisions.
#'   \item \code{readParquetSchema} reads the first \code{*.parquet} file
#'     found under \code{path} (recursive search).
#' }
#'
#' @author Patrick Aboyoun
#'
#' @seealso
#' \code{\link[BiocDuckDB]{writeParquet}},
#' \code{\link[DuckDBArray]{writeCoordArray}}
#'
#' @aliases validateAppendOffset
#' @aliases readParquetSchema
#' @aliases reconcileParquetSchema
#' @aliases checkHiveAppendPartitions
#' @aliases checkAppendPart
#' @aliases parquetPartPath
#' @aliases validateWriteParquetPart
#' @aliases setupFlatParquetWrite
#' @aliases escapeSQLPath
#' @aliases quoteSQLColumns
#' @aliases buildParquetCopySQL
#' @aliases writeDuckDBTableParquet
#'
#' @examples
#' path <- tempfile()
#' dir.create(path)
#' on.exit(unlink(path, recursive = TRUE), add = TRUE)
#' pq <- file.path(path, "part-0.parquet")
#' arrow::write_parquet(data.frame(x = 1:3L, y = letters[1:3]), pq)
#' validateAppendOffset(0L)
#' readParquetSchema(path, columns = c("x", "y"))
#' tbl <- DuckDBTable(pq)
#' quoteSQLColumns(dbconn(tbl), c("x", "y"))
#'
#' @keywords internal
#'
#' @name parquet-io
NULL

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Validation
###

#' @export
#' @importFrom S4Vectors isSingleNumber
#' @rdname parquet-io
validateAppendOffset <- function(offset) {
    if (!isSingleNumber(offset) || offset != as.integer(offset) || offset < 0L) {
        stop("'offset' must be a single non-negative integer")
    }
    as.integer(offset)
}

#' @export
#' @importFrom arrow read_parquet schema
#' @rdname parquet-io
readParquetSchema <- function(path, columns = NULL) {
    files <- list.files(path, pattern = "\\.parquet$", recursive = TRUE,
                        full.names = TRUE)
    if (length(files) == 0L) {
        stop("'append = TRUE' but no parquet files found under ", path)
    }
    sch <- schema(read_parquet(files[1L], as_data_frame = FALSE))
    if (!is.null(columns)) {
        missing_fields <- setdiff(columns, names(sch))
        if (length(missing_fields) > 0L) {
            stop("schema mismatch: dataset at ", path, " lacks field(s) ",
                 paste(vapply(missing_fields, shQuote, character(1L)),
                       collapse = ", "))
        }
    }
    sch
}

#' @export
#' @rdname parquet-io
reconcileParquetSchema <- function(path, columns, arrowtypes) {
    sch <- readParquetSchema(path, columns = columns)
    resolved <- vector("list", length(columns))
    names(resolved) <- columns
    for (nm in columns) {
        existing <- sch$GetFieldByName(nm)$type
        arrow_type <- arrowtypes[[nm]]
        if (is.null(arrow_type)) {
            resolved[[nm]] <- existing
        } else if (is.character(arrow_type)) {
            if (!identical(arrow_type, existing$ToString())) {
                stop("append schema mismatch on '", nm,
                     "': existing type is ", existing$ToString(),
                     ", supplied type is ", arrow_type)
            }
            resolved[[nm]] <- existing
        } else if (!arrow_type$Equals(existing)) {
            stop("append schema mismatch on '", nm,
                 "': existing type is ", existing$ToString(),
                 ", supplied type is ", arrow_type$ToString())
        } else {
            resolved[[nm]] <- arrow_type
        }
    }
    resolved
}

#' @export
#' @rdname parquet-io
checkHiveAppendPartitions <-
function(path, indexcols, grid_suffix, grid, along, group_offset)
{
    ndim <- length(indexcols)
    dim_grid <- dim(grid)
    pfx1 <- paste0(indexcols[1L], grid_suffix, "=")

    top <- list.files(path, all.files = FALSE, full.names = FALSE,
                      no.. = TRUE)
    top_dirs <- list.dirs(path, full.names = FALSE, recursive = FALSE)
    loose <- setdiff(top, top_dirs)
    bad_dirs <- top_dirs[!startsWith(top_dirs, pfx1)]
    if (length(loose) > 0L || length(bad_dirs) > 0L) {
        stop("'append = TRUE' requires a hive-partitioned dataset at ",
             path, " (expected subdirectories '", pfx1,
             "<n>'); found unexpected entries: ",
             paste(c(loose, bad_dirs), collapse = ", "))
    }

    groups <- lapply(seq_len(ndim), function(k) seq_len(dim_grid[k]))
    groups[[along]] <- group_offset + seq_len(dim_grid[along])
    cells <- do.call(expand.grid,
                     c(groups, list(KEEP.OUT.ATTRS = FALSE)))
    for (i in seq_len(nrow(cells))) {
        cell <- as.integer(cells[i, ])
        parts <- paste0(indexcols, grid_suffix, "=", cell)
        target <- do.call(file.path, c(list(path), as.list(parts)))
        if (dir.exists(target)) {
            stop("'append = TRUE' would write into an existing partition: ",
                 target,
                 " (check 'group_offset' -- it must skip past every ",
                 "previously-written partition along dimension ", along,
                 ")")
        }
    }
    invisible(NULL)
}

#' @export
#' @importFrom S4Vectors isSingleNumber
#' @rdname parquet-io
checkAppendPart <- function(path, part, part_digits = 0L) {
    part <- validateWriteParquetPart(part)
    target <- parquetPartPath(path, part, part_digits)
    if (file.exists(target)) {
        stop("target file already exists: ", target,
             " (refusing to overwrite; choose a different 'part')")
    }
    invisible(NULL)
}

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Flat table paths and setup
###
### Mirrors the writeCoordArray preamble (.validateAppend / .setupCoordWrite)
### for part-*.parquet flat layout used by writeParquet and
### writeDuckDBTableParquet.
###

#' @export
#' @importFrom S4Vectors isSingleNumber
#' @rdname parquet-io
parquetPartPath <- function(path, part, part_digits = 0L) {
    part <- validateWriteParquetPart(part)
    fmt <- if (part_digits > 0L) {
        paste0("part-%0", as.integer(part_digits), "d.parquet")
    } else {
        "part-%d.parquet"
    }
    file.path(path, sprintf(fmt, as.integer(part)))
}

#' @export
#' @importFrom S4Vectors isSingleNumber
#' @rdname parquet-io
validateWriteParquetPart <- function(part) {
    if (is.null(part)) {
        return(NULL)
    }
    if (!isSingleNumber(part) || part != as.integer(part) || part < 0L) {
        stop("'part' must be NULL or a single non-negative integer")
    }
    as.integer(part)
}

#' @export
#' @importFrom S4Vectors isTRUEorFALSE
#' @rdname parquet-io
setupFlatParquetWrite <-
function(path, append = FALSE, offset = 0L, part = NULL, part_digits = 0L,
         indexcol = NULL, reconcile_columns = NULL, create = TRUE)
{
    if (!isTRUEorFALSE(append)) {
        stop("'append' must be TRUE or FALSE")
    }
    if (create && !dir.exists(path)) {
        dir.create(path, recursive = TRUE)
    }

    part <- validateWriteParquetPart(part)
    if (isTRUE(append) && is.null(part)) {
        stop("'append = TRUE' requires 'part'")
    }
    if (!is.null(part) && isTRUE(append)) {
        checkAppendPart(path, part, part_digits)
    }

    flat_part <- !is.null(part)
    if (!flat_part && !isTRUE(append)) {
        part <- 0L
        flat_part <- TRUE
    }

    if (!is.null(indexcol)) {
        offset <- validateAppendOffset(offset)
    } else {
        offset <- as.integer(offset)
    }

    if (isTRUE(append) && length(reconcile_columns)) {
        reconcileParquetSchema(
            path, reconcile_columns,
            setNames(rep(list(NULL), length(reconcile_columns)), reconcile_columns)
        )
    }

    list(path = path,
         part = part,
         part_digits = part_digits,
         offset = offset,
         pq_path = parquetPartPath(path, part, part_digits),
         flat_part = flat_part,
         subsequent_part = isTRUE(append) && !is.null(part) && as.integer(part) > 0L)
}

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Shared SQL utilities
###
### Used by writeDuckDBTableParquet (flat) and DuckDBArray writeCoordArray
### (hive PARTITION_BY) for consistent COPY TO defaults.
###

#' @export
#' @rdname parquet-io
escapeSQLPath <- function(path) {
    gsub("'", "''", path, fixed = TRUE)
}

#' @export
#' @importFrom DBI dbQuoteIdentifier
#' @rdname parquet-io
quoteSQLColumns <- function(conn, cols) {
    vapply(cols, function(col) {
        as.character(dbQuoteIdentifier(conn, col))
    }, character(1L), USE.NAMES = FALSE)
}

#' @export
#' @importFrom S4Vectors isSingleNumber
#' @rdname parquet-io
buildParquetCopySQL <-
function(query_sql, target_path, order_cols = NULL, partition_by = NULL,
         row_group_size = NULL)
{
    order_clause <- if (!is.null(order_cols) && length(order_cols) > 0L) {
        sprintf(" ORDER BY %s", paste(order_cols, collapse = ", "))
    } else {
        ""
    }

    options <- c("FORMAT PARQUET", "COMPRESSION zstd", "COMPRESSION_LEVEL 3")
    if (!is.null(row_group_size)) {
        if (!isSingleNumber(row_group_size) ||
            row_group_size != as.integer(row_group_size) ||
            row_group_size <= 0L) {
            stop("'row_group_size' must be a single positive integer")
        }
        options <- c(options, sprintf("ROW_GROUP_SIZE %d", as.integer(row_group_size)))
    }
    if (!is.null(partition_by) && length(partition_by) > 0L) {
        options <- c(options,
                     sprintf("PARTITION_BY (%s)", paste(partition_by, collapse = ", ")))
    }

    sprintf(
        "COPY (%s%s) TO '%s' (%s)",
        query_sql, order_clause, escapeSQLPath(target_path),
        paste(options, collapse = ", "))
}

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Lazy flat table export
###
### SQL COPY TO for DuckDBTable objects; preflight via setupFlatParquetWrite.
###

.tableKeycolName <- function(x, keycol) {
    if (is.null(keycol))
        return(NULL)
    kcols <- keynames(x)
    cols <- unique(c(colnames(x), kcols))
    if (keycol %in% cols)
        return(keycol)
    if (length(kcols) == 1L && kcols %in% cols)
        return(kcols)
    if (is(x, "DuckDBDataFrame")) {
        rnms <- rownames(x)
        if (!is.integer(rnms) && length(rnms) > 0L && length(kcols) == 1L)
            return(kcols)
    }
    NULL
}

.dimtblSelectParts <- function(conn, dimtbl) {
    if (is.null(dimtbl) || ncol(dimtbl) == 0L)
        return(character())
    if (nrow(dimtbl) != 1L)
        stop("'dimtbl' must have exactly one row for lazy table export")
    vapply(seq_len(ncol(dimtbl)), function(j) {
        nm <- colnames(dimtbl)[j]
        val <- dimtbl[[j]][1L]
        qnm <- as.character(dbQuoteIdentifier(conn, nm))
        if (is.character(val)) {
            sprintf("'%s' AS %s", gsub("'", "''", val, fixed = TRUE), qnm)
        } else if (is.numeric(val) && length(val) == 1L) {
            sprintf("%s AS %s", val, qnm)
        } else if (is.logical(val) && length(val) == 1L) {
            sprintf("%s AS %s", if (isTRUE(val)) "TRUE" else "FALSE", qnm)
        } else {
            stop("unsupported 'dimtbl' column type for column '", nm, "'")
        }
    }, character(1L))
}

#' @importFrom dbplyr sql_render
#' @importFrom DBI dbQuoteIdentifier
buildTableSelectSQL <-
function(x, indexcol = NULL, keycol = NULL, dimtbl = NULL, offset = 0L,
         conn = dbconn(x))
{
    if (!inherits(x, "DuckDBTable"))
        stop("'x' must be a DuckDBTable")
    tbl_q <- sql_render(tblconn(x, select = FALSE))
    data_cols <- colnames(x)
    kcols <- keynames(x)
    table_cols <- unique(c(data_cols, setdiff(kcols, data_cols)))

    select_parts <- character()
    output_names <- character()

    if (!is.null(indexcol)) {
        qidx <- as.character(dbQuoteIdentifier(conn, indexcol))
        select_parts <- c(select_parts,
                          sprintf("(%d + row_number() OVER (ORDER BY (SELECT 1))) AS %s",
                                  as.integer(offset), qidx))
        output_names <- c(output_names, indexcol)
    }

    key_src <- .tableKeycolName(x, keycol)
    if (!is.null(keycol) && !is.null(key_src)) {
        qsrc <- as.character(dbQuoteIdentifier(conn, key_src))
        qdst <- as.character(dbQuoteIdentifier(conn, keycol))
        if (identical(key_src, keycol)) {
            select_parts <- c(select_parts, sprintf("t.%s", qsrc))
        } else {
            select_parts <- c(select_parts, sprintf("t.%s AS %s", qsrc, qdst))
        }
        output_names <- c(output_names, keycol)
    }

    select_parts <- c(select_parts, .dimtblSelectParts(conn, dimtbl))
    if (!is.null(dimtbl) && ncol(dimtbl) > 0L)
        output_names <- c(output_names, colnames(dimtbl))

    reserved <- unique(c(output_names, if (!is.null(indexcol)) indexcol,
                         if (!is.null(keycol)) keycol,
                         if (!is.null(key_src)) key_src))
    for (col in table_cols) {
        if (col %in% reserved)
            next
        qcol <- as.character(dbQuoteIdentifier(conn, col))
        select_parts <- c(select_parts, sprintf("t.%s", qcol))
        output_names <- c(output_names, col)
    }

    output_names <- make.unique(output_names, sep = "_")
    if (length(select_parts) != length(output_names))
        stop("internal problem building table SELECT")

    for (i in seq_along(select_parts)) {
        if (!grepl(" AS ", select_parts[i], fixed = TRUE)) {
            qout <- as.character(dbQuoteIdentifier(conn, output_names[i]))
            select_parts[i] <- sprintf("%s AS %s", select_parts[i], qout)
        }
    }

    list(
        sql = sprintf("SELECT %s FROM (%s) t",
                      paste(select_parts, collapse = ", "), tbl_q),
        colnames = output_names,
        order_col = if (!is.null(indexcol)) {
            as.character(dbQuoteIdentifier(conn, indexcol))
        } else {
            NULL
        }
    )
}

#' @describeIn parquet-io Lazy DuckDBTable SQL Parquet export.
#' @export
#' @importFrom DBI dbExecute
#' @importFrom arrow read_parquet
writeDuckDBTableParquet <-
function(x, path, indexcol = "__index__", keycol = "__name__", dimtbl = NULL,
         append = FALSE, offset = 0L, part = NULL, part_digits = 0L, ...)
{
    if (!inherits(x, "DuckDBTable"))
        stop("'x' must be a DuckDBTable")

    prep <- setupFlatParquetWrite(
        path, append = append, offset = offset, part = part,
        part_digits = part_digits, indexcol = indexcol,
        reconcile_columns = if (isTRUE(append) && !is.null(indexcol)) indexcol,
        create = TRUE)

    conn <- dbconn(x)
    built <- buildTableSelectSQL(x, indexcol = indexcol, keycol = keycol,
                                 dimtbl = dimtbl, offset = prep$offset,
                                 conn = conn)
    order_cols <- if (!is.null(built$order_col) && nzchar(built$order_col)) {
        built$order_col
    } else {
        NULL
    }
    copy_sql <- buildParquetCopySQL(built$sql, prep$pq_path, order_cols = order_cols)
    DBI::dbExecute(conn, copy_sql)

    n <- nrow(x)
    sample_n <- min(100L, max(1L, n))
    sample_df <- as.data.frame(arrow::read_parquet(prep$pq_path))
    if (nrow(sample_df) > sample_n)
        sample_df <- sample_df[seq_len(sample_n), , drop = FALSE]

    list(path = prep$pq_path,
         dir = prep$path,
         nrow = n,
         sample_df = sample_df,
         colnames = built$colnames,
         part = prep$part,
         append = append,
         subsequent_part = prep$subsequent_part)
}
