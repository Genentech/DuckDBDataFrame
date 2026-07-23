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

test_that("nodes slot works for a DuckDBSelfHits", {
    # Default: implicit encoding
    hits <- DuckDBSelfHits(selfhits_parquet, from = "from", to = "to", nnode = 5L,
                           keycol = list(id = selfhits_df[["id"]]))
    expect_identical(hits@nodes, c(NA_integer_, -5L))
    expect_true(DuckDBDataFrame:::.has_implicit_nodes(hits))
    expect_identical(DuckDBDataFrame:::.nodes(hits), 1:5)

    # Explicit nodes
    hits <- DuckDBSelfHits(selfhits_parquet, from = "from", to = "to", nnode = 3L,
                           nodes = c(1L, 3L, 5L),
                           keycol = list(id = selfhits_df[["id"]]))
    expect_identical(hits@nodes, c(1L, 3L, 5L))
    expect_false(DuckDBDataFrame:::.has_implicit_nodes(hits))
    expect_identical(DuckDBDataFrame:::.nodes(hits), c(1L, 3L, 5L))
    expect_identical(nnode(hits), 3L)

    # Named nodes (aliases)
    hits <- DuckDBSelfHits(selfhits_parquet, from = "from", to = "to", nnode = 3L,
                           nodes = c(nodeA = 1L, nodeC = 3L, nodeE = 5L),
                           keycol = list(id = selfhits_df[["id"]]))
    expect_identical(hits@nodes, c(nodeA = 1L, nodeC = 3L, nodeE = 5L))
    expect_identical(names(hits@nodes), c("nodeA", "nodeC", "nodeE"))
})

test_that("extractNODES works for a DuckDBSelfHits", {
    hits <- DuckDBSelfHits(selfhits_parquet, from = "from", to = "to", nnode = 5L,
                           mcols = c("weight", "distance"),
                           keycol = list(id = selfhits_df[["id"]]))

    sub <- extractNODES(hits, c(2L, 3L, 5L))
    expect_identical(nnode(sub), 3L)
    expect_identical(sub@nodes, c(2L, 3L, 5L))
    expect_false(DuckDBDataFrame:::.has_implicit_nodes(sub))

    df <- as.data.frame(sub)
    expect_true(all(df$from %in% c(2L, 3L, 5L)))
    expect_true(all(df$to %in% c(2L, 3L, 5L)))
    expect_identical(nrow(df), 1L)
})

test_that("extractROWS works for a DuckDBSelfHits", {
    hits <- DuckDBSelfHits(selfhits_parquet, from = "from", to = "to", nnode = 5L,
                           mcols = c("weight", "distance"),
                           keycol = list(id = selfhits_df[["id"]]))

    sub <- extractROWS(hits, c(1L, 3L, 5L))
    expect_identical(nnode(sub), nnode(hits))
    expect_true(DuckDBDataFrame:::.has_implicit_nodes(sub))
    expect_identical(length(sub), 3L)
})

test_that("tblconn applies node filtering for a DuckDBSelfHits", {
    hits <- DuckDBSelfHits(selfhits_parquet, from = "from", to = "to", nnode = 5L,
                           keycol = list(id = selfhits_df[["id"]]))

    conn <- tblconn(hits, filter = TRUE)
    expect_identical(nrow(dplyr::collect(conn)), 7L)

    sub <- extractNODES(hits, c(2L, 3L, 5L))
    conn <- tblconn(sub, filter = TRUE)
    df <- dplyr::collect(conn)
    expect_identical(nrow(df), 1L)
    expect_true(all(df$from %in% c(2L, 3L, 5L)))
    expect_true(all(df$to %in% c(2L, 3L, 5L)))

    conn <- tblconn(sub, filter = FALSE)
    expect_identical(nrow(dplyr::collect(conn)), 7L)
})

test_that("countLnodeHits works for a DuckDBSelfHits", {
    hits <- DuckDBSelfHits(selfhits_parquet, from = "from", to = "to", nnode = 5L,
                           keycol = list(id = selfhits_df[["id"]]))

    counts <- countLnodeHits(hits)
    expect_identical(length(counts), 5L)
    expect_null(names(counts))
    expect_identical(counts[1], 2L)
    expect_identical(counts[4], 2L)
    expect_identical(counts[5], 1L)

    sub <- extractNODES(hits, c(2L, 3L, 5L))
    counts <- countLnodeHits(sub)
    expect_identical(length(counts), 3L)
    expect_identical(names(counts), c("2", "3", "5"))
    expect_identical(counts["2"], c("2" = 1L))
    expect_identical(sum(counts), 1L)
})

test_that("countRnodeHits works for a DuckDBSelfHits", {
    hits <- DuckDBSelfHits(selfhits_parquet, from = "from", to = "to", nnode = 5L,
                           keycol = list(id = selfhits_df[["id"]]))

    counts <- countRnodeHits(hits)
    expect_identical(length(counts), 5L)
    expect_null(names(counts))

    sub <- extractNODES(hits, c(2L, 3L, 5L))
    counts <- countRnodeHits(sub)
    expect_identical(length(counts), 3L)
    expect_identical(names(counts), c("2", "3", "5"))
    expect_identical(counts["3"], c("3" = 1L))
    expect_identical(sum(counts), 1L)
})

