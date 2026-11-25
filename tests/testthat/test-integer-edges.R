# Integers at the ends of their range. The values are exact or the call fails:
# a number is never rounded to a double behind the back of the caller.

.int_edges <- function() {
    tb <- arrow::arrow_table(
        id = c("a", "b", "c"),
        u8 = arrow::Array$create(c(255L, 1L, NA), arrow::uint8()),
        i8 = arrow::Array$create(c(127L, -128L, 5L), arrow::int8()),
        i64 = arrow::Array$create(bit64::as.integer64(c("9007199254740993", "-9007199254740993", "3")),
                                  arrow::int64()))
    path <- tempfile(fileext = ".parquet")
    arrow::write_parquet(tb, path)
    list(path = path,
         table = DuckDBDataFrame(path, datacols = c("u8", "i8", "i64"), keycol = "id"))
}

test_that("a sum of narrow integers does not overflow", {
    e <- .int_edges()
    on.exit(unlink(e$path))
    expect_equal(sum(e$table[["u8"]], na.rm = TRUE), 256)
    expect_equal(sum(e$table[["i8"]]), 4)
    expect_equal(mean(e$table[["u8"]], na.rm = TRUE), 128)
})

test_that("arithmetic that overflows a narrow integer is an error, not a wrong value", {
    # base R widens these. DuckDB does the arithmetic in the type of the column
    # and refuses; a cast of the column is the way around it.
    e <- .int_edges()
    on.exit(unlink(e$path))
    expect_error(as.vector(e$table[["u8"]] + 1L), "Overflow")
    expect_error(as.vector(e$table[["i8"]] * 2L), "Overflow")
    expect_equal(unname(as.vector(e$table[["u8"]] + 0L)), c(255L, 1L, NA))
})

test_that("a 64 bit integer past 2^53 is read and compared exactly", {
    e <- .int_edges()
    on.exit(unlink(e$path))
    big <- as.vector(e$table[["i64"]])
    expect_s3_class(big, "integer64")
    expect_identical(as.character(big), c("9007199254740993", "-9007199254740993", "3"))
    expect_identical(as.character(as.vector(e$table[["i64"]] + 1L)),
                     c("9007199254740994", "-9007199254740992", "4"))
    expect_identical(as.character(sum(e$table[["i64"]])), "3")
    expect_identical(unname(as.vector(e$table[["i64"]] > 9007199254740992)),
                     c(TRUE, FALSE, FALSE))
})
