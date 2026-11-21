## The contract for the order and identity of rows. These tests are order
## sensitive on purpose: the check helpers in setup.R compare rownames as sets,
## which is why the problems below went unnoticed.

# A lazy object must agree with its own materialization: the dimensions, the
# rownames and the values that it reports are the ones it returns.
expectConsistent <- function(x) {
    df <- as.data.frame(x)
    expect_identical(nrow(x), nrow(df))
    expect_identical(rownames(x), rownames(df))
    invisible(df)
}

.write_keyed <- function(keys, a = seq_along(keys), chunk_size = NULL) {
    d <- data.frame(k = keys, a = a, stringsAsFactors = FALSE)
    p <- tempfile(fileext = ".parquet")
    if (is.null(chunk_size)) arrow::write_parquet(d, p)
    else arrow::write_parquet(d, p, chunk_size = chunk_size)
    list(path = p, data = d)
}

test_that("keys read from the database are in C-locale order, whatever the file order", {
    keys <- c("b", "A", "a", "B", "_x", "10", "9", "r1", "r10", "r2", "é", "Z")
    f <- .write_keyed(keys)
    on.exit(unlink(f$path), add = TRUE)
    x <- DuckDBDataFrame(f$path, datacols = "a", keycol = "k")
    expect_identical(rownames(x), sort(keys, method = "radix"))
    df <- expectConsistent(x)
    expect_identical(df$a, f$data$a[match(rownames(x), f$data$k)])

    # more keys than the key-filter threshold, and several row groups
    keys <- sprintf("id%04d", sample(900L))
    f2 <- .write_keyed(keys, chunk_size = 200L)
    on.exit(unlink(f2$path), add = TRUE)
    x2 <- DuckDBDataFrame(f2$path, datacols = "a", keycol = "k")
    expect_identical(rownames(x2), sort(keys, method = "radix"))
    expectConsistent(x2)

    # a key list given by the caller is never reordered
    own <- c("b", "A", "a", "B", "_x", "10", "9", "r1", "r10", "r2", "é", "Z")
    x3 <- DuckDBDataFrame(f$path, datacols = "a", keycol = list(k = own))
    expect_identical(rownames(x3), own)
})

test_that("an empty-string key is a key like any other", {
    f <- .write_keyed(c("b", "", "a"), a = c(1L, 2L, 3L))
    on.exit(unlink(f$path), add = TRUE)
    x <- DuckDBDataFrame(f$path, datacols = "a", keycol = "k")
    expect_identical(rownames(x), c("", "a", "b"))
    df <- expectConsistent(x)
    expect_identical(df$a, c(2L, 3L, 1L))
    expect_identical(unname(as.vector(x[["a"]])), c(2L, 3L, 1L))
    expect_identical(as(x, "DFrame")$a, c(2L, 3L, 1L))
})

test_that("a missing or repeated key is an error, not a corrupted object", {
    f <- .write_keyed(c("r1", NA, "r3"))
    on.exit(unlink(f$path), add = TRUE)
    expect_error(DuckDBDataFrame(f$path, datacols = "a", keycol = "k"),
                 "missing value.*cannot be NA")

    n <- data.frame(k = c(1, NA, 3), a = 1:3)
    p <- tempfile(fileext = ".parquet"); on.exit(unlink(p), add = TRUE)
    arrow::write_parquet(n, p)
    expect_error(DuckDBDataFrame(p, datacols = "a", keycol = "k"), "missing value")

    d <- .write_keyed(c("a", "b", "a", "c"))
    on.exit(unlink(d$path), add = TRUE)
    expect_error(DuckDBDataFrame(d$path, datacols = "a", keycol = "k"),
                 "repeated values.*'a'")

    # keys that a caller lists are checked too
    expect_error(DuckDBDataFrame(d$path, datacols = "a",
                                 keycol = list(k = c("a", "a", "b"))),
                 "repeated values")
    expect_error(DuckDBDataFrame(d$path, datacols = "a",
                                 keycol = list(k = c("a", NA))), "missing value")

    # a value repeats along the other dimensions of a table with several keys
    tbl <- DuckDBTable(esoph_parquet, datacols = c("ncases", "ncontrols"),
                       keycols = c("agegp", "alcgp", "tobgp"))
    expect_s4_class(tbl, "DuckDBTable")
})

