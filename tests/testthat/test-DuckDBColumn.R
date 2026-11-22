# Tests the basic functions of a DuckDBColumn.
# library(testthat); library(DuckDBDataFrame); source("setup.R"); source("test-DuckDBColumn.R")

test_that("head works for DuckDBColumn", {
    df <- DuckDBDataFrame(mtcars_parquet, datacols = colnames(mtcars), keycol = list(model = rownames(mtcars)))
    cyl <- df[["cyl"]]

    checkDuckDBColumn(head(cyl, 0), head(setNames(mtcars[["cyl"]], rownames(mtcars)), 0))
    checkDuckDBColumn(head(cyl, 20), head(setNames(mtcars[["cyl"]], rownames(mtcars)), 20))
})

test_that("tail works for DuckDBColumn", {
    df <- DuckDBDataFrame(mtcars_parquet, datacols = colnames(mtcars), keycol = list(model = rownames(mtcars)))
    cyl <- df[["cyl"]]

    checkDuckDBColumn(tail(cyl, 0), tail(setNames(mtcars[["cyl"]], rownames(mtcars)), 0))
    checkDuckDBColumn(tail(cyl, 20), tail(setNames(mtcars[["cyl"]], rownames(mtcars)), 20))
})

test_that("DuckDBColumn can be cast to a different type", {
    df <- DuckDBDataFrame(mtcars_parquet, datacols = colnames(mtcars), keycol = "model")
    cyl <- df[["cyl"]]

    checkDuckDBColumn(cyl, as.vector(cyl))

    type(cyl) <- "integer"
    expected <- as.vector(cyl)
    storage.mode(expected) <- "integer"
    checkDuckDBColumn(cyl, expected)
})

test_that("nonzero functions work for DuckDBColumn", {
    df <- DuckDBDataFrame(mtcars_parquet, datacols = colnames(mtcars), keycol = "model")
    am <- df[["am"]]
    checkDuckDBColumn(is_nonzero(am), is_nonzero(as.vector(am)))
    expect_equal(nzcount(am), nzcount(as.vector(am)))
})

test_that("unique works as expected for a DuckDBColumn", {
    df <- DuckDBDataFrame(mtcars_parquet, datacols = colnames(mtcars), keycol = "model")
    cyl <- df[["cyl"]]
    expected <- unique(as.vector(cyl))
    names(expected) <- NULL
    checkDuckDBColumn(unique(cyl), expected)
})

test_that("Arith methods work as expected for a DuckDBColumn", {
    df <- DuckDBDataFrame(mtcars_parquet, datacols = colnames(mtcars), keycol = "model")
    mpg <- df[["mpg"]]
    disp <- df[["disp"]]

    checkDuckDBColumn(mpg + disp, as.vector(mpg) + as.vector(disp))
    checkDuckDBColumn(+ mpg, + as.vector(mpg))
    checkDuckDBColumn(mpg - 1L, as.vector(mpg) - 1L)
    checkDuckDBColumn(- mpg, - as.vector(mpg))
    checkDuckDBColumn(mpg * 3.14, as.vector(mpg) * 3.14)
    checkDuckDBColumn(1L / mpg, 1L / as.vector(mpg))
    checkDuckDBColumn(3.14 ^ mpg, 3.14 ^ as.vector(mpg))
    checkDuckDBColumn(mpg %% disp, as.vector(mpg) %% as.vector(disp))
    checkDuckDBColumn(mpg %/% 3.14, as.vector(mpg) %/% 3.14)
})

test_that("Compare methods work as expected for a DuckDBColumn", {
    df <- DuckDBDataFrame(mtcars_parquet, datacols = colnames(mtcars), keycol = "model")
    vs <- df[["vs"]]
    am <- df[["am"]]

    checkDuckDBColumn(vs == am, as.vector(vs) == as.vector(am))
    checkDuckDBColumn(vs > 1L, as.vector(vs) > 1L)
    checkDuckDBColumn(vs < 1L, as.vector(vs) < 1L)
    checkDuckDBColumn(1L != vs, 1L != as.vector(vs))
    checkDuckDBColumn(1 <= vs, 1 <= as.vector(vs))
    checkDuckDBColumn(vs >= am, as.vector(vs) >= as.vector(am))
})

