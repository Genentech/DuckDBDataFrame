test_that("validateAppendOffset coerces valid offsets", {
    expect_identical(validateAppendOffset(0L), 0L)
    expect_identical(validateAppendOffset(3), 3L)
    expect_error(validateAppendOffset(-1L), "'offset'")
    expect_error(validateAppendOffset(c(0L, 1L)), "'offset'")
})

test_that("checkAppendPart refuses existing part files", {
    path <- tempfile()
    dir.create(path)
    on.exit(unlink(path, recursive = TRUE), add = TRUE)
    target <- file.path(path, "part-0.parquet")
    file.create(target)
    expect_error(checkAppendPart(path, 0L), "already exists")
    expect_invisible(checkAppendPart(path, 1L))
})

test_that("readParquetSchema reads first file", {
    path <- tempfile()
    dir.create(path)
    on.exit(unlink(path, recursive = TRUE), add = TRUE)
    df <- data.frame(x = 1:3L, y = letters[1:3])
    pq <- file.path(path, "part-0.parquet")
    arrow::write_parquet(df, pq)
    sch <- readParquetSchema(path, columns = c("x", "y"))
    expect_true(inherits(sch, "Schema"))
    expect_error(readParquetSchema(path, columns = "z"), "lacks field")
})

test_that("arrowType narrows non-negative integers", {
    expect_identical(arrowType(1:10L)$ToString(), "uint8")
    expect_identical(arrowType(1:300L)$ToString(), "uint16")
})

test_that("arrowIntType narrows by range", {
    expect_identical(arrowIntType(c(0L, 10L))$ToString(), "uint8")
    expect_identical(arrowIntType(c(-5L, 5L))$ToString(), "int8")
})

test_that("arrowTypeFromName and arrowTypeToName round-trip", {
    expect_identical(arrowTypeToName(arrow::uint16()), "uint16")
    expect_identical(arrowTypeFromName("uint16")$ToString(), "uint16")
    expect_identical(arrowTypeToName("int32"), "int32")
})

test_that("arrowIntType selects wider unsigned integer types", {
    expect_identical(arrowIntType(c(0L, 65535L))$ToString(), "uint16")
    expect_identical(arrowIntType(c(0L, 2147483647L))$ToString(), "int32")
    expect_identical(arrowIntType(c(0L, 4294967295))$ToString(), "uint32")
    expect_identical(arrowIntType(c(0L, 5000000000))$ToString(), "int64")
})

test_that("arrowIntType selects signed integer types", {
    expect_identical(arrowIntType(c(-32768L, 32767L))$ToString(), "int16")
    expect_identical(arrowIntType(c(-2147483647L, 2147483647L))$ToString(), "int32")
    expect_identical(arrowIntType(c(-5000000000, 5000000000))$ToString(), "int64")
})

test_that("arrowType infers non-integer vectors", {
    expect_identical(arrowType(letters)$ToString(), "string")
    expect_identical(arrowType(c(1.5, 2.5))$ToString(), "double")
    expect_identical(arrowType(integer(0))$ToString(), "int32")
})

test_that("arrowTypeToName validates input", {
    expect_error(arrowTypeToName(c("int32", "int64")), "single")
    expect_error(arrowTypeToName(1L), "DataType")
})

test_that("arrowTypeFromName supports scalar types and validates input", {
    expect_identical(arrowTypeFromName("float")$ToString(), "float")
    expect_identical(arrowTypeFromName("double")$ToString(), "double")
    expect_identical(arrowTypeFromName("bool")$ToString(), "bool")
    expect_identical(arrowTypeFromName("int8")$ToString(), "int8")
    expect_identical(arrowTypeFromName("uint32")$ToString(), "uint32")
    expect_identical(arrowTypeFromName("uint64")$ToString(), "uint64")
    expect_error(arrowTypeFromName("not_a_type"), "unsupported")
    expect_error(arrowTypeFromName(c("int32", "int64")), "single")
})

test_that("reconcileParquetSchema accepts character type names", {
    path <- tempfile()
    dir.create(path)
    on.exit(unlink(path, recursive = TRUE), add = TRUE)
    df <- data.frame(x = 1:3L, y = letters[1:3])
    arrow::write_parquet(df, file.path(path, "part-0.parquet"))
    arrowtypes <- list(x = "int32", y = NULL)
    resolved <- reconcileParquetSchema(path, c("x", "y"), arrowtypes)
    expect_identical(resolved$x$ToString(), "int32")
    expect_identical(resolved$y$ToString(), "string")
    expect_error(
        reconcileParquetSchema(path, "x", list(x = "int64")),
        "schema mismatch"
    )
})

test_that("parquetPartPath builds part filenames", {
    path <- tempfile()
    expect_equal(parquetPartPath(path, 0L), file.path(path, "part-0.parquet"))
    expect_equal(parquetPartPath(path, 1L, 2L), file.path(path, "part-01.parquet"))
})

test_that("validateWriteParquetPart accepts NULL", {
    expect_null(validateWriteParquetPart(NULL))
    expect_identical(validateWriteParquetPart(2L), 2L)
    expect_error(validateWriteParquetPart(-1L), "'part'")
})

