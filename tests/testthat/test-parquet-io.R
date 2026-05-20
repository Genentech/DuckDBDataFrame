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
