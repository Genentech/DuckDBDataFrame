# Smoking, Alcohol and (O)esophageal Cancer
esoph_df <- esoph
for (i in 1:3) {
  esoph_df[[i]] <- as.character(esoph_df[[i]])
}
esoph_csv <- tempfile(fileext = ".csv")
write.csv(esoph_df, esoph_csv, row.names = FALSE)
esoph_csv_gz <- tempfile(fileext = ".csv.gz")
write.csv(esoph_df, gzfile(esoph_csv_gz), row.names = FALSE)
esoph_parquet <- tempfile(fileext = ".parquet")
arrow::write_parquet(esoph_df, esoph_parquet)


# Infertility after Spontaneous and Induced Abortion
infert_csv <- tempfile(fileext = ".csv")
write.csv(infert, infert_csv, row.names = FALSE)
infert_csv_gz <- tempfile(fileext = ".csv.gz")
write.csv(infert, gzfile(infert_csv_gz), row.names = FALSE)
infert_parquet <- tempfile(fileext = ".parquet")
arrow::write_parquet(infert, infert_parquet)

# Motor Trend Car Road Tests
mtcars_df <- cbind(model = rownames(mtcars), mtcars)
rownames(mtcars_df) <- NULL

mtcars_csv <- tempfile(fileext = ".csv")
write.csv(mtcars_df, mtcars_csv, row.names = FALSE)
mtcars_csv_gz <- tempfile(fileext = ".csv.gz")
write.csv(mtcars_df, gzfile(mtcars_csv_gz), row.names = FALSE)
mtcars_parquet <- tempfile(fileext = ".parquet")
arrow::write_parquet(mtcars_df, mtcars_parquet)

mtcars_mcols <- DataFrame(description = c("Miles/(US) gallon", "Number of cylinders",
                                          "Displacement (cu.in.)", "Gross horsepower",
                                          "Rear axle ratio", "Weight (1000 lbs)",
                                          "1/4 mile time", "Engine (0 = V-shaped, 1 = straight)",
                                          "Transmission (0 = automatic, 1 = manual)",
                                          "Number of forward gears", "Number of carburetors"),
                          row.names = colnames(mtcars))


# Titanic dataset
titanic_array <- unclass(Titanic)
storage.mode(titanic_array) <- "integer"
titanic_df <- do.call(expand.grid, c(dimnames(Titanic), stringsAsFactors = FALSE))
titanic_df$fate <- as.integer(Titanic[as.matrix(titanic_df)])
titanic_df <- titanic_df[titanic_df$fate != 0L, ]
titanic_csv <- tempfile(fileext = ".csv")
write.csv(titanic_df, titanic_csv, row.names = FALSE)
titanic_csv_gz <- tempfile(fileext = ".csv.gz")
write.csv(titanic_df, gzfile(titanic_csv_gz), row.names = FALSE)
titanic_parquet <- tempfile(fileext = ".parquet")
arrow::write_parquet(titanic_df, titanic_parquet)


# Case-sensitive characters
case_sensitive_df <- data.frame(id = letters, ID = LETTERS)
case_sensitive_path <- tempfile(fileext = ".parquet")
arrow::write_parquet(case_sensitive_df, case_sensitive_path)


# Special characters
special_df <- data.frame(id = letters[1:4], x = c(-Inf, 0, Inf, NaN))
special_path <- tempfile(fileext = ".parquet")
arrow::write_parquet(special_df, special_path)


# Atomic lists dataset
lists_df <- data.frame(
    id = sprintf("gene%02d", 1:50),
    int_list = I(lapply(1:50, function(i) sample(1:100, rpois(1, 5)))),
    dbl_list = I(lapply(1:50, function(i) runif(rpois(1, 5)))),
    chr_list = I(lapply(1:50, function(i) sample(letters, rpois(1, 5)))),
    lgl_list = I(lapply(1:50, function(i) sample(c(TRUE, FALSE), rpois(1, 5), replace = TRUE)))
)
lists_parquet <- tempfile(fileext = ".parquet")
arrow::write_parquet(lists_df, lists_parquet)


