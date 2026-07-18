# Tests for DuckDB connection cache.
# library(testthat); library(DuckDBDataFrame); source("test-DuckDBConnection.R")

test_that("acquireDuckDBConn caches a duckdb connection", {
    releaseDuckDBConn()
    on.exit(releaseDuckDBConn(), add = TRUE)

    conn1 <- acquireDuckDBConn()
    conn2 <- acquireDuckDBConn()
    expect_s4_class(conn1, "duckdb_connection")
    expect_identical(conn1, conn2)
})

test_that("releaseDuckDBConn disconnects and is idempotent", {
    releaseDuckDBConn()
    conn <- acquireDuckDBConn()
    expect_s4_class(conn, "duckdb_connection")
    expect_invisible(releaseDuckDBConn())
    expect_invisible(releaseDuckDBConn())
})

test_that("acquireDuckDBConn validates conn type on first call", {
    releaseDuckDBConn()
    on.exit(releaseDuckDBConn(), add = TRUE)
    expect_error(acquireDuckDBConn("not a connection"), "'conn' must be")
})

test_that("configureOutOfCore applies engine settings from options and env", {
    releaseDuckDBConn()
    old <- options(
        DuckDBDataFrame.threads = 2L,
        DuckDBDataFrame.preserve_insertion_order = FALSE,
        DuckDBDataFrame.memory_limit = "512MB"
    )
    old_env <- Sys.getenv("BIOCDUCKDB_TEMP_DIRECTORY", unset = NA)
    td <- tempfile("spill")
    dir.create(td, showWarnings = FALSE, recursive = TRUE)
    Sys.setenv(BIOCDUCKDB_TEMP_DIRECTORY = td)
    on.exit({
        options(old)  # restores threads to the setup.R harness pin (1L)
        if (is.na(old_env)) {
            Sys.unsetenv("BIOCDUCKDB_TEMP_DIRECTORY")
        } else {
            Sys.setenv(BIOCDUCKDB_TEMP_DIRECTORY = old_env)
        }
        releaseDuckDBConn()
    }, add = TRUE)

    conn <- acquireDuckDBConn()
    setting <- function(k) {
        DBI::dbGetQuery(conn, sprintf("SELECT current_setting('%s') AS v", k))$v
    }
    expect_equal(as.integer(setting("threads")), 2L)
    expect_false(as.logical(setting("preserve_insertion_order")))
    expect_match(as.character(setting("temp_directory")), basename(td), fixed = TRUE)
})

test_that("configureOutOfCore leaves settings at defaults when unset", {
    releaseDuckDBConn()
    old <- options(
        DuckDBDataFrame.threads = NULL,
        DuckDBDataFrame.memory_limit = NULL,
        DuckDBDataFrame.temp_directory = NULL,
        DuckDBDataFrame.preserve_insertion_order = NULL
    )
    on.exit({
        options(old)
        releaseDuckDBConn()
    }, add = TRUE)

    # A bad env value must not error the connection setup (SET is try()-guarded).
    Sys.setenv(BIOCDUCKDB_THREADS = "not-a-number")
    on.exit(Sys.unsetenv("BIOCDUCKDB_THREADS"), add = TRUE)
    expect_s4_class(acquireDuckDBConn(), "duckdb_connection")
})
