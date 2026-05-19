#' Parquet append validation for the DuckDB package suite
#'
#' Low-level guards for incremental Parquet writes used by
#' \pkg{BiocDuckDB} and \pkg{DuckDBArray}. End users should call
#' \code{\link[BiocDuckDB]{writeParquet}} or
#' \code{\link[DuckDBArray]{writeCoordArray}} rather than these functions
#' directly.
#'
#' @param offset Non-negative integer scalar; global index shift for flat
#'   table append (\code{\link{validateAppendOffset}}).
#' @param path Directory containing Parquet files or hive partitions.
#' @param columns Character vector of column names required in an existing
#'   dataset schema.
#' @param arrowtypes Named list of \code{\link[arrow]{DataType}} objects
#'   (names must match \code{columns}). \code{NULL} elements adopt the on-disk
#'   type; non-\code{NULL} elements must match the existing type exactly
#'   (\code{\link{reconcileParquetSchema}}).
#' @param indexcols Character vector of index column names for hive layout.
#' @param grid_suffix Partition directory suffix (e.g. \code{"group__"}).
#' @param grid \link[S4Arrays]{ArrayGrid} for the current write slab.
#' @param along Integer index of the append dimension along which
#'   \code{group_offset} applies.
#' @param group_offset Partition-group offset along \code{along} for hive
#'   append.
#' @param part Non-negative integer; flat \code{part-<n>.parquet} index.
#' @param part_digits Zero-padding width for \code{part} in the filename.
#'
#' @return
#' \describe{
#'   \item{\code{validateAppendOffset}}{Integer scalar.}
#'   \item{\code{readParquetSchema}}{\code{\link[arrow]{Schema}} object.}
#'   \item{\code{reconcileParquetSchema}}{Named list of resolved
#'     \code{DataType} objects.}
#'   \item{\code{checkHiveAppendPartitions}, \code{checkAppendPart}}{
#'     \code{NULL}, invisibly.}
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
    if (!isSingleNumber(part) || part != as.integer(part) || part < 0L) {
        stop("'part' must be a single non-negative integer")
    }
    fmt <- if (part_digits > 0L) {
        paste0("part-%0", as.integer(part_digits), "d.parquet")
    } else {
        "part-%d.parquet"
    }
    target <- file.path(path, sprintf(fmt, as.integer(part)))
    if (file.exists(target)) {
        stop("target file already exists: ", target,
             " (refusing to overwrite; choose a different 'part')")
    }
    invisible(NULL)
}
