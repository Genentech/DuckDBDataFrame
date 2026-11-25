### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Errors at the boundaries of DuckDB
###
### A query that fails in DuckDB comes back as a stack of messages from dbplyr,
### duckdb and rlang that holds the SQL, which can be a screen long and has the
### cause on one line of it. The helpers here turn that into one classed
### condition whose message is the cause, and keep the original in 'parent'.
###

.duckdbErrorSummary <- function(e) {
    lines <- strsplit(conditionMessage(e), "\n", fixed = TRUE)[[1L]]
    lines <- lines[nzchar(trimws(lines))]
    cause <- grep("^! ", lines, value = TRUE)
    short <- if (length(cause)) sub("^! ", "", cause[length(cause)]) else lines[1L]
    type <- sub("^.*Error type: ([A-Z_]+).*$", "\\1",
                grep("Error type: ", lines, value = TRUE)[1L])
    list(message = short, type = if (is.na(type) || !nzchar(type)) NULL else tolower(type))
}

# Run 'expr', and turn an error of DuckDB into a condition of class
# "duckdbdataframe_error" (and "duckdb_<type>", as "duckdb_out_of_range") that
# says what was being done and why it failed, without the query. Errors of R
# that are not from DuckDB, and the conditions of this package, pass through.
.withDuckDBError <- function(expr, action) {
    withCallingHandlers(
        expr,
        error = function(e) {
            if (inherits(e, "duckdbdataframe_error") ||
                inherits(e, "duckdbdataframe_too_large"))
                return()
            text <- paste(conditionMessage(e), paste(class(e), collapse = " "))
            if (!grepl("duckdb|dbplyr|Failed to collect|Error type:|Binder Error|Conversion Error|Out of Range|Invalid Input|Catalog Error|Parser Error|IO Error|Out of Memory",
                       text))
                return()
            s <- .duckdbErrorSummary(e)
            cond <- structure(
                class = c("duckdbdataframe_error",
                          if (!is.null(s$type)) paste0("duckdb_", s$type),
                          "error", "condition"),
                list(message = sprintf("DuckDB could not %s: %s", action, s$message),
                     call = NULL, parent = e))
            stop(cond)
        })
}

# The number of values that a collection of 'n' rows of 'x' holds is checked
# against a limit, so that an object that does not fit in memory is refused
# with a message and not by the operating system. The limit is a number of
# values, 5e8 (4 GB of doubles) unless options(DuckDBDataFrame.max_cells) says
# otherwise, and Inf turns the check off.
.checkCollectSize <- function(x, n) {
    limit <- getOption("DuckDBDataFrame.max_cells", 5e8)
    if (!is.numeric(limit) || length(limit) != 1L || is.na(limit))
        stop("option 'DuckDBDataFrame.max_cells' must be a single number")
    cells <- as.numeric(n) * (length(x@datacols) + length(x@keycols))
    if (cells > limit) {
        stop(structure(
            class = c("duckdbdataframe_too_large", "error", "condition"),
            list(message = sprintf(
                paste0("collecting %s rows of %d columns would put %s values in memory, ",
                       "about %.1f GB, and the limit is %s. Select fewer rows or columns, ",
                       "compute in DuckDB (an aggregate, or head()), or raise the limit with ",
                       "options(DuckDBDataFrame.max_cells = ...)."),
                format(n, big.mark = ",", scientific = FALSE),
                length(x@datacols) + length(x@keycols),
                format(cells, big.mark = ",", scientific = FALSE),
                cells * 8 / 2^30,
                format(limit, big.mark = ",", scientific = FALSE)),
                call = NULL)))
    }
    invisible(x)
}