test_that("setupFlatParquetWrite validates flat append", {
    path <- tempfile()
    dir.create(path)
    on.exit(unlink(path, recursive = TRUE), add = TRUE)
    arrow::write_parquet(data.frame(x = 1L), file.path(path, "part-0.parquet"))

    prep0 <- setupFlatParquetWrite(path, append = FALSE)
    expect_false(prep0$subsequent_part)
    expect_equal(prep0$part, 0L)

    prep <- setupFlatParquetWrite(path, append = TRUE, part = 1L,
                                  indexcol = "__sample__", offset = 3L)
    expect_equal(prep$pq_path, file.path(path, "part-1.parquet"))
    expect_equal(prep$offset, 3L)
    expect_true(prep$subsequent_part)

    prep2 <- setupFlatParquetWrite(path, append = TRUE, part = 2L,
                                   indexcol = "__sample__", offset = 10L)
    expect_true(prep2$subsequent_part)
    expect_error(setupFlatParquetWrite(path, append = TRUE),
                 "requires 'part'")
})

test_that("escapeSQLPath doubles single quotes", {
    expect_equal(escapeSQLPath("/tmp/a'b"), "/tmp/a''b")
})

test_that("quoteSQLColumns quotes identifiers", {
    conn <- DBI::dbConnect(duckdb::duckdb())
    on.exit(DBI::dbDisconnect(conn, shutdown = TRUE), add = TRUE)
    quoted <- quoteSQLColumns(conn, c("col", "x y"))
    expect_length(quoted, 2L)
    expect_equal(quoted[1L], "col")
    expect_true(grepl("x y", quoted[2L], fixed = TRUE))
})

test_that("buildParquetCopySQL assembles COPY TO options", {
    sql <- buildParquetCopySQL("SELECT 1", "/tmp/out.parquet",
                               order_cols = '"idx"')
    expect_true(grepl("^COPY \\(SELECT 1 ORDER BY", sql))
    expect_true(grepl("FORMAT PARQUET", sql))
    expect_true(grepl("COMPRESSION zstd", sql))
    expect_true(grepl("COMPRESSION_LEVEL 3", sql))
    expect_false(grepl("ROW_GROUP_SIZE", sql))

    sql2 <- buildParquetCopySQL("SELECT 1", "/tmp/out",
                                order_cols = "m1.new_idx",
                                partition_by = '"__sample__group__"',
                                row_group_size = 491520L)
    expect_true(grepl("ROW_GROUP_SIZE 491520", sql2))
    expect_true(grepl("PARTITION_BY", sql2))
})

# ---- cluster_by: coord-indexed / multi-dimensional clustering on write -----------

test_that("zorder/hilbert constructors validate their arguments", {
    z <- zorder(c("x", "y"))
    expect_s3_class(z, "DuckDBClusterSpec")
    expect_identical(z$curve, "zorder")
    expect_identical(z$cols, c("x", "y"))
    expect_error(hilbert(c("x", "y", "z")), "exactly two")   # ST_Hilbert is 2-D
    expect_error(zorder(character(0)), "at least one")
    expect_error(zorder(c("a", "b", "c", "d"), bits = 16L), "<= 62")  # 4*16 overflows 64-bit
    expect_error(zorder("x", bits = 40L), "1:20")            # bits out of range
    expect_error(zorder("x", bits = 0L), "1:20")
})

test_that("clusterSort reorders in memory and is a permutation", {
    set.seed(1)
    df <- data.frame(x = runif(1000, 0, 100), y = runif(1000, 0, 100))
    srt <- clusterSort(df, zorder(c("x", "y")))
    expect_equal(nrow(srt), nrow(df))
    expect_setequal(srt$x, df$x)
    # spatially clustered: adjacent-row distance far below the random baseline
    step <- mean(sqrt(diff(srt$x)^2 + diff(srt$y)^2))
    base <- mean(sqrt(diff(df$x)^2 + diff(df$y)^2))
    expect_lt(step, base / 2)
    # lexicographic + no-op cases
    expect_equal(clusterSort(df, "x")$x, sort(df$x))
    expect_identical(clusterSort(df, NULL), df)
})

test_that("clusterSort composite key groups by `by=` prefix then clusters within", {
    set.seed(1)
    n <- 1200
    df <- data.frame(gene = sample(c("A", "B", "C"), n, replace = TRUE),
                     x = runif(n, 0, 100), y = runif(n, 0, 100),
                     stringsAsFactors = FALSE)
    srt <- clusterSort(df, zorder(c("x", "y"), by = "gene"))
    expect_equal(nrow(srt), nrow(df))
    expect_setequal(srt$x, df$x)
    # each gene's rows are contiguous (prefix ordered ascending)
    expect_equal(srt$gene, sort(srt$gene))
    # ...and spatially clustered WITHIN each gene group
    within <- mean(vapply(split(srt[c("x", "y")], srt$gene), function(g)
        if (nrow(g) > 1L) mean(sqrt(diff(g$x)^2 + diff(g$y)^2)) else NA_real_,
        numeric(1L)), na.rm = TRUE)
    base <- mean(sqrt(diff(df$x)^2 + diff(df$y)^2))
    expect_lt(within, base / 2)
    # `by` is budget-free: the prefix does not enter the length(cols)*bits<=62 budget
    expect_s3_class(zorder(c("a", "b", "c"), bits = 20L, by = c("gene", "cell")),
                    "DuckDBClusterSpec")
})

