# Tests the basic functions of a DuckDBSelfHits.
# library(testthat); library(DuckDBDataFrame); source("setup.R"); source("test-DuckDBSelfHits.R")

test_that("basic methods work for a DuckDBSelfHits", {
    hits <- DuckDBSelfHits(selfhits_parquet, from = "from", to = "to", nnode = 5L,
                           mcols = c("weight", "distance"))
    checkDuckDBSelfHits(hits, selfhits_sh)

    hits <- DuckDBSelfHits(selfhits_parquet, from = "from", to = "to", nnode = 5L,
                           mcols = c("weight", "distance"),
                           keycol = list(id = selfhits_df[["id"]]))
    checkDuckDBSelfHits(hits, selfhits_sh)
})

test_that("coercion to DuckDBDataFrame works for a DuckDBSelfHits", {
    hits <- DuckDBSelfHits(selfhits_parquet, from = "from", to = "to", nnode = 5L,
                           mcols = c("weight", "distance"),
                           keycol = list(id = selfhits_df[["id"]]))

    df <- as(hits, "DuckDBDataFrame")
    expect_s4_class(df, "DuckDBDataFrame")
    expect_identical(colnames(df), c("from", "to", "weight", "distance"))
    expect_identical(nrow(df), length(hits))
    expect_identical(rownames(df), selfhits_df[["id"]])
})

test_that("coercion to dgCMatrix works for a DuckDBSelfHits", {
    hits <- DuckDBSelfHits(selfhits_parquet, from = "from", to = "to", nnode = 5L,
                           mcols = "weight",
                           keycol = list(id = selfhits_df[["id"]]))

    mat <- as(hits, "dgCMatrix")
    expect_s4_class(mat, "dgCMatrix")
    expect_identical(dim(mat), c(5L, 5L))

    # Check specific values from edge list
    expect_equal(mat[1, 2], 0.8)
    expect_equal(mat[1, 5], 0.6)
    expect_equal(mat[2, 3], 0.9)
})

test_that("slicing by rows works for a DuckDBSelfHits", {
    hits <- DuckDBSelfHits(selfhits_parquet, from = "from", to = "to", nnode = 5L,
                           mcols = c("weight", "distance"),
                           keycol = list(id = selfhits_df[["id"]]))

    keep <- c(1L, 3L, 5L)
    checkDuckDBSelfHits(hits[keep], selfhits_sh[keep])

    keep <- selfhits_df[["id"]][c(4L, 2L, 3L)]
    checkDuckDBSelfHits(hits[keep], selfhits_sh[c(4L, 2L, 3L)])

    keep <- startsWith(rownames(hits@frame), "edge0")
    checkDuckDBSelfHits(hits[keep], selfhits_sh)

    # Verify nnode is unchanged (edges subsetted, not nodes)
    keep <- 5L
    expect_identical(nnode(hits[keep]), nnode(hits))
})

test_that("head and tail work for a DuckDBSelfHits", {
    hits <- DuckDBSelfHits(selfhits_parquet, from = "from", to = "to", nnode = 5L,
                           mcols = c("weight", "distance"),
                           keycol = list(id = selfhits_df[["id"]]))

    checkDuckDBSelfHits(head(hits, 3), head(selfhits_sh, 3))
    checkDuckDBSelfHits(tail(hits, 3), tail(selfhits_sh, 3))

    # Negative n
    checkDuckDBSelfHits(head(hits, -2), head(selfhits_sh, -2))
    checkDuckDBSelfHits(tail(hits, -2), tail(selfhits_sh, -2))
})

test_that("queryHits/subjectHits aliases work for a DuckDBSelfHits", {
    hits <- DuckDBSelfHits(selfhits_parquet, from = "from", to = "to", nnode = 5L,
                           keycol = list(id = selfhits_df[["id"]]))

    expect_identical(as.integer(queryHits(hits)), as.integer(from(hits)))
    expect_identical(as.integer(subjectHits(hits)), as.integer(to(hits)))
    expect_identical(queryLength(hits), nLnode(hits))
    expect_identical(subjectLength(hits), nRnode(hits))
    expect_identical(countQueryHits(hits), countLnodeHits(hits))
    expect_identical(countSubjectHits(hits), countRnodeHits(hits))
})

test_that("mcols accessor works for a DuckDBSelfHits", {
    # Without mcols
    hits_no_mcols <- DuckDBSelfHits(selfhits_parquet, from = "from", to = "to", nnode = 5L,
                                    keycol = list(id = selfhits_df[["id"]]))
    expect_true(is.null(mcols(hits_no_mcols)) || ncol(mcols(hits_no_mcols)) == 0L)

    # With mcols
    hits <- DuckDBSelfHits(selfhits_parquet, from = "from", to = "to", nnode = 5L,
                           mcols = c("weight", "distance"), keycol = list(id = selfhits_df[["id"]]))
    m <- mcols(hits)
    expect_s4_class(m, "DuckDBDataFrame")
    expect_identical(colnames(m), c("weight", "distance"))
    expect_identical(nrow(m), length(hits))
})

test_that("validation catches invalid inputs for DuckDBSelfHits", {
    # nnode must be a single non-negative integer
    expect_error(DuckDBSelfHits(selfhits_parquet, from = "from", to = "to", nnode = c(5L, 10L)))
    expect_error(DuckDBSelfHits(selfhits_parquet, from = "from", to = "to", nnode = -1L))

    # from and to must be specified
    expect_error(DuckDBSelfHits(selfhits_parquet, from = NULL, to = "to", nnode = 5L))
    expect_error(DuckDBSelfHits(selfhits_parquet, from = "from", to = NULL, nnode = 5L))
})

test_that("validation catches out-of-bounds indices when materializing", {
    # Create hits with out-of-bounds indices
    df_bad <- data.frame(from = c(1L, 2L, 10L), to = c(2L, 3L, 1L))
    tf <- tempfile(fileext = ".parquet")
    on.exit(unlink(tf), add = TRUE)
    arrow::write_parquet(df_bad, tf)

    hits <- DuckDBSelfHits(tf, from = "from", to = "to", nnode = 5L)

    # Should fail when materializing (10 > nnode)
    expect_error(as(hits, "SelfHits"), "'from' indices out of bounds")
})

test_that("show method works for a DuckDBSelfHits", {
    hits <- DuckDBSelfHits(selfhits_parquet, from = "from", to = "to", nnode = 5L,
                           mcols = c("weight", "distance"), keycol = list(id = selfhits_df[["id"]]))

    output <- capture.output(show(hits))
    expect_true(length(output) > 0L)
    expect_true(any(grepl("DuckDBSelfHits", output)))
    expect_true(any(grepl("7 hit", output)))
    expect_true(any(grepl("5 node", output)))
})

test_that("realize works for a DuckDBSelfHits", {
    hits <- DuckDBSelfHits(selfhits_parquet, from = "from", to = "to", nnode = 5L,
                           mcols = c("weight", "distance"), keycol = list(id = selfhits_df[["id"]]))

    realized <- realize(hits, BACKEND = NULL)
    expect_s4_class(realized, "SelfHits")
    expect_false(is(realized, "DuckDBSelfHits"))
    expect_identical(realized, selfhits_sh)
})
