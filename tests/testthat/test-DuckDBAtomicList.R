# Tests the basic functions of a DuckDBAtomicList.
# library(testthat); library(DuckDBDataFrame); source("setup.R"); source("test-DuckDBAtomicList.R")

test_that("DuckDBIntegerList is created from INTEGER[] columns (no keycol)", {
    df <- DuckDBDataFrame(lists_parquet)
    int_list <- df[["int_list"]]

    expect_s4_class(int_list, "DuckDBIntegerList")
    expect_s4_class(int_list, "IntegerList")
    expect_s4_class(int_list, "DuckDBAtomicList")
    expect_identical(elementType(int_list), "integer")
    checkDuckDBAtomicList(int_list, as.list(int_list))
})

test_that("DuckDBIntegerList is created from INTEGER[] columns (keycol name)", {
    df <- DuckDBDataFrame(lists_parquet, keycol = "id")
    int_list <- df[["int_list"]]

    expect_s4_class(int_list, "DuckDBIntegerList")
    expect_s4_class(int_list, "IntegerList")
    expect_s4_class(int_list, "DuckDBAtomicList")
    expect_identical(elementType(int_list), "integer")
    checkDuckDBAtomicList(int_list, as.list(int_list))
})

test_that("DuckDBIntegerList is created from INTEGER[] columns (keycol list)", {
    df <- DuckDBDataFrame(lists_parquet, keycol = list(id = sprintf("gene%02d", 1:50)))
    int_list <- df[["int_list"]]

    expect_s4_class(int_list, "DuckDBIntegerList")
    expect_s4_class(int_list, "IntegerList")
    expect_s4_class(int_list, "DuckDBAtomicList")
    expect_identical(elementType(int_list), "integer")
    checkDuckDBAtomicList(int_list, as.list(int_list))
})

test_that("DuckDBNumericList is created from DOUBLE[] columns", {
    df <- DuckDBDataFrame(lists_parquet, keycol = "id")
    dbl_list <- df[["dbl_list"]]

    expect_s4_class(dbl_list, "DuckDBNumericList")
    expect_s4_class(dbl_list, "NumericList")
    expect_s4_class(dbl_list, "DuckDBAtomicList")
    expect_identical(elementType(dbl_list), "double")
    checkDuckDBAtomicList(dbl_list, as.list(dbl_list))
})

test_that("DuckDBCharacterList is created from VARCHAR[] columns", {
    df <- DuckDBDataFrame(lists_parquet, keycol = "id")
    chr_list <- df[["chr_list"]]

    expect_s4_class(chr_list, "DuckDBCharacterList")
    expect_s4_class(chr_list, "CharacterList")
    expect_s4_class(chr_list, "DuckDBAtomicList")
    expect_identical(elementType(chr_list), "character")
    checkDuckDBAtomicList(chr_list, as.list(chr_list))
})

test_that("DuckDBLogicalList is created from BOOLEAN[] columns", {
    df <- DuckDBDataFrame(lists_parquet, keycol = "id")
    lgl_list <- df[["lgl_list"]]

    expect_s4_class(lgl_list, "DuckDBLogicalList")
    expect_s4_class(lgl_list, "LogicalList")
    expect_s4_class(lgl_list, "DuckDBAtomicList")
    expect_identical(elementType(lgl_list), "logical")
    checkDuckDBAtomicList(lgl_list, as.list(lgl_list))
})

test_that("head works for DuckDBAtomicList", {
    df <- DuckDBDataFrame(lists_parquet, keycol = "id")
    int_list <- df[["int_list"]]

    checkDuckDBAtomicList(head(int_list, 0), as.list(head(int_list, 0)))
    checkDuckDBAtomicList(head(int_list, 5), as.list(head(int_list, 5)))
    checkDuckDBAtomicList(head(int_list, 100), as.list(head(int_list, 100)))
})

test_that("tail works for DuckDBAtomicList", {
    df <- DuckDBDataFrame(lists_parquet, keycol = "id")
    int_list <- df[["int_list"]]

    checkDuckDBAtomicList(tail(int_list, 0), as.list(tail(int_list, 0)))
    checkDuckDBAtomicList(tail(int_list, 5), as.list(tail(int_list, 5)))
    checkDuckDBAtomicList(tail(int_list, 100), as.list(tail(int_list, 100)))
})