test_that("writeDuckDBTableParquet clusters rows with cluster_by = zorder()", {
    skip_if_not_installed("arrow")
    set.seed(1)
    df <- data.frame(x = runif(3000, 0, 100), y = runif(3000, 0, 100),
                     gene = sample(paste0("G", 0:19), 3000, replace = TRUE),
                     stringsAsFactors = FALSE)
    src <- tempfile(fileext = ".parquet"); on.exit(unlink(src), add = TRUE)
    arrow::write_parquet(df, src)
    ddf <- DuckDBDataFrame(src)

    out <- tempfile()
    writeDuckDBTableParquet(ddf, out, indexcol = NULL, keycol = NULL,
                            cluster_by = zorder(c("x", "y")))
    pq <- file.path(out, list.files(out, pattern = "parquet$", recursive = TRUE))[1L]
    got <- as.data.frame(arrow::read_parquet(pq))
    expect_equal(nrow(got), nrow(df))
    expect_setequal(got$x, df$x)
    step <- mean(sqrt(diff(got$x)^2 + diff(got$y)^2))
    base <- mean(sqrt(diff(df$x)^2 + diff(df$y)^2))
    expect_lt(step, base / 2)                                 # zonemap-friendly locality

    expect_error(
        writeDuckDBTableParquet(ddf, tempfile(), indexcol = NULL, keycol = NULL,
                                cluster_by = zorder(c("x", "nope"))),
        "not found")
})

test_that("writeDuckDBTableParquet composite cluster_by = zorder(by=) groups then clusters", {
    skip_if_not_installed("arrow")
    set.seed(1)
    n <- 3000
    df <- data.frame(gene = sample(c("A", "B", "C"), n, replace = TRUE),
                     x = runif(n, 0, 100), y = runif(n, 0, 100),
                     stringsAsFactors = FALSE)
    src <- tempfile(fileext = ".parquet"); on.exit(unlink(src), add = TRUE)
    arrow::write_parquet(df, src)
    ddf <- DuckDBDataFrame(src)

    out <- tempfile()
    writeDuckDBTableParquet(ddf, out, indexcol = NULL, keycol = NULL,
                            cluster_by = zorder(c("x", "y"), by = "gene"))
    pq <- file.path(out, list.files(out, pattern = "parquet$", recursive = TRUE))[1L]
    got <- as.data.frame(arrow::read_parquet(pq))
    expect_equal(nrow(got), nrow(df))
    expect_equal(got$gene, sort(got$gene))          # gene groups contiguous on disk
    within <- mean(vapply(split(got[c("x", "y")], got$gene), function(g)
        mean(sqrt(diff(g$x)^2 + diff(g$y)^2)), numeric(1L)))
    base <- mean(sqrt(diff(df$x)^2 + diff(df$y)^2))
    expect_lt(within, base / 2)                       # clustered within each group

    expect_error(                                    # prefix column must exist too
        writeDuckDBTableParquet(ddf, tempfile(), indexcol = NULL, keycol = NULL,
                                cluster_by = zorder(c("x", "y"), by = "nope")),
        "not found")
})

test_that("cluster_by tolerates non-finite coordinates (no whole-axis collapse)", {
    skip_if_not_installed("arrow")
    set.seed(1)
    n <- 2000
    df <- data.frame(x = runif(n, 0, 100), y = runif(n, 0, 100))
    df$x[c(5L, 500L, 1500L)] <- NA_real_             # NULL coordinates
    df$y[10L] <- Inf                                 # +Inf coordinate
    src <- tempfile(fileext = ".parquet"); on.exit(unlink(src), add = TRUE)
    arrow::write_parquet(df, src)
    ddf <- DuckDBDataFrame(src)

    out <- tempfile()
    writeDuckDBTableParquet(ddf, out, indexcol = NULL, keycol = NULL,
                            cluster_by = zorder(c("x", "y")))
    got <- as.data.frame(arrow::read_parquet(
        file.path(out, list.files(out, pattern = "parquet$", recursive = TRUE))[1L]))
    expect_equal(nrow(got), n)                        # all rows kept, incl. non-finite
    # the SINGLE NaN/Inf must not collapse the extent: finite rows still cluster
    fin <- got[is.finite(got$x) & is.finite(got$y), , drop = FALSE]
    step <- mean(sqrt(diff(fin$x)^2 + diff(fin$y)^2))
    base <- mean(sqrt(diff(df$x)^2 + diff(df$y)^2), na.rm = TRUE)
    expect_lt(step, base / 2)
    # host path agrees: no error, all rows preserved
    expect_equal(nrow(clusterSort(df, zorder(c("x", "y")))), n)
})

test_that("writeDuckDBTableParquet clusters with cluster_by = hilbert() (native ST_Hilbert)", {
    skip_if_not_installed("arrow")
    have_spatial <- isTRUE(tryCatch({
        loadExtension(acquireDuckDBConn(), "spatial", optional = TRUE)
        "spatial" %in% DBI::dbGetQuery(
            acquireDuckDBConn(),
            "SELECT extension_name FROM duckdb_extensions() WHERE loaded")[[1L]]
    }, error = function(e) FALSE))
    skip_if_not(have_spatial, "DuckDB spatial extension unavailable (offline)")

    set.seed(1)
    df <- data.frame(x = runif(3000, 0, 100), y = runif(3000, 0, 100))
    src <- tempfile(fileext = ".parquet"); on.exit(unlink(src), add = TRUE)
    arrow::write_parquet(df, src)
    ddf <- DuckDBDataFrame(src)

    out <- tempfile()
    writeDuckDBTableParquet(ddf, out, indexcol = NULL, keycol = NULL,
                            cluster_by = hilbert(c("x", "y")))
    pq <- file.path(out, list.files(out, pattern = "parquet$", recursive = TRUE))[1L]
    got <- as.data.frame(arrow::read_parquet(pq))
    expect_equal(nrow(got), nrow(df))
    step <- mean(sqrt(diff(got$x)^2 + diff(got$y)^2))
    base <- mean(sqrt(diff(df$x)^2 + diff(df$y)^2))
    expect_lt(step, base / 2)
})

