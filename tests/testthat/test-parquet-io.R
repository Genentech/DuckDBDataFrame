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
