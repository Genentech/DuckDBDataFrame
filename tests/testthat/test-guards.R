# Guards against the habits that produced the bugs of the case-collision work.
# They read the code of the package, the functions and the methods, and a
# guard is tested on a planted snippet that it has to refuse, so that a guard
# that has stopped looking is noticed.

.package_code <- function() {
    ns <- asNamespace("DuckDBDataFrame")
    out <- list()
    for (nm in ls(ns, all.names = TRUE)) {
        obj <- get(nm, envir = ns)
        if (is.function(obj) && !is(obj, "standardGeneric"))
            out[[nm]] <- paste(deparse(obj), collapse = "\n")
    }
    for (g in getGenerics(where = ns)) {
        ms <- tryCatch(findMethods(g, where = ns), error = function(e) NULL)
        for (sig in names(ms)) {
            m <- ms[[sig]]
            if (is.function(m) && identical(environmentName(environment(m)), "DuckDBDataFrame"))
                out[[paste0(g, ",", sig)]] <- paste(deparse(m@.Data), collapse = "\n")
        }
    }
    out
}

.guard_hits <- function(code, pattern) {
    names(code)[vapply(code, function(x) grepl(pattern, x, perl = TRUE), logical(1L))]
}

test_that("no code draws random numbers, which would move the seed of the user", {
    expect_identical(.guard_hits(list(bad = "paste(sample(letters, 16L), collapse = '')"),
                                 "\\b(sample|sample\\.int|runif|rnorm)\\("), "bad")
    expect_identical(.guard_hits(.package_code(), "\\b(sample|sample\\.int|runif|rnorm)\\("),
                     character())
})

test_that("names are made unique against the names of the user only where the user chose them", {
    expect_identical(.guard_hits(list(bad = "make.unique(c(colnames(conn), 'x'))"),
                                 "make\\.unique\\("), "bad")
    # these rename columns that the user is told about: a derived key that is
    # named like a data column, and the columns of a combined list
    allowed <- c(".select_tblconn", "bindCOLS,DuckDBTable", "bindROWS,DuckDBTable",
                 "coerce,DuckDBDataFrameList#DFrameList")
    unexpected <- setdiff(.guard_hits(.package_code(), "make\\.unique\\("), allowed)
    expect_identical(unexpected, character())
})

test_that("a column that the code adds to a query has a name that cannot be the name of one of the user", {
    # a name with an underscore on both sides, written in the code, is one of the
    # names that are reserved or that stand for a fresh name
    code <- .package_code()
    stems <- c("__index__", "__name__", "__position__", "__alias__", "__split_part__",
               "__g%d__", "__position_", "__key_count__", "__nonmissing__", "__n__",
               "__w%d__", "__element__")
    found <- unique(unlist(regmatches(unlist(code), gregexpr("\"__[A-Za-z0-9_%]*__?\"", unlist(code)))))
    found <- gsub("\"", "", found)
    expect_identical(setdiff(found, stems), character())
    # the guard sees a name that is not one of those
    expect_identical(setdiff("__helper__", stems), "__helper__")
})

test_that("a table name is made by tempfile, not by a fixed word", {
    bad <- list(bad = "dbExecute(conn, 'CREATE TEMP TABLE tmp AS SELECT 1')")
    expect_identical(.guard_hits(bad, "CREATE TEMP TABLE (tmp|temp|t1)\\b"), "bad")
    expect_identical(.guard_hits(.package_code(), "CREATE TEMP TABLE (tmp|temp|t1)\\b"),
                     character())
})

test_that("every writer checks the names of the columns that it writes", {
    expect_true(grepl("checkParquetColumnNames", paste(deparse(buildTableSelectSQL), collapse = "\n")))
    # writeDuckDBTableParquet writes what buildTableSelectSQL builds
    expect_true(grepl("buildTableSelectSQL", paste(deparse(writeDuckDBTableParquet), collapse = "\n")))
    expect_false(grepl("checkParquetColumnNames",
                       paste(deparse(function(x) x), collapse = "\n")))
})