test_that("writeDuckDBTableParquet exports lazy table via COPY TO", {
    tf <- tempfile(fileext = ".parquet")
    on.exit(unlink(tf), add = TRUE)
    df <- data.frame(value = 1:5, key = letters[1:5])
    arrow::write_parquet(df, tf)
    x <- DuckDBDataFrame(tf, datacols = c("value"), keycol = "key")
    out_dir <- tempfile()
    dir.create(out_dir)
    on.exit(unlink(out_dir, recursive = TRUE), add = TRUE)

    res <- writeDuckDBTableParquet(x, out_dir, indexcol = "__sample__",
                                   keycol = "__name__")
    expect_true(file.exists(res$path))
    expect_equal(res$nrow, 5L)
    pq <- arrow::read_parquet(res$path)
    expect_equal(nrow(pq), 5L)
    expect_equal(pq$`__sample__`, 1:5)
    expect_equal(as.character(pq$`__name__`), letters[1:5])
    expect_equal(pq$value, 1:5)
})

test_that("writeDuckDBTableParquet supports flat append with offset", {
    tf <- tempfile(fileext = ".parquet")
    on.exit(unlink(tf), add = TRUE)
    df <- data.frame(value = 1:3)
    arrow::write_parquet(df, tf)
    x1 <- DuckDBDataFrame(tf)
    out_dir <- tempfile()
    dir.create(out_dir)
    on.exit(unlink(out_dir, recursive = TRUE), add = TRUE)

    writeDuckDBTableParquet(x1, out_dir, indexcol = "__sample__", keycol = NULL,
                            part = 0L)

    df2 <- data.frame(value = 4:5)
    tf2 <- tempfile(fileext = ".parquet")
    arrow::write_parquet(df2, tf2)
    x2 <- DuckDBDataFrame(tf2)
    res2 <- writeDuckDBTableParquet(x2, out_dir, indexcol = "__sample__",
                                    keycol = NULL, offset = 3L, part = 1L,
                                    append = TRUE)
    expect_true(res2$subsequent_part)
    pq2 <- arrow::read_parquet(res2$path)
    expect_equal(pq2$`__sample__`, 4:5)
})

test_that("buildTableSelectSQL returns dplyr-compatible SQL", {
    tf <- tempfile(fileext = ".parquet")
    on.exit(unlink(tf), add = TRUE)
    arrow::write_parquet(data.frame(a = 1:2), tf)
    x <- DuckDBTable(tf)
    built <- buildTableSelectSQL(x, indexcol = "__index__", keycol = NULL,
                                 offset = 10L)
    expect_true(grepl("^SELECT ", built$sql))
    expect_true(grepl("__index__", built$sql))
    expect_equal(built$colnames[1L], "__index__")
})

test_that("collevels restores factor columns on materialization", {
    tf <- tempfile(fileext = ".parquet")
    on.exit(unlink(tf), add = TRUE)
    df <- data.frame(id = letters[1:6], g = c("A", "B", "A", "C", "B", "A"),
                     stringsAsFactors = FALSE)
    arrow::write_parquet(df, tf)

    ddf <- DuckDBDataFrame(tf, datacols = "g", keycol = "id",
                           collevels = list(g = list(levels = c("A", "B", "C"),
                                                     ordered = FALSE)))
    out <- as.data.frame(ddf)
    expect_true(is.factor(out[["g"]]))
    expect_false(is.ordered(out[["g"]]))
    expect_identical(levels(out[["g"]]), c("A", "B", "C"))
    # single-column materialization path (as.vector,DuckDBColumn)
    expect_true(is.factor(as.vector(ddf[["g"]])))
    # coltypes()/type() report "factor" without materializing
    expect_identical(unname(coltypes(ddf)["g"]), "factor")
    expect_identical(type(ddf[["g"]]), "factor")
    # levels()/nlevels() on the DuckDBColumn, also without materializing
    expect_identical(levels(ddf[["g"]]), c("A", "B", "C"))
    expect_identical(nlevels(ddf[["g"]]), 3L)

    ordered <- DuckDBDataFrame(tf, datacols = "g", keycol = "id",
                              collevels = list(g = list(levels = c("A", "B", "C"),
                                                        ordered = TRUE)))
    expect_true(is.ordered(as.data.frame(ordered)[["g"]]))

    # a recast column is no longer a factor
    recast <- ddf
    coltypes(recast) <- c(g = "character")
    expect_false(is.factor(as.data.frame(recast)[["g"]]))
    expect_identical(unname(coltypes(recast)["g"]), "character")
    expect_null(levels(recast[["g"]]))
    expect_identical(nlevels(recast[["g"]]), 0L)

    # a non-factor column has no levels
    tf2 <- tempfile(fileext = ".parquet")
    on.exit(unlink(tf2), add = TRUE)
    arrow::write_parquet(data.frame(id = letters[1:3], plain = c("x", "y", "z")), tf2)
    plain_ddf <- DuckDBDataFrame(tf2, datacols = "plain", keycol = "id")
    expect_null(levels(plain_ddf[["plain"]]))
    expect_identical(nlevels(plain_ddf[["plain"]]), 0L)
})