test_that("Logic methods work as expected for a DuckDBColumn", {
    df <- DuckDBDataFrame(mtcars_parquet, datacols = colnames(mtcars), keycol = "model")
    mpg <- df[["mpg"]]
    x <- mpg > 15
    y <- mpg < 25

    checkDuckDBColumn(x & y, as.vector(x) & as.vector(y))
    checkDuckDBColumn(x | y, as.vector(x) | as.vector(y))
    checkDuckDBColumn(!x, !as.vector(x))
})

test_that("Math methods work as expected for a DuckDBColumn", {
    df <- DuckDBDataFrame(mtcars_parquet, datacols = colnames(mtcars), keycol = "model")
    mpg <- df[["mpg"]]

    checkDuckDBColumn(abs(mpg), abs(as.vector(mpg)))
    checkDuckDBColumn(sqrt(mpg), sqrt(as.vector(mpg)))
    checkDuckDBColumn(ceiling(mpg), ceiling(as.vector(mpg)))
    checkDuckDBColumn(floor(mpg), floor(as.vector(mpg)))
    checkDuckDBColumn(trunc(mpg), trunc(as.vector(mpg)))

    expect_error(cummax(mpg))
    expect_error(cummin(mpg))
    expect_error(cumprod(mpg))
    expect_error(cumsum(mpg))

    checkDuckDBColumn(log(mpg), log(as.vector(mpg)))
    checkDuckDBColumn(log10(mpg), log10(as.vector(mpg)))
    checkDuckDBColumn(log2(mpg), log2(as.vector(mpg)))
    checkDuckDBColumn(log1p(mpg), log1p(as.vector(mpg)))
})

test_that("%in% works as expected for a DuckDBColumn", {
    df <- DuckDBDataFrame(mtcars_parquet, datacols = colnames(mtcars), keycol = "model")
    carb <- df[["carb"]]

    checkDuckDBColumn(carb %in% c(2, 4, 8), setNames(as.vector(carb) %in% c(2, 4, 8), names(carb)))
})

test_that("%in% never returns NA for a DuckDBColumn, like base R", {
    na_df <- data.frame(id = letters[1:5], x = c(1, NA, 3, 4, NA))
    na_path <- tempfile(fileext = ".parquet")
    arrow::write_parquet(na_df, na_path)
    on.exit(unlink(na_path))

    df <- DuckDBDataFrame(na_path, datacols = "x", keycol = "id")
    x <- df[["x"]]
    expected <- function(table) setNames(na_df$x %in% table, na_df$id)

    checkDuckDBColumn(x %in% c(1, 4), expected(c(1, 4)))
    checkDuckDBColumn(x %in% c(1, NA), expected(c(1, NA)))
    checkDuckDBColumn(x %in% NA, expected(NA))
    checkDuckDBColumn(x %in% numeric(0), expected(numeric(0)))
    expect_identical(sum(as.vector(x %in% c(1, 4))), 2L)
})

test_that("%in% keeps NA and NaN distinct for a DuckDBColumn, like base R", {
    nan_df <- data.frame(id = letters[1:6], x = c(1, NA, NaN, 4, NA, NaN))
    nan_path <- tempfile(fileext = ".parquet")
    arrow::write_parquet(nan_df, nan_path)
    on.exit(unlink(nan_path))

    x <- DuckDBDataFrame(nan_path, datacols = "x", keycol = "id")[["x"]]
    expected <- function(table) setNames(nan_df$x %in% table, nan_df$id)

    checkDuckDBColumn(x %in% NaN, expected(NaN))
    checkDuckDBColumn(x %in% NA, expected(NA))
    checkDuckDBColumn(x %in% c(1, NaN), expected(c(1, NaN)))
    checkDuckDBColumn(x %in% c(1, NA), expected(c(1, NA)))
    checkDuckDBColumn(x %in% c(NA, NaN), expected(c(NA, NaN)))
    checkDuckDBColumn(x %in% c(1, 4), expected(c(1, 4)))
})

