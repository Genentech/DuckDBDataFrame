# Regression tests for the length-safe stored-key reorder shared by
# as.vector,DuckDBColumn / as.list,DuckDBAtomicList / as.data.frame,DuckDBDataFrame
# (review finding F11). The coercions label a query result from the materialized
# keycol column and then reorder to the object's canonical stored-key order; the
# reorder must be a clean bijection or fall back to query order, never silently
# NA-pad / first-match / truncate when the stored key set diverges.

test_that(".storedKeysBijective accepts a clean 1:1 correspondence only", {
    bij <- DuckDBDataFrame:::.storedKeysBijective
    expect_true(bij(c("a", "b", "c"), c("c", "a", "b")))   # same set, reordered
    expect_false(bij(c("a", "b", "c"), c("a", "b")))        # length mismatch
    expect_false(bij(c("a", "b"), c("a", "b", "c")))        # length mismatch
    expect_false(bij(c("a", "a"), c("a", "b")))             # duplicate stored key
    expect_false(bij(c("a", "b"), c("a", "a")))             # duplicate materialized name
    expect_false(bij(c("a", "b", "c"), c("a", "b", "d")))   # disjoint element
    expect_true(bij(character(0), character(0)))            # empty is trivially safe
})

test_that(".reindexByStoredKeys reorders to stored-key order when it is a bijection", {
    reindex <- DuckDBDataFrame:::.reindexByStoredKeys
    res <- reindex(setNames(c(10, 20, 30), c("b", "a", "c")), c("a", "b", "c"))
    expect_identical(res, setNames(c(20, 10, 30), c("a", "b", "c")))
})

test_that(".reindexByStoredKeys keeps query order on divergence (no NA-pad / first-match)", {
    reindex <- DuckDBDataFrame:::.reindexByStoredKeys
    # stored set longer than materialized -> would NA-pad; must NOT
    q <- setNames(c(1, 2, 3), c("a", "b", "c"))
    expect_identical(reindex(q, c("a", "b", "c", "d")), q)
    expect_false(anyNA(reindex(q, c("a", "b", "c", "d"))))
    # duplicate materialized names -> would first-match; must keep both values
    d <- setNames(c(1, 2), c("a", "a"))
    expect_identical(reindex(d, c("a", "b")), d)
    # every value stays paired with its own name in all cases
    expect_identical(names(reindex(q, c("x", "y"))), c("a", "b", "c"))
})

test_that("named-column coercions preserve canonical order + value/name pairing", {
    tf <- tempfile(fileext = ".parquet")
    on.exit(unlink(tf))
    # deliberately unsorted on disk to prove reorder to canonical order happens
    arrow::write_parquet(
        data.frame(cell_id = c("c3", "c1", "c2"), val = c(30, 10, 20),
                   stringsAsFactors = FALSE), tf)
    ddf <- DuckDBDataFrame(tf, keycol = "cell_id")
    col <- ddf[["val"]]

    keys <- rownames(col@table)               # canonical stored-key order
    v <- as.vector(col)
    expect_identical(names(v), keys)
    expect_identical(v[["c1"]], 10)           # correct value under each name
    expect_identical(v[["c2"]], 20)
    expect_identical(v[["c3"]], 30)

    df <- as.data.frame(ddf)
    expect_identical(rownames(df), keys)
    expect_identical(df[["val"]], unname(v[keys]))   # rows follow the same canonical order
})

test_that("row_number-keyed column coerces without a stored-key reorder scan", {
    tf <- tempfile(fileext = ".parquet")
    on.exit(unlink(tf))
    arrow::write_parquet(data.frame(val = c(5, 6, 7)), tf)
    col <- DuckDBDataFrame(tf)[["val"]]
    expect_true(DuckDBDataFrame:::.has_row_number(col@table))
    expect_identical(unname(as.vector(col)), c(5, 6, 7))
})