test_that("reading wide numeric types warns about possible precision loss", {
    tf <- tempfile(fileext = ".parquet")
    on.exit(unlink(tf), add = TRUE)
    wide <- arrow::arrow_table(
        id = letters[1:3],
        d = arrow::Array$create(c(1, 2, 3), type = arrow::decimal128(38, 0)))
    arrow::write_parquet(wide, tf)
    expect_warning(DuckDBDataFrame(tf, datacols = "d", keycol = "id"),
                   "precision")

    tf2 <- tempfile(fileext = ".parquet")
    on.exit(unlink(tf2), add = TRUE)
    narrow <- arrow::arrow_table(
        id = letters[1:3],
        d = arrow::Array$create(c(1.5, 2.5, 3.5), type = arrow::decimal128(10, 2)))
    arrow::write_parquet(narrow, tf2)
    expect_no_warning(DuckDBDataFrame(tf2, datacols = "d", keycol = "id"),
                      message = "precision")
})

.f1IndexType <- function(dir) {
    fs <- sort(list.files(dir, pattern = "parquet$", recursive = TRUE,
                          full.names = TRUE))
    vapply(fs, function(p)
        arrow::ParquetFileReader$create(p)$GetSchema()$
            GetFieldByName("__index__")$type$ToString(), character(1L))
}

test_that("lazy writeParquet narrows __index__ and honors index_max", {
    skip_if_not_installed("arrow")
    src <- tempfile(fileext = ".parquet"); on.exit(unlink(src), add = TRUE)
    arrow::write_parquet(data.frame(v = 1:5), src)
    ddf <- DuckDBDataFrame(src)

    # Small lazy write narrows (uint8), no longer defaults to int64/BIGINT.
    out <- tempfile()
    writeDuckDBTableParquet(ddf, out, indexcol = "__index__", keycol = NULL)
    expect_identical(unname(.f1IndexType(out)), "uint8")

    # index_max = Inf forces int64 (parity with the in-memory writer).
    out2 <- tempfile()
    writeDuckDBTableParquet(ddf, out2, indexcol = "__index__", keycol = NULL,
                            index_max = Inf)
    expect_identical(unname(.f1IndexType(out2)), "int64")
})

test_that("lazy append pins __index__ to part 0's type (schema-consistent parts)", {
    skip_if_not_installed("arrow")
    src <- tempfile(fileext = ".parquet"); on.exit(unlink(src), add = TRUE)
    arrow::write_parquet(data.frame(v = 1:5), src)
    ddf <- DuckDBDataFrame(src)

    dir <- tempfile()
    writeDuckDBTableParquet(ddf, dir, indexcol = "__index__", keycol = NULL,
                            part = 0L, part_digits = 2L, append = FALSE,
                            index_max = Inf)                      # part 0 int64
    writeDuckDBTableParquet(ddf, dir, indexcol = "__index__", keycol = NULL,
                            offset = 5, part = 1L, part_digits = 2L,
                            append = TRUE)                        # no index_max
    types <- .f1IndexType(dir)
    expect_length(types, 2L)
    expect_true(all(types == "int64"))    # append pinned to part 0, not narrowed
})

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Factor preservation on the lazy write path, and splitParquetPart safety
###

test_that("writeDuckDBTableParquet preserves factor levels recorded in collevels", {
    skip_if_not_installed("arrow")
    src <- tempfile(fileext = ".parquet"); on.exit(unlink(src), add = TRUE)
    # 'zz' is deliberately unused: it cannot be recovered from the written
    # values, so it only survives if collevels is consulted on write.
    arrow::write_parquet(
        data.frame(g = c("a", "b", "a", "c"), o = c("lo", "hi", "lo", "hi"),
                   stringsAsFactors = FALSE),
        src)
    ddf <- DuckDBDataFrame(src, collevels = list(
        g = list(levels = c("a", "b", "c", "zz"), ordered = FALSE),
        o = list(levels = c("lo", "hi"), ordered = TRUE)))

    dir <- tempfile(); on.exit(unlink(dir, recursive = TRUE), add = TRUE)
    res <- writeDuckDBTableParquet(ddf, dir, indexcol = NULL, keycol = NULL)

    pq <- arrow::read_parquet(res$path)
    expect_s3_class(pq$g, "factor")
    expect_identical(levels(pq$g), c("a", "b", "c", "zz"))
    expect_false(is.ordered(pq$g))
    expect_identical(as.character(pq$g), c("a", "b", "a", "c"))

    expect_true(is.ordered(pq$o))
    expect_identical(levels(pq$o), c("lo", "hi"))

    # the returned sample_df drives the caller's schema inference, so it must
    # see the factors too
    expect_s3_class(res$sample_df$g, "factor")
    expect_identical(levels(res$sample_df$g), c("a", "b", "c", "zz"))
})

test_that("writeDuckDBTableParquet leaves non-factor columns alone", {
    skip_if_not_installed("arrow")
    src <- tempfile(fileext = ".parquet"); on.exit(unlink(src), add = TRUE)
    arrow::write_parquet(data.frame(v = 1:4, s = letters[1:4]), src)
    ddf <- DuckDBDataFrame(src)

    dir <- tempfile(); on.exit(unlink(dir, recursive = TRUE), add = TRUE)
    res <- writeDuckDBTableParquet(ddf, dir, indexcol = NULL, keycol = NULL)

    pq <- arrow::read_parquet(res$path)
    expect_type(pq$s, "character")
    expect_identical(pq$v, 1:4)
})

