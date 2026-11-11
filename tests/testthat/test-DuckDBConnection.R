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

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### .get_duckdb_schema() memoization (schema_cache)
###

test_that(".get_duckdb_schema() memoizes and reuses a cache hit", {
    releaseDuckDBConn()
    on.exit(releaseDuckDBConn(), add = TRUE)

    # DuckDBTable() construction itself already calls .get_duckdb_schema()
    # once internally (for its lossy-widetype check), so the cache already
    # holds this (conn, datacols) pair once construction returns.
    tbl <- DuckDBTable(esoph_parquet, datacols = c("ncases", "ncontrols"),
                       keycols = c("agegp", "alcgp", "tobgp"))
    n1 <- length(DuckDBDataFrame:::.duckdb$schema_cache$entries)
    expect_gte(n1, 1L)

    s1 <- DuckDBDataFrame:::.get_duckdb_schema(tbl@conn, tbl@datacols)

    # a second call with the SAME (conn, datacols) must hit the cache, not
    # grow it, and must return the identical schema
    s2 <- DuckDBDataFrame:::.get_duckdb_schema(tbl@conn, tbl@datacols)
    expect_equal(length(DuckDBDataFrame:::.duckdb$schema_cache$entries), n1)
    expect_identical(s1, s2)
})

test_that(".get_duckdb_schema() cache correctly misses on a genuinely different (conn, datacols)", {
    releaseDuckDBConn()
    on.exit(releaseDuckDBConn(), add = TRUE)

    tbl1 <- DuckDBTable(esoph_parquet, datacols = c("ncases", "ncontrols"),
                        keycols = c("agegp", "alcgp", "tobgp"))
    tbl2 <- DuckDBTable(esoph_parquet, datacols = "ncases",
                        keycols = c("agegp", "alcgp", "tobgp"))

    s1 <- DuckDBDataFrame:::.get_duckdb_schema(tbl1@conn, tbl1@datacols)
    s2 <- DuckDBDataFrame:::.get_duckdb_schema(tbl2@conn, tbl2@datacols)
    # different 'datacols' -> genuinely different schema, not a stale hit
    # borrowed from tbl1's cache entry
    expect_false(identical(s1, s2))
    expect_identical(names(s2), "ncases")
    expect_identical(unname(s2), unname(s1["ncases"]))

    # re-querying tbl1 after tbl2 was cached must still return tbl1's own
    # schema (the cache must not have cross-contaminated entries)
    s1b <- DuckDBDataFrame:::.get_duckdb_schema(tbl1@conn, tbl1@datacols)
    expect_identical(s1, s1b)
})

test_that("releaseDuckDBConn() clears the schema cache", {
    releaseDuckDBConn()
    on.exit(releaseDuckDBConn(), add = TRUE)

    tbl <- DuckDBTable(esoph_parquet, datacols = c("ncases", "ncontrols"),
                       keycols = c("agegp", "alcgp", "tobgp"))
    DuckDBDataFrame:::.get_duckdb_schema(tbl@conn, tbl@datacols)
    expect_gt(length(DuckDBDataFrame:::.duckdb$schema_cache$entries), 0L)

    releaseDuckDBConn()
    expect_identical(DuckDBDataFrame:::.duckdb$schema_cache$entries, list())
})

test_that("the schema cache evicts least-recently-used entries past its size cap", {
    releaseDuckDBConn()
    on.exit(releaseDuckDBConn(), add = TRUE)

    # Exercise .store_schema_cache()/.lookup_schema_cache() directly with
    # synthetic (fabricated, but mutually identical()-distinct) keys: the
    # eviction bookkeeping itself doesn't depend on these being real
    # tbl_duckdb_connection/datacols objects.
    cap <- DuckDBDataFrame:::.SCHEMA_CACHE_SIZE
    keys <- lapply(seq_len(cap + 2L), function(i) as.expression(as.name(paste0("x", i))))
    for (i in seq_along(keys)) {
        DuckDBDataFrame:::.store_schema_cache(conn = "conn", datacols = keys[[i]],
                                              schema = c(x = "INTEGER"))
    }
    expect_identical(length(DuckDBDataFrame:::.duckdb$schema_cache$entries), cap)
    # the oldest two keys were evicted; the most recent 'cap' remain
    expect_null(DuckDBDataFrame:::.lookup_schema_cache("conn", keys[[1L]]))
    expect_null(DuckDBDataFrame:::.lookup_schema_cache("conn", keys[[2L]]))
    expect_identical(DuckDBDataFrame:::.lookup_schema_cache("conn", keys[[length(keys)]]),
                     c(x = "INTEGER"))
})

test_that("BIOCDUCKDB_EXTENSION_REPOSITORY is used by loadExtension's INSTALL", {
    releaseDuckDBConn()
    repo <- tempfile("ext_repo_")
    ext_dir <- tempfile("ext_dir_")
    dir.create(repo)
    old <- Sys.getenv(c("BIOCDUCKDB_EXTENSION_REPOSITORY",
                        "DUCKDB_EXTENSION_DIRECTORY"), unset = NA)
    Sys.setenv(BIOCDUCKDB_EXTENSION_REPOSITORY = repo,
               DUCKDB_EXTENSION_DIRECTORY = ext_dir)
    on.exit({
        for (nm in names(old)) {
            if (is.na(old[[nm]])) Sys.unsetenv(nm)
            else do.call(Sys.setenv, setNames(list(old[[nm]]), nm))
        }
        unlink(c(repo, ext_dir), recursive = TRUE)
        releaseDuckDBConn()
    }, add = TRUE)

    con <- acquireDuckDBConn()
    setting <- DBI::dbGetQuery(con,
        "SELECT current_setting('custom_extension_repository') AS v")$v
    expect_identical(setting, repo)

    # the empty local mirror has no extensions, so the install must fail
    # while looking there rather than reaching out to the public repository
    err <- tryCatch(loadExtension(con, "spatial"), error = conditionMessage)
    expect_type(err, "character")
    expect_match(err, basename(repo), fixed = TRUE)
})