test_that("%in% with NaN in the table works for an integer DuckDBColumn", {
    int_df <- data.frame(id = letters[1:4], n = c(1L, 2L, NA, 4L))
    int_path <- tempfile(fileext = ".parquet")
    arrow::write_parquet(int_df, int_path)
    on.exit(unlink(int_path))

    n <- DuckDBDataFrame(int_path, datacols = "n", keycol = "id")[["n"]]
    expected <- function(table) setNames(int_df$n %in% table, int_df$id)

    checkDuckDBColumn(n %in% NaN, expected(NaN))
    checkDuckDBColumn(n %in% c(1, NaN), expected(c(1, NaN)))
    checkDuckDBColumn(n %in% c(1, NA, NaN), expected(c(1, NA, NaN)))
    checkDuckDBColumn(n %in% 2, expected(2))
})

test_that("is.nan() sees a stored NaN, also in a column with no missing value", {
    # DuckDB 2.0.0's isnan() gives FALSE for such a column read from Parquet,
    # apparently because the file statistics leave NaN out
    d <- data.frame(id = letters[1:5], x = c(NaN, 1, 2, NaN, 3),
                    y = c(NaN, 1, NA, 2, 3), n = 1:5)
    path <- tempfile(fileext = ".parquet")
    arrow::write_parquet(d, path)
    on.exit(unlink(path))

    df <- DuckDBDataFrame(path, datacols = c("x", "y", "n"), keycol = "id")
    checkDuckDBColumn(is.nan(df[["x"]]), setNames(is.nan(d$x), d$id))
    checkDuckDBColumn(is.nan(df[["y"]]), setNames(is.nan(d$y), d$id))
    # an integer column cannot hold a NaN, and printf() cannot format one
    checkDuckDBColumn(is.nan(df[["n"]]), setNames(is.nan(d$n), d$id))
    checkDuckDBColumn(df[["x"]] %in% NaN, setNames(d$x %in% NaN, d$id))
    checkDuckDBColumn(df[["x"]] %in% c(1, NaN), setNames(d$x %in% c(1, NaN), d$id))
})

test_that("is.na() and anyNA() count a NaN as missing, also in a column with no NULL", {
    # DuckDB 2.0.0's isnan() gives FALSE for such a column read from Parquet
    d <- data.frame(id = letters[1:6], x = c(1, 2, NaN, 4, 5, 6),
                    y = c(1, 2, 3, 4, 5, 6), z = c(NaN, 1, NA, Inf, -Inf, 3),
                    n = 1:6)
    path <- tempfile(fileext = ".parquet")
    arrow::write_parquet(d, path)
    on.exit(unlink(path))

    df <- DuckDBDataFrame(path, datacols = c("x", "y", "z", "n"), keycol = "id")
    for (col in c("x", "y", "z", "n")) {
        checkDuckDBColumn(is.na(df[[col]]), setNames(is.na(d[[col]]), d$id))
        expect_identical(anyNA(df[[col]]), anyNA(d[[col]]), info = col)
    }
    expect_true(anyNA(df))
    expect_false(anyNA(df[, c("y", "n")]))
})

test_that("is.finite() and is.infinite() are never NA, as in base R", {
    cases <- list(finite = c(1, 2, 3, 4, 5, 6),
                  inf = c(1, 2, Inf, 4, -Inf, 6),
                  nan = c(1, 2, NaN, 4, 5, 6),
                  na = c(1, NA, 3, 4, 5, 6),
                  mixed = c(NaN, 1, NA, Inf, -Inf, 3),
                  all_na = rep(NA_real_, 6),
                  int = c(1L, NA, 3L, 4L, 5L, 6L))
    ids <- letters[1:6]
    for (nm in names(cases)) {
        v <- cases[[nm]]
        path <- tempfile(fileext = ".parquet")
        arrow::write_parquet(data.frame(id = ids, x = v), path)
        df <- DuckDBDataFrame(path, datacols = "x", keycol = "id")
        checkDuckDBColumn(is.finite(df[["x"]]), setNames(is.finite(v), ids))
        checkDuckDBColumn(is.infinite(df[["x"]]), setNames(is.infinite(v), ids))
        expect_identical(unname(as.vector(is.finite(df)[["x"]])), unname(is.finite(v)), info = nm)
        expect_identical(unname(as.vector(is.infinite(df)[["x"]])), unname(is.infinite(v)), info = nm)
        unlink(path)
    }
})