# Embeddings dataset
n_cells <- 100L
pca_data <- matrix(rnorm(n_cells * 50), nrow = n_cells, ncol = 50L)
umap_data <- matrix(rnorm(n_cells * 2), nrow = n_cells, ncol = 2L)
tsne_data <- matrix(rnorm(n_cells * 2), nrow = n_cells, ncol = 2L)
embeddings_df <- data.frame(
    cell_id = sprintf("cell_%03d", seq_len(n_cells)),
    pca = I(asplit(pca_data, 1L)),
    umap = I(asplit(umap_data, 1L)),
    tsne = I(asplit(tsne_data, 1L)),
    stringsAsFactors = FALSE
)
embeddings_parquet <- tempfile(fileext = ".parquet")
arrow::write_parquet(embeddings_df, embeddings_parquet)


# Helper functions
checkDuckDBTable <- function(object, expected) {
    expect_true(validObject(object))
    expect_s4_class(object, "DuckDBTable")
    expect_true(length(capture.output(show(object))) > 0L)
    expect_identical(dbconn(object), acquireDuckDBConn())
    expect_s3_class(tblconn(object), "tbl_duckdb_connection")
    expect_gte(nrow(object), nrow(expected))
    expect_gte(NROW(object), NROW(expected))
    expect_equal(nkey(object) + ncol(object), ncol(expected))
    expect_equal(nkey(object) + NCOL(object), NCOL(expected))
    expected_cols <- c(setdiff(colnames(expected), keynames(object)), keynames(object))
    expect_identical(c(colnames(object), keynames(object)), expected_cols)
    if (nkey(object) == 0L) {
        object <- as.data.frame(object)
        expect_gte(nrow(object), nrow(expected))
        expect_equal(ncol(object) - 1L, ncol(expected))
    } else {
        df <- as.data.frame(object)
        df <- df[match(do.call(paste, expected[, keynames(object), drop = FALSE]),
                       do.call(paste, df[, keynames(object), drop = FALSE])), ]
        rownames(df) <- NULL
        dcol_names <- setdiff(colnames(expected), keynames(object))
        expected <- expected[, c(dcol_names, keynames(object)), drop = FALSE]
        expect_equivalent(df, expected)
    }
}

checkDuckDBDataFrame <- function(object, expected) {
    expect_true(validObject(object))
    expect_s4_class(object, "DuckDBDataFrame")
    expect_true(length(capture.output(show(object))) > 0L)
    expect_identical(dbconn(object), acquireDuckDBConn())
    expect_s3_class(tblconn(object), "tbl_duckdb_connection")
    expect_identical(nrow(object), nrow(expected))
    expect_identical(ncol(object), ncol(expected))
    expect_setequal(rownames(object), rownames(expected))
    expect_identical(colnames(object), colnames(expected))
    if (nkey(object) == 0L) {
        object <- as.data.frame(object)
        expect_identical(nrow(object), nrow(expected))
        expect_identical(ncol(object), ncol(expected))
        expect_identical(colnames(object), colnames(expected))
    } else {
        expect_identical(as.data.frame(object)[rownames(expected), , drop=FALSE], expected)
    }
}

checkDuckDBColumn <- function(object, expected) {
    expect_true(validObject(object))
    expect_s4_class(object, "DuckDBColumn")
    expect_true(length(capture.output(show(object))) > 0L)
    expect_identical(dbconn(object), acquireDuckDBConn())
    expect_s3_class(tblconn(object), "tbl_duckdb_connection")
    expect_identical(length(object), length(expected))
    if (nkey(object@table) == 0L) {
        object <- as.vector(object)
        expect_identical(length(object), length(expected))
    } else {
        expect_identical(names(object), names(expected))
        expect_equal(as.vector(object), expected)
        expect_equal(realize(object), expected)
    }
}

