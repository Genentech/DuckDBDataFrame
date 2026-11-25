# The names of the columns, and of the entries that become files, are checked in
# one place each, and the names that the code gives to its own columns cannot be
# taken for the columns of the user.

.name_file <- function(...) {
    d <- data.frame(id = c("a", "b", "c"), v = c(3, 1, 2), ..., check.names = FALSE)
    path <- tempfile(fileext = ".parquet")
    arrow::write_parquet(d, path)
    list(path = path, data = d)
}

test_that("checkParquetColumnNames refuses NA, empty and non-character names", {
    expect_error(checkParquetColumnNames(c("a", NA)), "must not be NA.*positions 2")
    expect_error(checkParquetColumnNames(c("a", "", "")), "must not be empty.*positions 2, 3")
    expect_error(checkParquetColumnNames(NULL), "character vector, not NULL")
    expect_error(checkParquetColumnNames(1:2), "character vector, not integer")
    expect_identical(checkParquetColumnNames(c("a", "__b__")), c("a", "__b__"))
})

test_that("checkParquetColumnNames folds the letters A to Z only, as DuckDB does", {
    accent <- c("\u00c9", "\u00e9")
    expect_identical(checkParquetColumnNames(accent), accent)
    expect_error(checkParquetColumnNames(c("\u00c9a", "\u00c9A")), "same name")
    # DuckDB does not bind the one name to the other
    con <- DBI::dbConnect(duckdb::duckdb(), shared_home = FALSE)
    on.exit(DBI::dbDisconnect(con, shutdown = TRUE))
    expect_error(DBI::dbGetQuery(con, sprintf("SELECT \"%s\" FROM (SELECT 1 AS \"%s\") t",
                                              accent[2L], accent[1L])))
})

test_that("checkEntryNames refuses names that cannot be files or are the same up to case", {
    expect_identical(checkEntryNames("assays", c("counts", "logcounts")),
                     c("counts", "logcounts"))
    expect_identical(checkEntryNames("assays", NULL), character())
    expect_identical(checkEntryNames("assays", character()), character())
    expect_error(checkEntryNames("assays", c("counts", "Counts")),
                 "assays include names that are the same, ignoring case: \\('counts', 'Counts'\\)")
    expect_error(checkEntryNames("assays", c("a/b", "c")), "a/b")
    expect_error(checkEntryNames("assays", "a\\b"), "a\\\\b")
    expect_error(checkEntryNames("assays", c("..", "x")), "'\\.\\.'")
    expect_error(checkEntryNames("assays", "."), "become file names")
    expect_error(checkEntryNames("assays", "a\nb"), "become file names")
    expect_error(checkEntryNames("assays", c("a", NA)), "must not be NA or empty.*positions 2")
    expect_error(checkEntryNames("assays", c("a", "")), "must not be NA or empty")
    expect_error(checkEntryNames("assays", 1:2), "must be a character vector")
    expect_error(checkEntryNames("assays", c("a", "B"), reserved = "b"),
                 "reserved: 'B'")
    expect_error(checkEntryNames(NA, "a"), "'kind'")
})

test_that("fresh names differ from the names of the user without regard to case", {
    fresh <- DuckDBDataFrame:::.freshName
    expect_identical(fresh(c("a", "b"), "__x__"), "__x__")
    expect_identical(fresh(c("a", "__x__"), "__x__"), "__x___1")
    expect_identical(fresh(c("a", "__X__", "__x___1"), "__x__"), "__x___2")
    expect_identical(fresh(character(), "__x__"), "__x__")
    expect_identical(DuckDBDataFrame:::.freshNames(c("__G1__"), c("__g1__", "__g2__")),
                     c("__g1___1", "__g2__"))
    expect_identical(DuckDBDataFrame:::.freshNames(character(), c("n", "n")), c("n", "n_1"))
})

