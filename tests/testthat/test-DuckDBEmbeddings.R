# Tests the basic functions of a DuckDBEmbeddings.
# library(testthat); library(DuckDBDataFrame); source("setup.R"); source("test-DuckDBEmbeddings.R")

test_that("DuckDBEmbeddings is created from ARRAY[DOUBLE] columns (no keycol)", {
    object <- DuckDBDataFrame(embeddings_parquet)[["pca"]]
    expected <- do.call(rbind, embeddings_df[["pca"]])

    expect_true(validObject(object))
    expect_s4_class(object, "DuckDBEmbeddings")
    expect_true(length(capture.output(show(object))) > 0L)
    expect_identical(dbconn(object), acquireDuckDBConn())
    expect_s3_class(tblconn(object), "tbl_duckdb_connection")
    expect_identical(dim(object), dim(expected))
    expect_identical(nrow(object), nrow(expected))
    expect_identical(ncol(object), ncol(expected))
})

test_that("DuckDBEmbeddings is created from ARRAY[DOUBLE] columns (keycol name)", {
    object <- DuckDBDataFrame(embeddings_parquet, keycol = "cell_id")[["pca"]]
    expected <- do.call(rbind, embeddings_df[["pca"]])

    expect_true(validObject(object))
    expect_s4_class(object, "DuckDBEmbeddings")
    expect_true(length(capture.output(show(object))) > 0L)
    expect_identical(dbconn(object), acquireDuckDBConn())
    expect_s3_class(tblconn(object), "tbl_duckdb_connection")
    expect_identical(dim(object), dim(expected))
    expect_identical(nrow(object), nrow(expected))
    expect_identical(ncol(object), ncol(expected))
})

test_that("DuckDBEmbeddings is created from ARRAY[DOUBLE] columns (keycol list)", {
    cell_ids <- embeddings_df[["cell_id"]]
    object <- DuckDBDataFrame(embeddings_parquet, keycol = list(cell_id = cell_ids))[["pca"]]
    expected <- do.call(rbind, embeddings_df[["pca"]])
    rownames(expected) <- cell_ids
    checkDuckDBEmbeddings(object, expected)
})

test_that("DuckDBEmbeddings works with different embedding dimensions", {
    cell_ids <- embeddings_df[["cell_id"]]
    object <- DuckDBDataFrame(embeddings_parquet, keycol = list(cell_id = cell_ids))[["pca"]]
    expected <- do.call(rbind, embeddings_df[["pca"]])
    rownames(expected) <- cell_ids
    checkDuckDBEmbeddings(object, expected)

    cell_ids <- embeddings_df[["cell_id"]]
    object <- DuckDBDataFrame(embeddings_parquet, keycol = list(cell_id = cell_ids))[["umap"]]
    expected <- do.call(rbind, embeddings_df[["umap"]])
    rownames(expected) <- cell_ids
    checkDuckDBEmbeddings(object, expected)

    cell_ids <- embeddings_df[["cell_id"]]
    object <- DuckDBDataFrame(embeddings_parquet, keycol = list(cell_id = cell_ids))[["tsne"]]
    expected <- do.call(rbind, embeddings_df[["tsne"]])
    rownames(expected) <- cell_ids
    checkDuckDBEmbeddings(object, expected)
})

test_that("head works for DuckDBEmbeddings", {
    cell_ids <- embeddings_df[["cell_id"]]
    object <- DuckDBDataFrame(embeddings_parquet, keycol = list(cell_id = cell_ids))[["pca"]]
    expected <- do.call(rbind, embeddings_df[["pca"]])
    rownames(expected) <- cell_ids

    checkDuckDBEmbeddings(head(object, 10), head(expected, 10))
})

test_that("tail works for DuckDBEmbeddings", {
    cell_ids <- embeddings_df[["cell_id"]]
    object <- DuckDBDataFrame(embeddings_parquet, keycol = list(cell_id = cell_ids))[["pca"]]
    expected <- do.call(rbind, embeddings_df[["pca"]])
    rownames(expected) <- cell_ids

    checkDuckDBEmbeddings(tail(object, 10), tail(expected, 10))
})

test_that("extractROWS works for DuckDBEmbeddings", {
    cell_ids <- embeddings_df[["cell_id"]]
    object <- DuckDBDataFrame(embeddings_parquet, keycol = list(cell_id = cell_ids))[["pca"]]
    expected <- do.call(rbind, embeddings_df[["pca"]])
    rownames(expected) <- cell_ids

    checkDuckDBEmbeddings(object[1:10, ], expected[1:10, ])
    checkDuckDBEmbeddings(object[c("cell_001", "cell_050", "cell_100"), ],
                          expected[c("cell_001", "cell_050", "cell_100"), ])
})

test_that("extractCOLS works for DuckDBEmbeddings", {
    cell_ids <- embeddings_df[["cell_id"]]
    object <- DuckDBDataFrame(embeddings_parquet, keycol = list(cell_id = cell_ids))[["pca"]]
    expected <- do.call(rbind, embeddings_df[["pca"]])
    rownames(expected) <- cell_ids

    checkDuckDBEmbeddings(object[, 1:10], expected[, 1:10])
    checkDuckDBColumn(object[, 1], expected[, 1])
})

test_that("2D subsetting works for DuckDBEmbeddings", {
    cell_ids <- embeddings_df[["cell_id"]]
    object <- DuckDBDataFrame(embeddings_parquet, keycol = list(cell_id = cell_ids))[["pca"]]
    expected <- do.call(rbind, embeddings_df[["pca"]])
    rownames(expected) <- cell_ids

    checkDuckDBEmbeddings(object[1:10, ], expected[1:10, ])
    checkDuckDBEmbeddings(object[, 1:5], expected[, 1:5])
    checkDuckDBEmbeddings(object[1:10, 1:5], expected[1:10, 1:5])
})

test_that("show method works for DuckDBEmbeddings", {
    cell_ids <- embeddings_df[["cell_id"]]
    object <- DuckDBDataFrame(embeddings_parquet, keycol = list(cell_id = cell_ids))[["pca"]]

    output <- capture.output(show(object))
    expect_true(length(output) > 0L)
    expect_true(any(grepl("DuckDBEmbeddings", output)))
    expect_true(any(grepl("100 x 50", output)))
})

test_that("as.list works for DuckDBEmbeddings", {
    cell_ids <- embeddings_df[["cell_id"]]
    object <- DuckDBDataFrame(embeddings_parquet, keycol = list(cell_id = cell_ids))[["pca"]]
    expected <- lapply(embeddings_df[["pca"]], identity)
    names(expected) <- cell_ids

    expect_equal(as.list(object), expected, check.attributes = FALSE)
})

test_that("elementNROWS works for DuckDBEmbeddings", {
    cell_ids <- embeddings_df[["cell_id"]]
    object <- DuckDBDataFrame(embeddings_parquet, keycol = list(cell_id = cell_ids))[["pca"]]
    expected <- do.call(rbind, embeddings_df[["pca"]])
    rownames(expected) <- cell_ids

    elem_nrows <- elementNROWS(object)
    expect_identical(length(elem_nrows), 100L)
    expect_true(all(elem_nrows == 50L))
})

test_that("getListElement works for DuckDBEmbeddings", {
    cell_ids <- embeddings_df[["cell_id"]]
    object <- DuckDBDataFrame(embeddings_parquet, keycol = list(cell_id = cell_ids))[["pca"]]
    expected <- do.call(rbind, embeddings_df[["pca"]])

    expect_equal(object[[1]], expected[1, , drop = FALSE], tolerance = 1e-10)
})
