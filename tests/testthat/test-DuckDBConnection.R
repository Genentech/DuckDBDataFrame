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
