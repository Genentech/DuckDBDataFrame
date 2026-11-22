# Aggregates of a lazy column or table follow base R for NA and NaN, with
# na.rm = FALSE and na.rm = TRUE.

.aggr_table <- function(v, name = "x") {
    d <- data.frame(id = sprintf("k%02d", seq_along(v)))
    d[[name]] <- v
    path <- tempfile(fileext = ".parquet")
    arrow::write_parquet(d, path)
    list(df = DuckDBDataFrame(path, datacols = name, keycol = "id"), path = path)
}

# R leaves it unspecified whether a mix of NA and NaN gives NA or NaN, so
# 'arbitrary' lets the two stand for each other
.same_aggregate <- function(got, want, arbitrary = FALSE) {
    got <- as.numeric(got)
    want <- as.numeric(want)
    if (length(got) != length(want)) {
        return(FALSE)
    }
    if (arbitrary) {
        got[is.nan(got)] <- NA
        want[is.nan(want)] <- NA
    }
    identical(is.nan(got), is.nan(want)) &&
        identical(is.na(got) & !is.nan(got), is.na(want) & !is.nan(want)) &&
        isTRUE(all.equal(got[!is.na(got)], want[!is.na(want)], tolerance = 1e-9))
}

test_that("min, max, sum, range, prod, mean, var, sd and median follow base R for NA and NaN", {
    datasets <- list(
        finite = c(4, 1, 7, 2, 9, 3),
        na = c(4, NA, 7, 2, 9, 3),
        nan = c(4, NaN, 7, 2, 9, 3),
        mixed = c(4, NA, NaN, 2, 9, 3),
        allna = rep(NA_real_, 4),
        inf = c(4, Inf, 7, -Inf, 9, 3),
        single = 5,
        nan_nona = c(NaN, 1, 2, 3))
    exprs <- c("min(x%s)", "max(x%s)", "sum(x%s)", "range(x%s)", "prod(x%s)",
               "mean(x%s)", "var(x%s)", "sd(x%s)", "median(x%s)")
    for (nm in names(datasets)) {
        v <- datasets[[nm]]
        fx <- .aggr_table(v)
        on.exit(unlink(fx$path), add = TRUE)
        objs <- list(column = fx$df[["x"]], table = fx$df)
        for (na.rm in c(FALSE, TRUE)) {
            arg <- paste0(", na.rm = ", na.rm)
            for (e in exprs) {
                txt <- sprintf(e, arg)
                want <- suppressWarnings(eval(parse(text = txt), list(x = v)))
                for (on in names(objs)) {
                    got <- suppressWarnings(eval(parse(text = txt), list(x = objs[[on]])))
                    expect_true(.same_aggregate(got, want, arbitrary = nm == "mixed"),
                                info = sprintf("%s: %s on a %s", nm, txt, on))
                }
            }
        }
    }
})

test_that("any() and all() follow base R for a logical column with NA", {
    for (v in list(c(TRUE, FALSE, TRUE), c(FALSE, FALSE), c(TRUE, NA), c(FALSE, NA),
                   c(NA, NA), c(TRUE, TRUE))) {
        fx <- .aggr_table(v)
        x <- fx$df[["x"]]
        for (na.rm in c(FALSE, TRUE)) {
            info <- sprintf("%s, na.rm = %s", paste(v, collapse = " "), na.rm)
            expect_identical(any(x, na.rm = na.rm), any(v, na.rm = na.rm), info = info)
            expect_identical(all(x, na.rm = na.rm), all(v, na.rm = na.rm), info = info)
        }
        unlink(fx$path)
    }
})

test_that("min and max of an integer column stay integers", {
    v <- c(3L, 1L, NA, 7L)
    fx <- .aggr_table(v)
    on.exit(unlink(fx$path))
    x <- fx$df[["x"]]
    for (na.rm in c(FALSE, TRUE)) {
        expect_identical(min(x, na.rm = na.rm), min(v, na.rm = na.rm))
        expect_identical(max(x, na.rm = na.rm), max(v, na.rm = na.rm))
    }
    expect_equal(sum(x, na.rm = TRUE), 11)
    expect_true(is.na(sum(x)))
})

test_that("aggregates of a table with no rows are the values base R gives for an empty set", {
    d <- data.frame(id = character(0), x = numeric(0))
    path <- tempfile(fileext = ".parquet")
    arrow::write_parquet(d, path)
    on.exit(unlink(path))
    x <- DuckDBDataFrame(path, datacols = "x", keycol = "id")[["x"]]
    expect_identical(length(x), 0L)
    for (na.rm in c(FALSE, TRUE)) {
        expect_identical(sum(x, na.rm = na.rm), 0)
        expect_identical(prod(x, na.rm = na.rm), 1)
        expect_identical(suppressWarnings(min(x, na.rm = na.rm)), Inf)
        expect_identical(suppressWarnings(max(x, na.rm = na.rm)), -Inf)
        expect_identical(mean(x, na.rm = na.rm), NaN)
        expect_identical(var(x, na.rm = na.rm), NA_real_)
    }
})

test_that("na.rm has to be TRUE or FALSE", {
    fx <- .aggr_table(c(1, 2, 3))
    on.exit(unlink(fx$path))
    x <- fx$df[["x"]]
    expect_error(sum(x, na.rm = NA), "na.rm")
    expect_error(mean(x, na.rm = "yes"), "na.rm")
})