test_that("the lazy writer refuses a column that is named like the index, the key or a dimtbl column", {
    f <- .name_file(`__index__` = c(50, 60, 70))
    on.exit(unlink(f$path))
    x <- DuckDBDataFrame(f$path, datacols = c("v", "__index__"), keycol = "id")
    expect_error(writeDuckDBTableParquet(x, tempfile()),
                 "column named '__index__'.*the row index")
    # a case that differs is the same name to DuckDB
    g <- .name_file(`__INDEX__` = c(50, 60, 70))
    on.exit(unlink(g$path), add = TRUE)
    y <- DuckDBDataFrame(g$path, datacols = c("v", "__INDEX__"), keycol = "id")
    expect_error(writeDuckDBTableParquet(y, tempfile()), "the row index")

    h <- .name_file(`__name__` = c("U", "V", "W"))
    on.exit(unlink(h$path), add = TRUE)
    z <- DuckDBDataFrame(h$path, datacols = c("v", "__name__"), keycol = "id")
    expect_error(writeDuckDBTableParquet(z, tempfile()), "the row names")

    k <- .name_file(part = c("p", "q", "r"))
    on.exit(unlink(k$path), add = TRUE)
    w <- DuckDBDataFrame(k$path, datacols = c("v", "part"), keycol = "id")
    expect_error(writeDuckDBTableParquet(w, tempfile(),
                                         dimtbl = S4Vectors::DataFrame(part = "one")),
                 "a column of 'dimtbl'")
    # without an index or a key column to write, the name is free
    out <- writeDuckDBTableParquet(x, tempfile(), indexcol = NULL, keycol = NULL)
    expect_true("__index__" %in% names(arrow::read_parquet(out$path)))
})

test_that("a key named like the index is the key, not a column that is left out", {
    d <- data.frame(`__index__` = c("a", "b", "c"), v = c(3, 1, 2), check.names = FALSE)
    path <- tempfile(fileext = ".parquet")
    arrow::write_parquet(d, path)
    on.exit(unlink(path))
    x <- DuckDBDataFrame(path, datacols = "v", keycol = "__index__")
    res <- writeDuckDBTableParquet(x, tempfile())
    w <- as.data.frame(arrow::read_parquet(res$path))
    expect_identical(names(w), c("__index__", "__name__", "v"))
    expect_identical(w[["__name__"]], d[["__index__"]])
    expect_equal(as.integer(w[["__index__"]]), 1:3)
})

test_that("the columns that the code adds cannot be mistaken for the columns of the user", {
    f <- .name_file(`__POSITION__` = c(9, 8, 7), `__G1__` = c("x", "y", "x"),
                    `__Alias__` = c(1, 2, 3), ROW_NUMBER = c(5, 6, 7))
    on.exit(unlink(f$path))
    x <- DuckDBDataFrame(f$path, datacols = c("v", "__POSITION__", "__G1__",
                                              "__Alias__", "ROW_NUMBER"),
                         keycol = "id")
    res <- writeDuckDBTableParquet(x, tempfile())
    w <- as.data.frame(arrow::read_parquet(res$path))
    expect_identical(w[["__name__"]], c("a", "b", "c"))
    expect_equal(as.integer(w[["__index__"]]), 1:3)
    expect_identical(w[["__POSITION__"]], c(9, 8, 7))
    expect_identical(w[["__G1__"]], c("x", "y", "x"))
    expect_identical(w[["ROW_NUMBER"]], c(5, 6, 7))

    expect_identical(unname(as.vector(unique(x[["__G1__"]]))), c("x", "y"))
    expect_identical(as.vector(table(x[["__G1__"]])), c(2L, 1L))
    expect_identical(unname(as.vector(unique(x[["__POSITION__"]], fromLast = TRUE))),
                     c(9, 8, 7))
    tab <- table(x[["__G1__"]])
    expect_identical(names(dimnames(tab)), "__G1__")
})

test_that("splitParquetPart names its own columns apart from the columns of the file", {
    dir <- tempfile(); dir.create(dir)
    on.exit(unlink(dir, recursive = TRUE))
    df <- data.frame(i = 1:12, `__SPLIT_PART__` = 12:1, check.names = FALSE)
    arrow::write_parquet(df, file.path(dir, "part-0.parquet"))
    seed <- .Random.seed
    out <- splitParquetPart(dir, 3L)
    expect_identical(.Random.seed, seed)       # no random draw for a table name
    back <- do.call(rbind, lapply(out, arrow::read_parquet))
    expect_identical(as.data.frame(back), df)
})

test_that("splitParquetPart says why a file with a column file_row_number cannot be split", {
    dir <- tempfile(); dir.create(dir)
    on.exit(unlink(dir, recursive = TRUE))
    src <- file.path(dir, "part-0.parquet")
    arrow::write_parquet(data.frame(i = 1:6, File_Row_Number = 6:1), src)
    expect_error(splitParquetPart(dir, 2L), "'file_row_number'.*Rename")
    expect_identical(arrow::read_parquet(src)$i, 1:6)
})