test_that("row subscripts agree with a DataFrame, or say why they cannot", {
    keys <- c("b", "A", "a", "B", "_x", "r1", "r10", "r2")
    f <- .write_keyed(keys, a = 10L * seq_along(keys))
    on.exit(unlink(f$path), add = TRUE)
    kx <- DuckDBDataFrame(f$path, datacols = "a", keycol = "k")
    ref <- DataFrame(a = f$data$a[match(rownames(kx), f$data$k)], row.names = rownames(kx))

    kl <- DuckDBDataFrame(f$path, datacols = "a")          # keyless: numbered by row
    refl <- DataFrame(a = f$data$a)

    same <- function(x, r, i) {
        df <- expectConsistent(x[i, , drop = FALSE])
        expect_identical(df$a, r[i, , drop = FALSE]$a, info = deparse(i))
    }
    for (i in list(2:5, c(1L, 3L, 6L), -1L, c(-1L, -2L), c(-8L, -1L), 0L, c(0L, 2L),
                   TRUE, c(FALSE, TRUE, TRUE, FALSE, TRUE, TRUE, FALSE, TRUE),
                   integer(0))) {
        same(kx, ref, i)
        same(kl, refl, i)
    }

    # a table with names can list its rows in another order
    for (i in list(c(5L, 2L, 4L), 8:1, c(3L, 1L))) {
        sub <- kx[i, , drop = FALSE]
        df <- expectConsistent(sub)
        expect_identical(rownames(sub), rownames(kx)[i])
        expect_identical(df$a, ref$a[i])
    }
    expect_identical(rownames(kx["a", , drop = FALSE]), "a")
    expect_identical(rownames(kx[c("r2", "A"), , drop = FALSE]), c("r2", "A"))

    # what it cannot do is an error that names the reason
    for (x in list(kx, kl)) {
        expect_error(x[c(1, 1, 2), , drop = FALSE], "repeat rows")
        expect_error(x[c(1, NA), , drop = FALSE], "NA")
        expect_error(x[9, , drop = FALSE], "out-of-bounds")
        expect_error(x[c(-1, 2), , drop = FALSE], "negative")
        expect_error(x[matrix(1:2, 1), , drop = FALSE], "matrix")
    }
    expect_error(kx["zz", , drop = FALSE], "invalid names")
    expect_error(kx[c("a", "a"), , drop = FALSE], "repeat rows")
    expect_error(kl[c(3, 1), , drop = FALSE], "increasing")
    expect_error(kl["a", , drop = FALSE], "numeric or logical")
    expect_error(rev(kl), "increasing")
})

test_that("a lazy filter on a subset keeps the stored order and never leaves the subset", {
    keys <- sprintf("id%03d", 1:40)
    f <- .write_keyed(keys, a = seq_along(keys))
    on.exit(unlink(f$path), add = TRUE)
    x <- DuckDBDataFrame(f$path, datacols = "a", keycol = "k")

    y <- x[5:20, , drop = FALSE]
    z <- y[y[["a"]] > 12, , drop = FALSE]
    expect_identical(rownames(z), keys[13:20])
    expect_false(anyNA(rownames(z)))
    df <- expectConsistent(z)
    expect_identical(df$a, 13:20)

    w <- x[x[["a"]] %% 3L == 0L, , drop = FALSE]
    expect_identical(rownames(w), keys[seq(3L, 40L, 3L)])
    expectConsistent(w)

    # the same on a table numbered by row
    kl <- DuckDBDataFrame(f$path, datacols = "a")
    sub <- kl[5:20, , drop = FALSE]
    zz <- sub[sub[["a"]] > 12, , drop = FALSE]
    expect_identical(as.data.frame(zz)$a, 13:20)
    expect_identical(nrow(zz), 8L)
})

test_that("a subscript on one dimension of a table with several keys is bounded by that dimension", {
    # an array is a table with one key column per dimension, and a subscript
    # addresses one of them, so the extent is the number of keys there (not the
    # number of rows of the table, which is their product)
    tbl <- DuckDBTable(esoph_parquet, datacols = c("ncases", "ncontrols"),
                       keycols = c("agegp", "alcgp", "tobgp"))
    ages <- tbl@keycols[["agegp"]]
    na <- length(ages)
    expect_gt(nrow(tbl), na)

    sub <- function(i) tbl[list(agegp = i), ]@keycols[["agegp"]]
    expect_identical(sub(c(TRUE, rep(FALSE, na - 1L))), ages[1L])
    expect_identical(sub(rep(c(TRUE, FALSE), length.out = na)), ages[c(TRUE, FALSE)])
    expect_identical(sub(-1L), ages[-1L])
    expect_identical(sub(c(-1L, -na)), ages[-c(1L, na)])
    expect_identical(sub(c(3L, 1L)), ages[c(3L, 1L)])
    expect_identical(sub(0L), ages[0L])

    expect_error(sub(na + 1L), "out-of-bounds")
    expect_error(sub(c(1L, 1L)), "repeat rows")
    expect_error(sub(c(TRUE, NA, rep(FALSE, na - 2L))), "no NAs")
    expect_error(sub(c(TRUE, FALSE)[rep_len(1:2, na + 1L)]), "length 1 or nrow")
})
