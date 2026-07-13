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
#' @param extension A character string naming a DuckDB extension (e.g.
#'   \code{"spatial"}).
#' @param optional If \code{TRUE}, an extension that is unknown to the build or
#'   cannot be installed (permission / network) produces a warning and is
#'   skipped rather than an error. Defaults to \code{FALSE}.
#'
#' @return
#' \code{acquireDuckDBConn} returns a cached \code{duckdb_connection} object.
#' \code{releaseDuckDBConn} returns \code{NULL}, invisibly.
#' \code{loadExtension} installs (if needed) and loads \code{extension} on
#' \code{conn}, returning the load status invisibly.
#'
#' @author Patrick Aboyoun
#'
#' @details
#' \code{acquireDuckDBConn} will add a \code{duckdb_connection} object to
#' the \pkg{BiocDuckDB} package cache.
#' \code{releaseDuckDBConn} will remove the \code{duckdb_connection} object
#' from that cache.
#' \code{loadExtension} installs and loads a DuckDB extension on the shared
#' connection; it is used by companion packages (e.g. \pkg{DuckDBSpatial}) to
#' ensure their required extension (\code{"spatial"}) is available.
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
#' @aliases loadExtension
#'
#' @keywords IO
#'
#' @name DuckDBConnection
NULL

#' @export
#' @rdname DuckDBConnection
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
                    "Could not install optional '%s' extension; some functionality may be limited.\nDetails: %s",
                    extension, err_msg), call. = FALSE)
                return(FALSE)
            }
            if (is_perm) {
                stop(sprintf(
                    "Failed to install '%s' extension: the DuckDB extension directory is not writable.\nSet the DUCKDB_EXTENSION_DIRECTORY environment variable to a writable path\n(e.g. '~/.duckdb/extensions') and retry.\n\nDetails: %s",
                    extension, err_msg), call. = FALSE)
            }
            if (is_net) {
                stop(sprintf(
                    "Failed to install '%s' extension: could not reach the extension repository.\nInstall it from a host with network access, or manually download it from\nhttp://extensions.duckdb.org into the DuckDB extension directory.\n\nDetails: %s",
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

#' @importFrom DBI dbExecute dbGetQuery
loadInstalledExtensions <- function(conn, extensions) {
    installed <- tryCatch(
        dbGetQuery(conn,
                   "SELECT extension_name FROM duckdb_extensions() WHERE installed"),
        error = function(e) NULL)
    if (is.null(installed)) {
        return(invisible(NULL))
    }
    for (ext in intersect(extensions, installed$extension_name)) {
        try(dbExecute(conn, sprintf("LOAD %s;", ext)), silent = TRUE)
    }
    invisible(NULL)
}

#' @importFrom DBI dbExecute dbGetQuery
configureExtensionAutoloading <- function(conn) {
    try(dbExecute(conn, "SET autoinstall_known_extensions = true;"), silent = TRUE)
    try(dbExecute(conn, "SET autoload_known_extensions = true;"), silent = TRUE)
    repo <- Sys.getenv("MODL_DUCKDB_EXTENSION_REPOSITORY",
                       unset = Sys.getenv("DUCKDB_EXTENSION_REPOSITORY", unset = ""))
    if (nzchar(repo)) {
        try(dbExecute(conn,
                      sprintf("SET autoinstall_extension_repository = '%s';", repo)),
            silent = TRUE)
    }
    loadInstalledExtensions(conn, c("spatial", "httpfs"))
    invisible(NULL)
}

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
        configureExtensionAutoloading(conn)
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
