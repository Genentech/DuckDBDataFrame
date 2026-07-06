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

#' @importFrom DBI dbExecute
#' @importFrom tools R_user_dir
setExtensionDirectory <- function(conn) {
    ext_dir <- Sys.getenv("DUCKDB_EXTENSION_DIRECTORY", unset = "")
    if (!nzchar(ext_dir)) {
        ext_dir <- R_user_dir("DuckDBDataFrame", which = "cache")
    }
    dir.create(ext_dir, recursive = TRUE, showWarnings = FALSE)
    dbExecute(conn, sprintf("SET extension_directory = '%s';", ext_dir))
    invisible(ext_dir)
}

#' @importFrom DBI dbExecute dbGetQuery
loadExtension <- function(conn, extension, optional = FALSE) {
    qry <-
      sprintf("SELECT * FROM duckdb_extensions() WHERE extension_name = '%s';",
              extension)
    tbl <- dbGetQuery(conn, qry)
    if (nrow(tbl) == 0L) {
        if (optional) {
            warning(sprintf("Optional extension '%s' is unknown to this DuckDB build; skipping.",
                            extension), call. = FALSE)
            return(invisible(0L))
        }
        stop(sprintf("Extension '%s' not found in DuckDB.", extension))
    }
    if (!tbl[["installed"]]) {
        installed <- tryCatch({
            dbExecute(conn, sprintf("INSTALL '%s';", extension))
            TRUE
        }, error = function(e) {
            err_msg <- conditionMessage(e)
            is_perm <- grepl("Permission denied|read-only|Failed to create directory",
                             err_msg, ignore.case = TRUE)
            is_net <- grepl("SSL|certificate|TLS|Failed to download|network|timeout",
                            err_msg, ignore.case = TRUE)
            if (optional && (is_perm || is_net)) {
                warning(sprintf(
                    "Could not install optional '%s' extension; some functionality may be limited.\nOriginal error: %s",
                    extension, err_msg), call. = FALSE)
                return(FALSE)
            }
            if (is_perm) {
                stop(sprintf(paste0(
                    "Failed to install '%s' extension: the DuckDB extension directory is not writable.\n",
                    "Set the DUCKDB_EXTENSION_DIRECTORY environment variable to a writable path\n",
                    "(e.g. '~/.duckdb/extensions') and retry.\n\nOriginal error: %s"),
                    extension, err_msg), call. = FALSE)
            }
            if (is_net) {
                stop(sprintf(paste0(
                    "Failed to install '%s' extension: could not reach the extension repository.\n",
                    "Install it from a host with network access, or manually download it from\n",
                    "http://extensions.duckdb.org into the DuckDB extension directory.\n\nOriginal error: %s"),
                    extension, err_msg), call. = FALSE)
            }
            stop(e)
        })
        if (!isTRUE(installed)) {
            return(invisible(0L))
        }
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
        setExtensionDirectory(conn)
        loadExtension(conn, "httpfs", optional = TRUE)
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
