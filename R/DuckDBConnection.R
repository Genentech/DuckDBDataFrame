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
#' \code{configureOutOfCore} applies out-of-core engine settings (buffer-pool
#' memory limit, worker threads, spill directory, insertion-order preservation)
#' to \code{conn} from R options or environment variables, returning \code{NULL}
#' invisibly.
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
#' \code{configureOutOfCore} is called automatically by \code{acquireDuckDBConn}
#' when the shared connection is first created; call it again (on
#' \code{acquireDuckDBConn()}) after changing an option to re-apply. Each
#' setting is read from an R option first, then an environment variable, and
#' left at the DuckDB default when neither is set:
#' \tabular{lll}{
#'   \strong{Setting} \tab \strong{Option} \tab \strong{Environment variable}
#'   \cr memory limit \tab \code{DuckDBDataFrame.memory_limit} \tab
#'   \code{BIOCDUCKDB_MEMORY_LIMIT} \cr threads \tab
#'   \code{DuckDBDataFrame.threads} \tab \code{BIOCDUCKDB_THREADS} \cr spill
#'   directory \tab \code{DuckDBDataFrame.temp_directory} \tab
#'   \code{BIOCDUCKDB_TEMP_DIRECTORY} \cr preserve insertion order \tab\
#'   \code{DuckDBDataFrame.preserve_insertion_order} \tab
#'   \code{BIOCDUCKDB_PRESERVE_INSERTION_ORDER} \cr
#' }
#' Setting \code{memory_limit} (e.g. \code{"16GB"} or \code{"80\%"}) and
#' \code{temp_directory} guards against the OS killing the process before DuckDB
#' can spill a large aggregation/sort/join; \code{preserve_insertion_order =
#' FALSE} avoids buffering a whole result to preserve row order on a Tahoe-scale
#' export where order is not significant.
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
#' @aliases configureOutOfCore
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
    repo <- Sys.getenv("BIOCDUCKDB_EXTENSION_REPOSITORY",
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

.outOfCoreSetting <- function(option, envvar) {
    val <- getOption(option, default = NULL)
    if (!is.null(val)) {
        return(as.character(val))
    }
    env_val <- Sys.getenv(envvar, unset = "")
    if (nzchar(env_val)) {
        return(env_val)
    }
    NULL
}

#' @export
#' @importFrom DBI dbExecute
#' @rdname DuckDBConnection
configureOutOfCore <- function(conn) {
    ml <- .outOfCoreSetting("DuckDBDataFrame.memory_limit", "BIOCDUCKDB_MEMORY_LIMIT")
    if (!is.null(ml)) {
        try(dbExecute(conn, sprintf("SET memory_limit = '%s';",
                                    gsub("'", "''", ml))), silent = TRUE)
    }
    td <- .outOfCoreSetting("DuckDBDataFrame.temp_directory", "BIOCDUCKDB_TEMP_DIRECTORY")
    if (!is.null(td)) {
        try(dbExecute(conn, sprintf("SET temp_directory = '%s';",
                                    gsub("'", "''", td))), silent = TRUE)
    }
    th <- .outOfCoreSetting("DuckDBDataFrame.threads", "BIOCDUCKDB_THREADS")
    if (!is.null(th)) {
        th_int <- suppressWarnings(as.integer(th))
        if (!is.na(th_int)) {
            try(dbExecute(conn, sprintf("SET threads = %d;", th_int)), silent = TRUE)
        }
    }
    pio <- .outOfCoreSetting("DuckDBDataFrame.preserve_insertion_order",
                             "BIOCDUCKDB_PRESERVE_INSERTION_ORDER")
    if (!is.null(pio)) {
        pio_on <- tolower(pio) %in% c("true", "t", "1", "yes")
        try(dbExecute(conn, sprintf("SET preserve_insertion_order = %s;",
                                    if (pio_on) "true" else "false")), silent = TRUE)
    }
    invisible(NULL)
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
        configureOutOfCore(conn)
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