test_that("splitParquetPart preserves row order and factor levels", {
    skip_if_not_installed("arrow")
    dir <- tempfile(); dir.create(dir)
    on.exit(unlink(dir, recursive = TRUE), add = TRUE)
    df <- data.frame(
        i = 1:12,
        g = factor(rep(c("a", "b", "c"), 4L), levels = c("a", "b", "c", "zz")))
    arrow::write_parquet(df, file.path(dir, "part-0.parquet"))

    out <- splitParquetPart(dir, 3L)
    expect_length(out, 3L)

    back <- do.call(rbind, lapply(out, arrow::read_parquet))
    expect_identical(back$i, 1:12)                    # contiguous, in order
    expect_s3_class(back$g, "factor")
    expect_identical(levels(back$g), c("a", "b", "c", "zz"))
})

test_that("splitParquetPart rolls back the source when the copy fails", {
    skip_if_not_installed("arrow")
    # The source file is the only copy of the data once the split parts are in
    # a temp dir, so a failed copy must not leave the directory empty.
    dir <- tempfile(); dir.create(dir)
    on.exit(unlink(dir, recursive = TRUE), add = TRUE)
    src <- file.path(dir, "part-0.parquet")
    arrow::write_parquet(data.frame(i = 1:12), src)

    local_mocked_bindings(file.copy = function(...) FALSE, .package = "base")
    expect_error(splitParquetPart(dir, 3L), "original file is unchanged")

    expect_true(file.exists(src))
    expect_identical(arrow::read_parquet(src)$i, 1:12)
    expect_identical(list.files(dir), "part-0.parquet")   # no stray .bak
})

test_that("splitParquetPart leaves the source intact when it cannot write", {
    skip_if_not_installed("arrow")
    skip_on_os("windows")

    dir <- tempfile(); dir.create(dir)
    on.exit({ Sys.chmod(dir, "0755"); unlink(dir, recursive = TRUE) }, add = TRUE)
    src <- file.path(dir, "part-0.parquet")
    df <- data.frame(i = 1:12)
    arrow::write_parquet(df, src)

    # Skip where the read-only bit does not actually deny writes, rather than
    # probing for root: this also covers filesystems that ignore permissions.
    Sys.chmod(dir, "0555")                            # no writes into 'dir'
    skip_if(file.access(dir, mode = 2L) == 0L,
            "directory permissions are not enforced here")

    expect_error(splitParquetPart(dir, 3L))

    # the original file must still be there, and still readable
    Sys.chmod(dir, "0755")
    expect_true(file.exists(src))
    expect_identical(arrow::read_parquet(src)$i, 1:12)
    expect_length(list.files(dir), 1L)                # no stray .bak left behind
})

test_that("factor restoration leaves no open mapping on the files it touches", {
    skip_if_not_installed("arrow")
    # arrow's default memory-mapped read leaves a mapping that Windows refuses
    # to write over, rename, or unlink ("[Windows error 1224] ... a file with a
    # user-mapped section open"). Both helpers rewrite a file in place, and
    # splitParquetPart() then renames and unlinks its source, so every read on
    # that path must pass mmap = FALSE. This assertion is a no-op on POSIX but
    # pins the invariant for the Windows builders.
    dir <- tempfile(); dir.create(dir)
    on.exit(unlink(dir, recursive = TRUE), add = TRUE)
    src <- file.path(dir, "part-0.parquet")
    arrow::write_parquet(
        data.frame(i = 1:12,
                   g = factor(rep(c("a", "b", "c"), 4L),
                              levels = c("a", "b", "c", "zz"))),
        src)

    # .findFactorColumns() must not pin the file it inspects
    expect_identical(DuckDBDataFrame:::.findFactorColumns(src), "g")
    moved <- paste0(src, ".moved")
    expect_true(file.rename(src, moved))
    expect_true(file.rename(moved, src))

    # readParquetSchema() reads a schema off the same kind of file and is
    # exported, so it must not pin it either
    expect_true(inherits(readParquetSchema(dir, columns = c("i", "g")), "Schema"))
    expect_true(file.rename(src, moved))
    expect_true(file.rename(moved, src))

    # after splitParquetPart(), the source is gone and every part is rewritable
    parts <- splitParquetPart(dir, 3L)
    expect_false(file.exists(paste0(src, ".bak")))
    for (p in parts) {
        expect_true(file.rename(p, paste0(p, ".x")))
        expect_true(file.rename(paste0(p, ".x"), p))
    }
    expect_true(all(file.remove(parts)))
})

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Regression: sample_df for schema inference must not depend on HOW it is
### computed (query + LIMIT vs. the old full-file reread via
### arrow::read_parquet()). The file written to 'res$path' is unaffected by
### the fix, so re-reading and truncating it the old way is a faithful
### ground truth to compare 'res$sample_df' against.
###

.oldSampleDF <- function(path, sample_n) {
    df <- as.data.frame(arrow::read_parquet(path, mmap = FALSE))
    if (nrow(df) > sample_n)
        df <- df[seq_len(sample_n), , drop = FALSE]
    df
}