test_that("%in% never returns NA for a character DuckDBColumn", {
    chr_df <- data.frame(id = letters[1:4], s = c("u", NA, "w", "u"))
    chr_path <- tempfile(fileext = ".parquet")
    arrow::write_parquet(chr_df, chr_path)
    on.exit(unlink(chr_path))

    s <- DuckDBDataFrame(chr_path, datacols = "s", keycol = "id")[["s"]]
    expected <- function(table) setNames(chr_df$s %in% table, chr_df$id)

    checkDuckDBColumn(s %in% c("u", "x"), expected(c("u", "x")))
    checkDuckDBColumn(s %in% c("u", NA), expected(c("u", NA)))
    checkDuckDBColumn(s %in% NA_character_, expected(NA_character_))
})

test_that("%in% with a lazy DuckDBColumn as the table matches base R", {
    x_df <- data.frame(id = letters[1:6], x = c(1, 2, NA, 4, 2, 7),
                       s = c("u", "v", NA, "u", "w", "v"))
    y_df <- data.frame(id = letters[1:3], y = c(2, 7, NA), t = c("v", "z", NA))
    x_path <- tempfile(fileext = ".parquet")
    y_path <- tempfile(fileext = ".parquet")
    arrow::write_parquet(x_df, x_path)
    arrow::write_parquet(y_df, y_path)
    on.exit(unlink(c(x_path, y_path)))

    x <- DuckDBDataFrame(x_path, datacols = c("x", "s"), keycol = "id")
    y <- DuckDBDataFrame(y_path, datacols = c("y", "t"), keycol = "id")
    expected <- function(v, table) setNames(v %in% table, x_df$id)

    # the answer has one value per element of x, not one per element of the table
    checkDuckDBColumn(x[["x"]] %in% y[["y"]], expected(x_df$x, y_df$y))
    checkDuckDBColumn(x[["s"]] %in% y[["t"]], expected(x_df$s, y_df$t))
    checkDuckDBColumn(x[["x"]] %in% x[["x"]], expected(x_df$x, x_df$x))
    checkDuckDBColumn(x[["x"]] %in% y[["y"]][0L], expected(x_df$x, numeric(0)))

    one <- x[, "x", drop = FALSE]
    expect_identical(as.vector(( one %in% y[["y"]] )[["x"]]), expected(x_df$x, y_df$y))
})

test_that("Special numeric functions work as expected for a DuckDBColumn", {
    df <- DuckDBDataFrame(special_path, datacols = "x", keycol = list(id = letters[1:4]))
    x <- df[["x"]]

    checkDuckDBColumn(is.finite(x), is.finite(as.vector(x)))
    checkDuckDBColumn(is.infinite(x), is.infinite(as.vector(x)))
    checkDuckDBColumn(is.nan(x), is.nan(as.vector(x)))
})

test_that("is.na/anyNA work as expected for a DuckDBColumn", {
    df <- DuckDBDataFrame(special_path, datacols = "x", keycol = list(id = letters[1:4]))
    x <- df[["x"]]

    checkDuckDBColumn(is.na(x), is.na(as.vector(x)))
    expect_identical(anyNA(x), anyNA(as.vector(x)))

    y <- df[["x"]][1:2]
    expect_false(anyNA(y))
})

test_that("factor()/order()/rank() work on a DuckDBColumn without a stack overflow", {
    # factor() calls order() when levels aren't supplied explicitly; order()
    # falls back to xtfrm() for a class it doesn't recognize, which in turn
    # falls back to rank(), which needs ordering again -- with no xtfrm()
    # method of its own, DuckDBColumn had no base case to stop that loop,
    # crashing with a C stack overflow (not a catchable R-level error)
    # instead of ever reaching any of these generics' actual logic.
    df <- DuckDBDataFrame(mtcars_parquet)
    x <- df[["model"]]
    plain <- as.vector(x)

    expect_identical(as.character(factor(x)), as.character(factor(plain)))
    expect_identical(levels(factor(x)), levels(factor(plain)))
    expect_identical(order(x), order(plain))
    expect_equal(unname(rank(x)), unname(rank(plain)))
})

