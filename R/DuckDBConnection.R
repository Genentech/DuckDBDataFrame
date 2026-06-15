.duckdb <- new.env()
.duckdb$drv <- NULL

#' @importFrom DBI dbDisconnect
reg.finalizer(.duckdb, function(env) {
    releaseDuckDBConn()
}, onexit = TRUE)

#' Acquire and Release the DuckDB Connection
#'
#' Acquire and Release the DuckDB connection used by the
#' \pkg{BiocDuckDB} package.
#'
#' @param conn A \code{duckdb_connection} object.
#'
#' @return
#' \code{acquireDuckDBConn} returns a cached \code{duckdb_connection} object.
#' \code{releaseDuckDBConn} returns \code{NULL}, invisibly.
#'
#' @author Patrick Aboyoun
#'
#' @details
#' \code{acquireDuckDBConn} will add a \code{duckdb_connection} object to
#' the \pkg{BiocDuckDB} package cache.
#' \code{releaseDuckDBConn} will remove the \code{duckdb_connection} object
#' from that cache.
#'
#' @examples
#' releaseDuckDBConn()
#' conn <- acquireDuckDBConn()
#' identical(conn, acquireDuckDBConn())
#' releaseDuckDBConn()
#' releaseDuckDBConn()
#'
#' @aliases acquireDuckDBConn
#' @aliases releaseDuckDBConn
#'
#' @keywords IO
#'
#' @name DuckDBConnection
NULL

#' @importFrom DBI dbExecute dbGetQuery
loadExtension <- function(conn, extension, optional = FALSE) {
    qry <-
      sprintf("SELECT * FROM duckdb_extensions() WHERE extension_name = '%s';",
              extension)
    tbl <- dbGetQuery(conn, qry)
    if (nrow(tbl) == 0L) {
        stop(sprintf("Extension '%s' not found in DuckDB.", extension))
    }
    if (!tbl[["installed"]]) {
        tryCatch({
            dbExecute(conn, sprintf("INSTALL '%s';", extension))
        }, error = function(e) {
            err_msg <- conditionMessage(e)
            if (grepl("SSL|certificate|TLS", err_msg, ignore.case = TRUE)) {
                if (optional) {
                    warning(sprintf(
                        "Could not install optional '%s' extension due to SSL certificate issues.\n",
                        "Some functionality may be limited.\n",
                        "To fix: manually download from http://extensions.duckdb.org"
                    ), extension, call. = FALSE)
                    return(invisible(0L))
                } else {
                    stop(sprintf(
                        paste0(
                            "Failed to install '%s' extension due to SSL certificate error.\n\n",
                            "To fix: manually download the extension from http://extensions.duckdb.org\n",
                            "and place it in the DuckDB extensions directory.\n\n",
                            "Original error: %s"
                        ),
                        extension, err_msg
                    ), call. = FALSE)
                }
            } else {
                stop(e)
            }
        })
    }
    status <- 0L
    tbl_final <- dbGetQuery(conn, qry)
    if (!tbl_final[["loaded"]]) {
        status <- dbExecute(conn, sprintf("LOAD '%s';", extension))
    }
    invisible(status)
}

#' @export
#' @importFrom DBI dbConnect
#' @importFrom duckdb duckdb
#' @rdname DuckDBConnection
acquireDuckDBConn <- function(conn = dbConnect(duckdb(), bigint = "integer64", array = "matrix")) {
    if (is.null(.duckdb$drv)) {
        if (!inherits(conn, "duckdb_connection")) {
            stop("'conn' must be a DuckDB connection")
        }
        loadExtension(conn, "httpfs", optional = FALSE)
        loadExtension(conn, "spatial", optional = TRUE)
        .duckdb$drv <- conn
    }
    .duckdb$drv
}

#' @export
#' @importFrom DBI dbDisconnect
#' @rdname DuckDBConnection
releaseDuckDBConn <- function() {
    if (!is.null(.duckdb$drv)) {
        dbDisconnect(.duckdb$drv)
        .duckdb$drv <- NULL
    }
    invisible(NULL)
}
