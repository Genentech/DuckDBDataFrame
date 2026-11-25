# DuckDB binds a column name without regard to case, so a query that holds both
# Sex and sex returns the values of Sex for either. A table read from a file
# with such names is correct (DuckDB renames the second to sex_1 and the table
# maps sex to it), but any SQL that refers to a column by name has to avoid the
# clash, and a file cannot be written with two such names.

.collision_file <- function(extra = NULL) {
    d <- data.frame(id = c("a", "b", "c", "d"),
                    Sex = c("M", "F", "M", "F"),
                    sex = c("male", "female", "male", "male"),
                    n = c(1, 2, 1, 3),
                    check.names = FALSE)
    if (!is.null(extra))
        d <- cbind(d, extra)
    path <- tempfile(fileext = ".parquet")
    arrow::write_parquet(d, path)
    list(path = path, data = d)
}

.collision_table <- function(f, datacols) {
    DuckDBDataFrame(f$path, datacols = datacols, keycol = "id")
}

.written <- function(x, ...) {
    res <- writeDuckDBTableParquet(x, tempfile(), ...)
    as.data.frame(arrow::read_parquet(res$path))
}

test_that("checkParquetColumnNames refuses names that are the same up to case", {
    expect_identical(checkParquetColumnNames(c("a", "b", "A_1")), c("a", "b", "A_1"))
    expect_identical(checkParquetColumnNames(character()), character())
    expect_error(checkParquetColumnNames(c("Sex", "id", "sex")), "'Sex', 'sex'")
    expect_error(checkParquetColumnNames(c("x", "x")), "same name, ignoring case")
    expect_error(checkParquetColumnNames(c("a", "A", "b", "B")), "'a', 'A'.*'b', 'B'")
    expect_error(checkParquetColumnNames(c("Sex", "sex")), "case-insensitive")
})

test_that("a table read from a file with names that clash up to case has the right values", {
    f <- .collision_file()
    on.exit(unlink(f$path))
    df <- .collision_table(f, c("Sex", "sex", "n"))
    expect_identical(colnames(df), c("Sex", "sex", "n"))
    expect_identical(unname(as.vector(df[["Sex"]])), f$data$Sex)
    expect_identical(unname(as.vector(df[["sex"]])), f$data$sex)
    sub <- df[c("c", "a"), ]
    expect_identical(unname(as.vector(sub[["sex"]])), c("male", "male"))
    expect_identical(unname(as.vector(df[["sex"]] %in% "female")), c(FALSE, TRUE, FALSE, FALSE))
})

test_that("the lazy writer writes the column that the table exposes, not one of the same name up to case", {
    f <- .collision_file()
    on.exit(unlink(f$path))

    # only sex is exposed, and the query still holds Sex
    w <- .written(.collision_table(f, "sex"))
    expect_identical(colnames(w), c("__index__", "__name__", "sex"))
    expect_identical(w$sex, f$data$sex)
    w <- .written(.collision_table(f, c("sex", "n")))
    expect_identical(w$sex, f$data$sex)
    expect_identical(w$n, f$data$n)
    w <- .written(.collision_table(f, "Sex"))
    expect_identical(w$Sex, f$data$Sex)
})

test_that("the lazy writer refuses columns whose names clash up to case", {
    f <- .collision_file()
    on.exit(unlink(f$path))
    both <- .collision_table(f, c("Sex", "sex"))
    expect_error(writeDuckDBTableParquet(both, tempfile()), "'Sex', 'sex'")
    expect_error(buildTableSelectSQL(both, indexcol = "__index__", keycol = "__name__"),
                 "same name, ignoring case")
})

test_that("a key named like a data column up to case is written correctly", {
    # the file can hold both: the key becomes __name__
    d <- data.frame(id = c("a", "b", "c"), ID = c("X", "Y", "Z"))
    path <- tempfile(fileext = ".parquet")
    arrow::write_parquet(d, path)
    on.exit(unlink(path))
    w <- .written(DuckDBDataFrame(path, datacols = "ID", keycol = "id"))
    expect_identical(colnames(w), c("__index__", "__name__", "ID"))
    expect_identical(w[["__name__"]], d$id)
    expect_identical(w$ID, d$ID)
})

test_that("a column named __position__ is written unchanged next to the position", {
    d <- data.frame(id = c("c", "a", "b"), x = c(3, 1, 2),
                    `__position__` = c(900, 700, 800), check.names = FALSE)
    path <- tempfile(fileext = ".parquet")
    arrow::write_parquet(d, path)
    on.exit(unlink(path))
    w <- .written(DuckDBDataFrame(path, datacols = c("x", "__position__"), keycol = "id"))
    expect_identical(w[["__name__"]], c("a", "b", "c"))
    expect_identical(w[["__position__"]], c(700, 800, 900))
})

test_that("unique and table follow the column that is asked for, not one of the same name up to case", {
    f <- .collision_file()
    on.exit(unlink(f$path))
    df <- .collision_table(f, c("Sex", "sex", "n"))

    expect_identical(unname(as.vector(unique(df[["sex"]]))), unique(f$data$sex))
    expect_identical(unname(as.vector(unique(df[["Sex"]]))), unique(f$data$Sex))
    expect_identical(unname(as.vector(unique(df[["sex"]], fromLast = TRUE))),
                     unique(f$data$sex, fromLast = TRUE))
    # a column that is an expression, whose expression is not its name
    expect_identical(unname(as.vector(unique(df[["n"]] * 2))), unique(f$data$n * 2))

    tab <- table(df[["sex"]])
    expect_identical(names(dimnames(tab)), "sex")
    expect_identical(as.vector(tab), as.vector(table(f$data$sex)))
    expect_identical(names(tab), names(table(f$data$sex)))
    tab2 <- table(df[["Sex"]])
    expect_identical(as.vector(tab2), as.vector(table(f$data$Sex)))
    # a table of two columns keeps the names of both
    two <- table(.collision_table(f, c("Sex", "sex")))
    expect_identical(names(dimnames(two)), c("Sex", "sex"))
    expect_identical(unname(as.vector(two)), as.vector(table(f$data$Sex, f$data$sex)))
})

test_that("assigning a column named like another up to case keeps both columns correct", {
    f <- .collision_file()
    on.exit(unlink(f$path))
    df <- .collision_table(f, "Sex")
    x <- df
    x[["sex"]] <- tolower(df[["Sex"]])
    expect_identical(unname(as.vector(x[["Sex"]])), f$data$Sex)
    expect_identical(unname(as.vector(x[["sex"]])), tolower(f$data$Sex))
})

test_that("log takes its base, as in base R", {
    d <- data.frame(id = c("a", "b", "c"), x = c(2, 8, 100))
    path <- tempfile(fileext = ".parquet")
    arrow::write_parquet(d, path)
    on.exit(unlink(path))
    tbl <- DuckDBDataFrame(path, datacols = "x", keycol = "id")
    col <- tbl[["x"]]
    for (base in list(2, 10, 3, 0.5, exp(1))) {
        expect_equal(unname(as.vector(log(col, base))), log(d$x, base))
        expect_equal(unname(as.vector(log(tbl, base)[["x"]])), log(d$x, base))
    }
    expect_equal(unname(as.vector(log(col, base = 10))), log10(d$x))
    expect_equal(unname(as.vector(log(col))), log(d$x))
    for (base in list(1, 0, -2, NA_real_, c(2, 3), "2"))
        expect_error(log(col, base), "'base'")
})