test_that("Summary methods work as expected for a DuckDBColumn", {
    df <- DuckDBDataFrame(mtcars_parquet, datacols = colnames(mtcars), keycol = "model")
    mpg <- df[["mpg"]]
    am <- df[["am"]]
    expect_identical(max(mpg), max(as.vector(mpg)))
    expect_identical(min(mpg), min(as.vector(mpg)))
    expect_identical(range(mpg), range(as.vector(mpg)))
    expect_equal(prod(mpg), prod(as.vector(mpg)))
    expect_equal(sum(mpg), sum(as.vector(mpg)))
    expect_identical(any(am == 0L), any(as.vector(am) == 0L))
    expect_identical(all(am == 0L), all(as.vector(am) == 0L))
})

test_that("Other aggregate methods work as expected for a DuckDBColumn", {
    df <- DuckDBDataFrame(mtcars_parquet, datacols = colnames(mtcars), keycol = "model")
    mpg <- df[["mpg"]]
    expect_equal(mean(mpg), mean(as.vector(mpg)))
    expect_equal(median(mpg), median(as.vector(mpg)))
    expect_equal(var(mpg), var(as.vector(mpg)))
    expect_equal(sd(mpg), sd(as.vector(mpg)))
    expect_equal(mad(mpg), mad(as.vector(mpg)))
    expect_equal(mad(mpg, constant = 1), mad(as.vector(mpg), constant = 1))

    expect_equal(quantile(mpg), quantile(as.vector(mpg)))
    expect_equal(quantile(mpg, probs = seq(0, 1, by = 0.05)), quantile(as.vector(mpg), probs = seq(0, 1, by = 0.05)))
    expect_equal(quantile(mpg, names = FALSE), quantile(as.vector(mpg), names = FALSE))
    expect_equal(quantile(mpg, type = 1), quantile(as.vector(mpg), type = 1))

    expect_equal(IQR(mpg), IQR(as.vector(mpg)))
    expect_equal(IQR(mpg, type = 1), IQR(as.vector(mpg), type = 1))

    gear <- df[["gear"]]
    carb <- df[["carb"]]
    expect_equal(table(gear, carb), table(gear = as.vector(gear), carb = as.vector(carb)))
})

test_that("Character methods work as expected for a DuckDBColumn", {
    df <- DuckDBDataFrame(penguins_raw_path, datacols = colnames(penguins_raw))
    species <- df[["Species"]]
    region <- df[["Region"]]

    checkDuckDBColumn(nchar(species), nchar(as.vector(species)))
    checkDuckDBColumn(tolower(species), tolower(as.vector(species)))
    checkDuckDBColumn(toupper(species), toupper(as.vector(species)))
    checkDuckDBColumn(chartr("aeiou", "12345", species), chartr("aeiou", "12345", as.vector(species)))
    checkDuckDBColumn(substr(species, 1, 1), substr(as.vector(species), 1, 1))
    checkDuckDBColumn(substring(species, 1, 1), substring(as.vector(species), 1, 1))
    checkDuckDBColumn(grepl("a", species), grepl("a", as.vector(species)))
    checkDuckDBColumn(grepl("a", species, fixed = TRUE), grepl("a", as.vector(species), fixed = TRUE))
    checkDuckDBColumn(sub("a", "X", species), sub("a", "X", as.vector(species)))
    checkDuckDBColumn(gsub("a", "X", species), gsub("a", "X", as.vector(species)))
    checkDuckDBColumn(startsWith(species, "a"), startsWith(as.vector(species), "a"))
    checkDuckDBColumn(endsWith(species, "z"), endsWith(as.vector(species), "z"))
    checkDuckDBColumn(paste2(species, region), paste2(as.vector(species), as.vector(region)))
    checkDuckDBColumn(paste2(species, " suffix"), paste2(as.vector(species), " suffix"))
    checkDuckDBColumn(paste2("prefix ", species), paste2("prefix ", as.vector(species)))
})

test_that("Variadic character methods work as expected for a DuckDBColumn", {
    df <- DuckDBDataFrame(penguins_raw_path, datacols = colnames(penguins_raw))
    species <- df[["Species"]]
    region <- df[["Region"]]
    island <- df[["Island"]]

    checkDuckDBColumn(paste(species, region), paste(as.vector(species), as.vector(region)))
    checkDuckDBColumn(paste(species, region, sep = "-"), paste(as.vector(species), as.vector(region), sep = "-"))
    checkDuckDBColumn(paste(species, region, island), paste(as.vector(species), as.vector(region), as.vector(island)))
})

