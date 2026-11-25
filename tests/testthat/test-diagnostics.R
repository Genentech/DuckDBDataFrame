# What a failure says, how a very large collection is refused, and a dry run
# of a write that agrees with the write.

.diag_table <- function(extra = NULL) {
    d <- data.frame(id = c("a", "b", "c"), v = c(3, 1, 2), n = c(1L, 2L, NA))
    if (!is.null(extra))
        d <- cbind(d, extra, stringsAsFactors = FALSE)
    path <- tempfile(fileext = ".parquet")
    arrow::write_parquet(d, path)
    list(path = path, table = DuckDBDataFrame(path, datacols = setdiff(names(d), "id"), keycol = "id"))
}

test_that("an error of DuckDB is a classed condition whose message is the cause", {
    d <- .diag_table()
    on.exit(unlink(d$path))
    big <- DuckDBDataFrame(d$path, datacols = "n", keycol = "id")[["n"]] * 2000000000L
    err <- tryCatch(as.vector(big), error = function(e) e)
    expect_s3_class(err, "duckdbdataframe_error")
    expect_s3_class(err, "duckdb_out_of_range")
    expect_match(conditionMessage(err), "^DuckDB could not read the values: ")
    expect_match(conditionMessage(err), "Overflow")
    # the query and the stack of messages are not the message, and the original is kept
    expect_false(grepl("SELECT|Backtrace|Caused by", conditionMessage(err)))
    expect_s3_class(err$parent, "error")
    expect_identical(sum(grepl("\n", conditionMessage(err), fixed = TRUE)), 0L)
})

test_that("an error that is not from DuckDB is left as it is", {
    expect_error(.withDuckDBError(stop("plain"), "do it"), "^plain$")
    err <- tryCatch(.withDuckDBError(stop("plain"), "do it"), error = function(e) e)
    expect_false(inherits(err, "duckdbdataframe_error"))
})

test_that("a failed write is a classed condition as well", {
    d <- .diag_table()
    on.exit(unlink(d$path))
    big <- DuckDBDataFrame(d$path, datacols = "n", keycol = "id")[["n"]] * 2000000000L
    out <- tempfile()
    on.exit(unlink(out, recursive = TRUE), add = TRUE)
    err <- tryCatch(writeDuckDBTableParquet(big@table, out), error = function(e) e)
    expect_s3_class(err, "duckdbdataframe_error")
    expect_match(conditionMessage(err), "^DuckDB could not write the Parquet file: ")
})

test_that("a collection of too many values is refused before it is run", {
    d <- .diag_table()
    on.exit(unlink(d$path))
    old <- options(DuckDBDataFrame.max_cells = 5)
    on.exit(options(old), add = TRUE)
    err <- tryCatch(as.data.frame(d$table), error = function(e) e)
    expect_s3_class(err, "duckdbdataframe_too_large")
    expect_match(conditionMessage(err), "3 rows of 3 columns would put 9 values in memory")
    expect_match(conditionMessage(err), "DuckDBDataFrame.max_cells")
    expect_s3_class(as.data.frame(head(d$table, 1L)), "data.frame")
    options(DuckDBDataFrame.max_cells = Inf)
    expect_identical(nrow(as.data.frame(d$table)), 3L)
    options(DuckDBDataFrame.max_cells = "many")
    expect_error(as.data.frame(d$table), "single number")
})

test_that("the dry run reports what the write writes, and what it refuses", {
    d <- .diag_table()
    on.exit(unlink(d$path))
    rep <- checkWritable(d$table)
    expect_s3_class(rep, "checkWritable")
    expect_true(rep$writable)
    res <- writeDuckDBTableParquet(d$table, tempfile())
    expect_identical(rep$columns, names(arrow::read_parquet(res$path)))
    expect_output(print(rep), "writable, with the columns: __index__, __name__, v, n")

    clash <- .diag_table(data.frame(`__INDEX__` = c(7, 8, 9), check.names = FALSE))
    on.exit(unlink(clash$path), add = TRUE)
    bad <- checkWritable(clash$table)
    expect_false(bad$writable)
    expect_match(bad$problems, "the row index")
    expect_error(writeDuckDBTableParquet(clash$table, tempfile()), bad$problems, fixed = TRUE)
    expect_output(print(bad), "not writable")
    # without an index the name is free, and the report says so
    expect_true(checkWritable(clash$table, indexcol = NULL)$writable)
})
