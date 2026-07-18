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

    ordered <- DuckDBDataFrame(tf, datacols = "g", keycol = "id",
                              collevels = list(g = list(levels = c("A", "B", "C"),
                                                        ordered = TRUE)))
    expect_true(is.ordered(as.data.frame(ordered)[["g"]]))

    # a recast column is no longer a factor
    recast <- ddf
    coltypes(recast) <- c(g = "character")
    expect_false(is.factor(as.data.frame(recast)[["g"]]))
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