test_that("extractROWS works for DuckDBAtomicList", {
    df <- DuckDBDataFrame(lists_parquet, keycol = "id")
    int_list <- df[["int_list"]]

    checkDuckDBAtomicList(int_list[1:10], as.list(int_list[1:10]))
    checkDuckDBAtomicList(int_list[c(1, 5, 10)], as.list(int_list[c(1, 5, 10)]))
    checkDuckDBAtomicList(int_list[c("gene01", "gene05", "gene10")],
                          as.list(int_list[c("gene01", "gene05", "gene10")]))
})

test_that("getListElement works for DuckDBAtomicList", {
    df <- DuckDBDataFrame(lists_parquet, keycol = "id")
    int_list <- df[["int_list"]]
    expected <- as.list(int_list)

    expect_identical(int_list[[1]], expected[[1]])
    expect_identical(int_list[[5]], expected[[5]])
    expect_identical(int_list[[10]], expected[[10]])
    expect_identical(int_list[["gene01"]], expected[["gene01"]])
    expect_identical(int_list[["gene25"]], expected[["gene25"]])
})

test_that("elementNROWS works for DuckDBAtomicList", {
    df <- DuckDBDataFrame(lists_parquet, keycol = "id")
    int_list <- df[["int_list"]]

    expect_identical(elementNROWS(int_list), elementNROWS(as.list(int_list)))

    subset <- int_list[1:10]
    expect_identical(elementNROWS(subset), elementNROWS(as.list(subset)))
})

test_that("as.list works for DuckDBAtomicList", {
    df <- DuckDBDataFrame(lists_parquet, keycol = "id")
    int_list <- df[["int_list"]]

    result <- as.list(int_list)
    expect_type(result, "list")
    expect_identical(result, as.list(int_list))

    result_no_names <- as.list(int_list, use.names = FALSE)
    expect_null(names(result_no_names))
    expect_identical(result_no_names, unname(as.list(int_list)))
})

test_that("realize works for DuckDBAtomicList", {
    df <- DuckDBDataFrame(lists_parquet, keycol = "id")
    int_list <- df[["int_list"]]

    result <- realize(int_list)
    expect_type(result, "list")
    expect_identical(result, as.list(int_list))
})

test_that("show works for DuckDBAtomicList", {
    df <- DuckDBDataFrame(lists_parquet, keycol = "id")
    int_list <- df[["int_list"]]

    output <- capture.output(show(int_list))
    expect_true(length(output) > 0)
    expect_true(any(grepl("IntegerList", output)))
})

test_that("length and names work for DuckDBAtomicList", {
    df <- DuckDBDataFrame(lists_parquet, keycol = "id")
    int_list <- df[["int_list"]]
    expected <- as.list(int_list)

    expect_identical(length(int_list), length(expected))
    expect_identical(names(int_list), names(expected))
})

test_that("DuckDBAtomicList works with different element types", {
    df <- DuckDBDataFrame(lists_parquet, keycol = "id")

    int_list <- df[["int_list"]]
    dbl_list <- df[["dbl_list"]]
    chr_list <- df[["chr_list"]]
    lgl_list <- df[["lgl_list"]]

    checkDuckDBAtomicList(int_list, as.list(int_list))
    checkDuckDBAtomicList(dbl_list, as.list(dbl_list))
    checkDuckDBAtomicList(chr_list, as.list(chr_list))
    checkDuckDBAtomicList(lgl_list, as.list(lgl_list))

    expect_identical(elementType(int_list), "integer")
    expect_identical(elementType(dbl_list), "double")
    expect_identical(elementType(chr_list), "character")
    expect_identical(elementType(lgl_list), "logical")
})

test_that("Empty lists are handled correctly", {
    df_with_empty <- data.frame(
        id = paste0("item", 1:10),
        values = I(list(1:3, integer(0), 4:6,
                        integer(0), 7:9,
                        integer(0), 10:12,
                        integer(0), 13:15,
                        integer(0)))
    )
    path <- tempfile(fileext = ".parquet")
    arrow::write_parquet(df_with_empty, path)

    df <- DuckDBDataFrame(path, keycol = "id")
    values <- df[["values"]]
    expected <- as.list(values)

    expect_s4_class(values, "DuckDBIntegerList")
    expect_identical(length(values), 10L)

    expected_lengths <- elementNROWS(expected)
    expect_setequal(names(values), names(expected_lengths))
    expect_identical(elementNROWS(values)[names(expected_lengths)],
                     expected_lengths)

    expect_identical(values[["item2"]], expected[["item2"]])
    expect_identical(values[["item4"]], expected[["item4"]])

    unlink(path)
})
