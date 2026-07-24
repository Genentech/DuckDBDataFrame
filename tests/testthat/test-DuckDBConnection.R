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

test_that(".slurmCpus / .defaultThreads read the SLURM CPU allocation", {
    Sys.unsetenv("SLURM_CPUS_PER_TASK")
    Sys.unsetenv("SLURM_CPUS_ON_NODE")
    on.exit({
        Sys.unsetenv("SLURM_CPUS_PER_TASK")
        Sys.unsetenv("SLURM_CPUS_ON_NODE")
    }, add = TRUE)

    expect_null(DuckDBDataFrame:::.slurmCpus())
    Sys.setenv(SLURM_CPUS_ON_NODE = "4")
    expect_identical(DuckDBDataFrame:::.slurmCpus(), 4L)
    Sys.setenv(SLURM_CPUS_PER_TASK = "6")            # per-task takes precedence
    expect_identical(DuckDBDataFrame:::.slurmCpus(), 6L)

    # A SLURM floor of 1 makes the detected default deterministically 1 --
    # min() with any cgroup CFS quota (>= 1) or with nothing detected.
    Sys.setenv(SLURM_CPUS_PER_TASK = "1")
    expect_identical(DuckDBDataFrame:::.defaultThreads(), 1L)
})

test_that("configureOutOfCore defaults threads to the SLURM allocation when unset", {
    releaseDuckDBConn()
    old <- options(DuckDBDataFrame.threads = NULL)
    Sys.setenv(SLURM_CPUS_PER_TASK = "1")
    on.exit({
        options(old)
        Sys.unsetenv("SLURM_CPUS_PER_TASK")
        releaseDuckDBConn()
    }, add = TRUE)

    con <- acquireDuckDBConn()
    thr <- as.integer(
        DBI::dbGetQuery(con, "SELECT current_setting('threads') AS v")$v)
    expect_identical(thr, 1L)
})

test_that(".cgroupDirs / cgroup detectors resolve the job subpath then fall back", {
    mk <- function(p, txt) {
        dir.create(dirname(p), recursive = TRUE, showWarnings = FALSE)
        writeLines(txt, p)
    }

    # cgroup v2: the job's own subpath must win over the mount root
    b <- tempfile("v2_"); root <- file.path(b, "cg"); proc <- file.path(b, "proc")
    on.exit(unlink(b, recursive = TRUE), add = TRUE)
    mk(file.path(root, "myjob", "memory.max"), "8589934592")   # 8 GiB (job)
    mk(file.path(root, "memory.max"), "68719476736")           # 64 GiB (root)
    mk(file.path(root, "myjob", "cpu.max"), "200000 100000")   # 2 cpus (job)
    mk(file.path(root, "cpu.max"), "800000 100000")            # 8 cpus (root)
    writeLines("0::/myjob", proc)
    expect_identical(
        DuckDBDataFrame:::.cgroupMemoryBytes(DuckDBDataFrame:::.cgroupDirs("memory", proc, root)),
        8 * 2^30)
    expect_identical(
        DuckDBDataFrame:::.cgroupCpus(DuckDBDataFrame:::.cgroupDirs("cpu", proc, root)),
        2L)

    # cgroup v1 with a combined controller mount (cpu,cpuacct) + subpath
    b <- tempfile("v1_"); root <- file.path(b, "cg"); proc <- file.path(b, "proc")
    on.exit(unlink(b, recursive = TRUE), add = TRUE)
    mk(file.path(root, "memory", "mygrp", "memory.limit_in_bytes"), "4294967296") # 4 GiB
    mk(file.path(root, "cpu,cpuacct", "mygrp", "cpu.cfs_quota_us"), "300000")
    mk(file.path(root, "cpu,cpuacct", "mygrp", "cpu.cfs_period_us"), "100000")    # 3 cpus
    writeLines(c("7:memory:/mygrp", "5:cpu,cpuacct:/mygrp"), proc)
    expect_identical(
        DuckDBDataFrame:::.cgroupMemoryBytes(DuckDBDataFrame:::.cgroupDirs("memory", proc, root)),
        4 * 2^30)
    expect_identical(
        DuckDBDataFrame:::.cgroupCpus(DuckDBDataFrame:::.cgroupDirs("cpu", proc, root)),
        3L)

    # root fallback: no /proc/self/cgroup -> the mount root is still searched
    b <- tempfile("rt_"); root <- file.path(b, "cg"); proc <- file.path(b, "absent")
    on.exit(unlink(b, recursive = TRUE), add = TRUE)
    mk(file.path(root, "memory.max"), "1073741824")            # 1 GiB at root
    expect_identical(
        DuckDBDataFrame:::.cgroupMemoryBytes(DuckDBDataFrame:::.cgroupDirs("memory", proc, root)),
        2^30)

    # unconstrained ("max") -> NULL
    b <- tempfile("mx_"); root <- file.path(b, "cg"); proc <- file.path(b, "proc")
    on.exit(unlink(b, recursive = TRUE), add = TRUE)
    mk(file.path(root, "memory.max"), "max")
    writeLines("0::/", proc)
    expect_null(
        DuckDBDataFrame:::.cgroupMemoryBytes(DuckDBDataFrame:::.cgroupDirs("memory", proc, root)))
})

test_that(".physicalMemoryBytes parses an injected /proc/meminfo", {
    mi <- tempfile()
    on.exit(unlink(mi), add = TRUE)
    writeLines(c("MemTotal:       16307188 kB", "SwapTotal:  0 kB"), mi)
    expect_identical(DuckDBDataFrame:::.physicalMemoryBytes(mi), 16307188 * 1024)
    expect_null(DuckDBDataFrame:::.physicalMemoryBytes(tempfile()))
})