.expectSampleMatchesOldReread <- function(res, sample_n) {
    old <- .oldSampleDF(res$path, sample_n)
    expect_identical(names(res$sample_df), names(old))
    expect_identical(nrow(res$sample_df), nrow(old))
    for (col in names(old)) {
        expect_identical(class(res$sample_df[[col]]), class(old[[col]]),
                         info = paste("column", col))
        # The query-based sample has no ORDER BY (adding one to pin row order
        # reintroduces the materialize-before-LIMIT cost this fix removes),
        # so it may return a differently-ordered subset of the same rows than
        # a sequential file reread. That's immaterial to callers: sample_df
        # only ever feeds per-column, order-independent type/shape inference
        # (.fieldtype()), never a row-aligned view across columns. Compare
        # value *sets* (or, for list columns, sorted lengths), not
        # row-for-row, to avoid a brittle false failure.
        if (is.list(old[[col]])) {
            expect_equal(sort(lengths(res$sample_df[[col]])),
                         sort(lengths(old[[col]])), info = paste("column", col))
        } else {
            expect_equal(sort(as.character(res$sample_df[[col]])),
                         sort(as.character(old[[col]])), info = paste("column", col))
        }
    }
}

test_that("writeDuckDBTableParquet sample_df matches an old-style full reread (small table, mixed types)", {
    skip_if_not_installed("arrow")
    tf <- tempfile(fileext = ".parquet")
    on.exit(unlink(tf), add = TRUE)
    # 'bignum'/'unum' are deliberately typed BIGINT/UINTEGER with small values:
    # arrow's int64/uint32 -> R conversion narrows these to plain integer when
    # read back from a file, which a naive DBI fetch from DuckDB would not do.
    tab <- arrow::arrow_table(
        id = letters[1:8],
        v = 1:8L,
        x = as.double(1:8) / 2,
        lgl = c(TRUE, FALSE, NA, TRUE, FALSE, TRUE, NA, FALSE),
        g = c("a", "b", "a", "c", "b", "a", "c", "b"),
        bignum = arrow::Array$create(1:8L, type = arrow::int64()),
        unum = arrow::Array$create(1:8L, type = arrow::uint32()))
    arrow::write_parquet(tab, tf)

    ddf <- DuckDBDataFrame(tf, datacols = c("v", "x", "lgl", "g", "bignum", "unum"),
                           keycol = "id",
                           collevels = list(g = list(levels = c("a", "b", "c", "zz"),
                                                     ordered = FALSE)))
    x <- as(ddf, "DuckDBTable")

    out <- tempfile(); dir.create(out)
    on.exit(unlink(out, recursive = TRUE), add = TRUE)
    res <- writeDuckDBTableParquet(x, out, indexcol = "__index__", keycol = "__name__")

    expect_identical(res$nrow, 8L)
    .expectSampleMatchesOldReread(res, min(100L, res$nrow))
    expect_s3_class(res$sample_df$g, "factor")
    expect_identical(levels(res$sample_df$g), c("a", "b", "c", "zz"))
})

test_that("writeDuckDBTableParquet sample_df matches an old-style full reread (list/embedding column)", {
    skip_if_not_installed("arrow")
    tf <- tempfile(fileext = ".parquet")
    on.exit(unlink(tf), add = TRUE)
    tab <- arrow::arrow_table(
        v = arrow::Array$create(list(1:2L, 1:3L, 1:2L, 1:2L),
                                type = arrow::list_of(arrow::int32())))
    arrow::write_parquet(tab, tf)
    ddf <- DuckDBDataFrame(tf)
    x <- as(ddf, "DuckDBTable")

    out <- tempfile(); dir.create(out)
    on.exit(unlink(out, recursive = TRUE), add = TRUE)
    res <- writeDuckDBTableParquet(x, out, indexcol = "__index__", keycol = NULL)

    expect_identical(res$nrow, 4L)
    .expectSampleMatchesOldReread(res, min(100L, res$nrow))

    # a list column's field-spec length constraint (BiocDuckDB's
    # .fieldtype.list()) is estimated from lengths() of the sampled column;
    # confirm that estimate is unaffected by switching how the sample itself
    # is fetched.
    lens <- lengths(res$sample_df$v)
    expect_identical(lens, c(2L, 3L, 2L, 2L))
    expect_true(is.list(res$sample_df$v))
})

test_that("writeDuckDBTableParquet sample_df matches an old-style full reread (large table, narrowed __index__)", {
    skip_if_not_installed("arrow")
    n <- 5000L
    tf <- tempfile(fileext = ".parquet")
    on.exit(unlink(tf), add = TRUE)
    set.seed(42)
    df <- data.frame(v = sample(1:1000, n, replace = TRUE),
                     x = rnorm(n),
                     s = sample(letters[1:5], n, replace = TRUE),
                     stringsAsFactors = FALSE)
    arrow::write_parquet(df, tf)
    ddf <- DuckDBDataFrame(tf)
    x <- as(ddf, "DuckDBTable")

    # index_max forces a wide (int64) __index__ -- the scenario that
    # motivated .sampleIndexColumn()'s magnitude handling.
    out <- tempfile(); dir.create(out)
    on.exit(unlink(out, recursive = TRUE), add = TRUE)
    res <- writeDuckDBTableParquet(x, out, indexcol = "__index__", keycol = NULL,
                                   index_max = Inf)

    expect_identical(res$nrow, n)
    expect_identical(nrow(res$sample_df), 100L)
    .expectSampleMatchesOldReread(res, 100L)
    # with index_max = Inf, arrow narrows __index__ back to plain integer
    # for these small (1..100) sample values, same as the old reread.
    expect_identical(class(res$sample_df$`__index__`), "integer")

    # without index_max, the small table narrows to the smallest unsigned
    # type that fits -- exercise a non-BIGINT branch of .sampleIndexColumn().
    out2 <- tempfile(); dir.create(out2)
    on.exit(unlink(out2, recursive = TRUE), add = TRUE)
    res2 <- writeDuckDBTableParquet(x, out2, indexcol = "__index__", keycol = NULL)
    .expectSampleMatchesOldReread(res2, 100L)
})