checkDuckDBAtomicList <- function(object, expected) {
    expect_true(validObject(object))
    expect_s4_class(object, "DuckDBAtomicList")
    expect_true(length(capture.output(show(object))) > 0L)
    expect_identical(dbconn(object), acquireDuckDBConn())
    expect_s3_class(tblconn(object), "tbl_duckdb_connection")
    expect_identical(length(object), length(expected))
    expect_identical(elementNROWS(object), elementNROWS(expected))
    if (nkey(object@table) == 0L) {
        object <- as.list(object)
        expect_identical(length(object), length(expected))
    } else {
        expect_identical(names(object), names(expected))
        expect_equal(as.list(object), expected)
        expect_equal(realize(object), expected)
    }
}

checkDuckDBEmbeddings <- function(object, expected) {
    expect_true(validObject(object))
    expect_s4_class(object, "DuckDBEmbeddings")
    expect_true(length(capture.output(show(object))) > 0L)
    expect_identical(dbconn(object), acquireDuckDBConn())
    expect_s3_class(tblconn(object), "tbl_duckdb_connection")
    expect_identical(dim(object), dim(expected))
    expect_identical(nrow(object), nrow(expected))
    expect_identical(ncol(object), ncol(expected))
    if (nkey(object@table) == 0L) {
        mat <- as.matrix(object)
        expect_identical(dim(mat), dim(expected))
    } else {
        expect_identical(rownames(object), rownames(expected))
        expect_equal(as.matrix(object), expected, tolerance = 1e-10)
    }
}

checkDuckDBTransposedDataFrame <- function(object, texpected) {
    expect_true(validObject(object))
    expect_s4_class(object, "DuckDBTransposedDataFrame")
    expect_true(length(capture.output(show(object))) > 0L)
    expect_identical(dbconn(object), acquireDuckDBConn())
    expect_s3_class(tblconn(object), "tbl_duckdb_connection")
    expect_identical(nrow(object), ncol(texpected))
    expect_identical(ncol(object), nrow(texpected))
    expect_identical(rownames(object), colnames(texpected))
    expect_setequal(colnames(object), rownames(texpected))
    if (nkey(t(object)) == 0L) {
        tobject <- as.data.frame(t(object))
        expect_identical(nrow(tobject), nrow(texpected))
        expect_identical(ncol(tobject), ncol(texpected))
        expect_identical(colnames(tobject), colnames(texpected))
    } else {
        expect_identical(as.data.frame(t(object))[rownames(texpected), , drop=FALSE], texpected)
    }
}

checkDuckDBDataFrameList <- function(object, expected) {
    expect_true(validObject(object))
    expect_s4_class(object, "DuckDBDataFrameList")
    expect_true(length(capture.output(show(object))) > 0L)
    expect_identical(dbconn(object), acquireDuckDBConn())
    expect_s3_class(tblconn(object), "tbl_duckdb_connection")
    expect_identical(length(object), length(expected))
    expect_identical(names(object), names(expected))
    expect_identical(NROW(object), NROW(expected))
    expect_identical(ROWNAMES(object), ROWNAMES(expected))
    expect_identical(elementNROWS(object), elementNROWS(expected))
    expect_identical(nrows(object), nrows(expected))
    expect_identical(ncols(object), ncols(expected))
    expect_identical(dims(object), dims(expected))
    for (i in seq_along(object)) {
        expect_setequal(rownames(object)[[i]], rownames(expected)[[i]])
    }
    expect_identical(colnames(object), colnames(expected))
    expect_identical(mcols(object), mcols(expected))
    expect_identical(columnMetadata(object), columnMetadata(expected))
    expect_identical(commonColnames(object), commonColnames(expected))
    checkDuckDBDataFrame(unlist(object), as.data.frame(unlist(expected, use.names = FALSE)))
}