test_that("coercion to SelfHits works for a DuckDBSelfHits", {
    hits <- DuckDBSelfHits(selfhits_parquet, from = "from", to = "to", nnode = 5L,
                           mcols = c("weight", "distance"),
                           keycol = list(id = selfhits_df[["id"]]))

    sh <- as(hits, "SelfHits")
    expect_identical(from(sh), from(selfhits_sh))
    expect_identical(to(sh), to(selfhits_sh))

    sub <- extractNODES(hits, c(2L, 3L, 5L))
    sh <- as(sub, "SelfHits")
    expect_identical(nnode(sh), 3L)
    expect_identical(length(sh), 1L)
    expect_true(all(from(sh) %in% 1:3))
    expect_true(all(to(sh) %in% 1:3))

    # Named nodes
    hits <- DuckDBSelfHits(selfhits_parquet, from = "from", to = "to", nnode = 3L,
                           nodes = c(nodeB = 2L, nodeC = 3L, nodeE = 5L),
                           mcols = c("weight", "distance"),
                           keycol = list(id = selfhits_df[["id"]]))
    sh <- as(hits, "SelfHits")
    expect_identical(nnode(sh), 3L)
    expect_identical(length(sh), 1L)
    expect_identical(as.integer(from(sh)), 1L)
    expect_identical(as.integer(to(sh)), 2L)
})

test_that("as.data.frame works for a DuckDBSelfHits", {
    hits <- DuckDBSelfHits(selfhits_parquet, from = "from", to = "to", nnode = 5L,
                           mcols = c("weight", "distance"),
                           keycol = list(id = selfhits_df[["id"]]))

    sub <- extractNODES(hits, c(2L, 3L))
    df <- as.data.frame(sub)
    expect_identical(nrow(df), 1L)
    expect_true(all(df$from %in% c(2L, 3L)))
    expect_true(all(df$to %in% c(2L, 3L)))
})

test_that("coercion to DuckDBDataFrame works for a DuckDBSelfHits", {
    hits <- DuckDBSelfHits(selfhits_parquet, from = "from", to = "to", nnode = 5L,
                           mcols = c("weight", "distance"),
                           keycol = list(id = selfhits_df[["id"]]))

    sub <- extractNODES(hits, c(1L, 2L))
    df <- as(sub, "DuckDBDataFrame")
    expect_s4_class(df, "DuckDBDataFrame")

    mat <- dplyr::collect(tblconn(df))
    expect_identical(nrow(mat), 1L)
    expect_true(all(mat$from %in% c(1L, 2L)))
    expect_true(all(mat$to %in% c(1L, 2L)))
})

test_that("coercion to DFrame works for a DuckDBSelfHits", {
    hits <- DuckDBSelfHits(selfhits_parquet, from = "from", to = "to", nnode = 5L,
                           mcols = c("weight", "distance"),
                           keycol = list(id = selfhits_df[["id"]]))

    sub <- extractNODES(hits, c(3L, 5L))
    df <- as(sub, "DFrame")
    expect_s4_class(df, "DFrame")
    expect_identical(nrow(df), 0L)
})

test_that("extractNODES chains for a DuckDBSelfHits", {
    hits <- DuckDBSelfHits(selfhits_parquet, from = "from", to = "to", nnode = 5L,
                           keycol = list(id = selfhits_df[["id"]]))

    sub1 <- extractNODES(hits, c(1L, 2L, 3L, 5L))
    expect_identical(nnode(sub1), 4L)
    expect_identical(sub1@nodes, c(1L, 2L, 3L, 5L))
    expect_identical(nrow(as.data.frame(sub1)), 4L)

    sub2 <- extractNODES(sub1, c(2L, 4L))
    expect_identical(nnode(sub2), 2L)
    expect_identical(sub2@nodes, c(2L, 5L))
    expect_identical(nrow(as.data.frame(sub2)), 0L)
})

test_that("edge and node subsetting are independent for a DuckDBSelfHits", {
    hits <- DuckDBSelfHits(selfhits_parquet, from = "from", to = "to", nnode = 5L,
                           keycol = list(id = selfhits_df[["id"]]))

    edge_sub <- hits[c(1L, 3L)]
    expect_true(DuckDBDataFrame:::.has_implicit_nodes(edge_sub))
    expect_identical(nnode(edge_sub), 5L)
    expect_identical(length(edge_sub), 2L)

    node_sub <- extractNODES(hits, c(1L, 2L, 3L))
    expect_false(DuckDBDataFrame:::.has_implicit_nodes(node_sub))
    expect_identical(nnode(node_sub), 3L)
    expect_identical(nrow(as.data.frame(node_sub)), 2L)
})

test_that("isolated node subset produces empty result for a DuckDBSelfHits", {
    hits <- DuckDBSelfHits(selfhits_parquet, from = "from", to = "to", nnode = 5L,
                           keycol = list(id = selfhits_df[["id"]]))

    sub <- extractNODES(hits, 4L)
    expect_identical(nnode(sub), 1L)
    expect_identical(nrow(as.data.frame(sub)), 0L)
})

test_that("nnode / node ids beyond the 32-bit range fail loudly (not silent NA)", {
    expect_error(
        DuckDBSelfHits(selfhits_parquet, from = "from", to = "to", nnode = 3e9),
        "32-bit")
    expect_error(
        DuckDBSelfHits(selfhits_parquet, from = "from", to = "to", nnode = 5L,
                       nodes = c(1, 3e9)),
        "32-bit")
})