test_that("writeDuckDBTableParquet falls back gracefully when nanoarrow is unavailable", {
    skip_if_not_installed("arrow")
    # duckdb's Arrow export (dbSendQueryArrow()/dbFetchArrow()) requires
    # 'nanoarrow', which duckdb itself only Suggests (not a hard dependency),
    # so it may not be installed. Confirm the schema-sampling step falls back
    # to the pre-optimization full-file reread instead of erroring, and still
    # produces the same sample as that old reread.
    tf <- tempfile(fileext = ".parquet")
    on.exit(unlink(tf), add = TRUE)
    set.seed(7)
    df <- data.frame(v = 1:20L, x = rnorm(20),
                     g = sample(letters[1:3], 20, replace = TRUE),
                     stringsAsFactors = FALSE)
    arrow::write_parquet(df, tf)
    x <- as(DuckDBDataFrame(tf), "DuckDBTable")

    out <- tempfile(); dir.create(out)
    on.exit(unlink(out, recursive = TRUE), add = TRUE)

    real_requireNamespace <- requireNamespace
    local_mocked_bindings(
        requireNamespace = function(package, ...) {
            if (identical(package, "nanoarrow")) return(FALSE)
            real_requireNamespace(package, ...)
        },
        .package = "base")

    expect_no_error(
        res <- writeDuckDBTableParquet(x, out, indexcol = "__index__", keycol = NULL))
    expect_identical(res$nrow, 20L)
    .expectSampleMatchesOldReread(res, min(100L, res$nrow))
})

test_that("writeDuckDBTableParquet sample_df matches an old-style full reread across a multi-part append", {
    skip_if_not_installed("arrow")
    tf1 <- tempfile(fileext = ".parquet")
    on.exit(unlink(tf1), add = TRUE)
    arrow::write_parquet(data.frame(v = 1:50), tf1)
    x1 <- as(DuckDBDataFrame(tf1), "DuckDBTable")

    out <- tempfile(); dir.create(out)
    on.exit(unlink(out, recursive = TRUE), add = TRUE)
    # index_max = Inf declares the physical column BIGINT, but this part's
    # own values (1..50) still fit in 32 bits, so arrow (and
    # .sampleIndexColumn()) narrow it to plain integer -- same as part 0 of
    # the "honors index_max" test above, just reached via the append path.
    res0 <- writeDuckDBTableParquet(x1, out, indexcol = "__index__", keycol = NULL,
                                    part = 0L, part_digits = 2L, index_max = Inf)
    expect_false(isTRUE(res0$subsequent_part))
    .expectSampleMatchesOldReread(res0, 50L)
    expect_identical(class(res0$sample_df$`__index__`),
                     class(.oldSampleDF(res0$path, 50L)$`__index__`))

    # Part 1 appends at a huge offset: __index__ is pinned to part 0's BIGINT
    # type, and this part's own range (offset+1 .. offset+30) now exceeds 32
    # bits, exercising .sampleIndexColumn()'s integer64 branch for real.
    big_offset <- 3000000000
    tf2 <- tempfile(fileext = ".parquet")
    on.exit(unlink(tf2), add = TRUE)
    arrow::write_parquet(data.frame(v = 51:80), tf2)
    x2 <- as(DuckDBDataFrame(tf2), "DuckDBTable")
    res1 <- writeDuckDBTableParquet(x2, out, indexcol = "__index__", keycol = NULL,
                                    offset = big_offset, part = 1L, part_digits = 2L,
                                    append = TRUE)
    expect_true(isTRUE(res1$subsequent_part))
    # Still computed (the caller decides whether to use it), still correct.
    .expectSampleMatchesOldReread(res1, 30L)
    expect_true(bit64::is.integer64(res1$sample_df$`__index__`))
    expect_true(all(res1$sample_df$`__index__` > big_offset))
})

test_that(".sampleIndexColumn mirrors arrow's int64/uint32 downcast rules", {
    # narrow types never need widening
    expect_identical(.sampleIndexColumn(0, 3L, 3L, "TINYINT"), 1:3)
    expect_identical(.sampleIndexColumn(0, 3L, 3L, "UTINYINT"), 1:3)
    # UINTEGER/BIGINT narrow to plain integer only if the FULL column (not
    # just the sample) fits in 32 bits
    expect_identical(.sampleIndexColumn(0, 3L, 3L, "UINTEGER"), 1:3)
    expect_identical(.sampleIndexColumn(0, 3L, 3L, "BIGINT"), 1:3)
    expect_identical(class(.sampleIndexColumn(0, 3L, 3e9, "UINTEGER")), "numeric")
    expect_true(bit64::is.integer64(.sampleIndexColumn(0, 3L, 3e9, "BIGINT")))
    # UBIGINT never narrows, even for tiny values
    expect_identical(class(.sampleIndexColumn(0, 3L, 3L, "UBIGINT")), "numeric")
    # an empty sample still returns a zero-length vector of the right class
    expect_identical(.sampleIndexColumn(0, 0L, 3e9, "BIGINT"), bit64::integer64())
})