test_that("Variadic numeric methods work as expected for a DuckDBColumn", {
    df <- DuckDBDataFrame(penguins_raw_path, datacols = colnames(penguins_raw))
    culmen_length <- df[["Culmen Length (mm)"]]
    culmen_depth <- df[["Culmen Depth (mm)"]]
    flipper_length <- df[["Flipper Length (mm)"]]

    checkDuckDBColumn(pmax(culmen_length, culmen_depth), pmax(as.vector(culmen_length), as.vector(culmen_depth)))
    checkDuckDBColumn(pmin(culmen_length, culmen_depth), pmin(as.vector(culmen_length), as.vector(culmen_depth)))
    checkDuckDBColumn(pmax(culmen_length, culmen_depth, flipper_length), pmax(as.vector(culmen_length), as.vector(culmen_depth), as.vector(flipper_length)))
    checkDuckDBColumn(pmin(culmen_length, culmen_depth, flipper_length), pmin(as.vector(culmen_length), as.vector(culmen_depth), as.vector(flipper_length)))
})

test_that("unique() keeps first occurrences in the order of the object, and honors fromLast", {
    # a hash order used to be returned, and fromLast was ignored
    d <- data.frame(id = c("e", "c", "a", "d", "b", "f"), x = c(2, 1, 2, 3, 1, 3),
                    y = c("p", "q", "p", "r", "q", "r"))
    path <- tempfile(fileext = ".parquet")
    arrow::write_parquet(d, path)
    on.exit(unlink(path))

    df <- DuckDBDataFrame(path, datacols = c("x", "y"), keycol = "id")
    ref <- d[order(d$id), ]                      # the object's own order is the key order
    for (fl in c(FALSE, TRUE)) {
        expect_identical(unname(as.vector(unique(df[["x"]], fromLast = fl))),
                         unique(ref$x, fromLast = fl))
        expect_identical(unname(as.vector(unique(df[["y"]], fromLast = fl))),
                         unique(ref$y, fromLast = fl))
        u <- as.data.frame(unique(df, fromLast = fl))
        w <- unique(ref[c("x", "y")], fromLast = fl)
        expect_identical(u$x, w$x)
        expect_identical(u$y, w$y)
    }
    # a user-given key order is the order of the object
    keyed <- DuckDBDataFrame(path, datacols = c("x", "y"),
                             keycol = list(id = c("f", "e", "d", "c", "b", "a")))
    kref <- d[match(rownames(keyed), d$id), ]
    expect_identical(unname(as.vector(unique(keyed[["x"]]))), unique(kref$x))
})

test_that("unique() of a subset only sees the rows of the subset", {
    # the key filter was left out, so the values of other rows came back
    d <- data.frame(id = c("e", "c", "a", "d", "b", "f"), x = c(2, 1, 2, 3, 1, 3),
                    y = c("p", "q", "p", "r", "q", "r"))
    path <- tempfile(fileext = ".parquet")
    arrow::write_parquet(d, path)
    on.exit(unlink(path))

    df <- DuckDBDataFrame(path, datacols = c("x", "y"), keycol = "id")
    sub <- df[c("c", "e"), ]
    expect_identical(unname(as.vector(unique(sub[["x"]]))), c(1, 2))
    expect_identical(unname(as.vector(unique(sub[["y"]]))), c("q", "p"))
    expect_identical(length(unique(sub[["y"]])), 2L)
})

test_that("unique() handles NA and NaN as base R does", {
    d <- data.frame(id = sprintf("k%02d", 1:7), x = c(NA, 1, NaN, 1, NA, NaN, 2))
    path <- tempfile(fileext = ".parquet")
    arrow::write_parquet(d, path)
    on.exit(unlink(path))
    x <- DuckDBDataFrame(path, datacols = "x", keycol = "id")[["x"]]
    got <- unname(as.vector(unique(x)))
    want <- unique(d$x)
    expect_identical(is.nan(got), is.nan(want))
    expect_identical(is.na(got), is.na(want))
    expect_equal(got[!is.na(got)], want[!is.na(want)])
})
