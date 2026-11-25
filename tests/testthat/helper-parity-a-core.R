# Parity of the methods of a DuckDB column with base R.
#
# A case is a function of two vectors that is run on the vectors themselves, as
# the reference, and on the columns of a table that holds them. The inputs are
# the same for every case: one registry of the edge cases that a method has to
# agree with R on. A method that is not a row of the table of cases, or in
# NO_PARITY_ROW with a reason, fails test-parity-coverage.R, so a method
# cannot be added, or a gap left, without one of the two.
#
# A case has
#   id        its name
#   generic   the S4 generic of the method, as in "Math" or "pmax"
#   member    for a group generic, the member of the group, as in "abs"
#   inputs    the names of the registry entries to run it on
#   f         function(x, y), with two vectors or two DuckDB columns
#   expect    "equal" (the default) or "error", for a method that has to refuse
#   skip      a named character vector, input = reason, of the inputs that the
#             case is not run on, for a difference that is stated in the docs
#   error_on  inputs on which DuckDB raises an error where R returns NA with a
#             warning, as for an overflow of an integer
#   escape    the reason that the result is compared without telling NA from
#             NaN, for a difference that is known and stated in the docs

parity_inputs <- list(
    numeric = list(
        finite = c(3, -1.5, 0, 2.25, 10, -7),
        half_ties = c(0.5, 1.5, 2.5, -0.5, -1.5, -2.5),
        with_na = c(1, NA, 3, -2, NA, 5),
        with_nan = c(1, NaN, NA, 4, NaN, -3),
        all_na = c(NA_real_, NA_real_, NA_real_),
        with_inf = c(1, Inf, -Inf, 2, NA, NaN),
        single = 42,
        ints = c(1L, NA, 3L, -4L, 5L),
        int32_edge = c(2147483647L, -2147483647L, 0L, 1L),
        neg_mod = c(-7, -3, 3, 7, 0.5, 2.675, 123456.789)),
    positive = list(
        positive = c(0.5, 1, 2, 10, 100, 3.5),
        positive_na = c(2, NA, 8, 0.25),
        positive_ints = c(1L, 2L, NA, 8L)),
    unit = list(unit = c(-0.5, 0, 0.5, NA, 1)),
    ge1 = list(ge1 = c(1, 2, 10, NA, 1.5)),
    logical = list(
        logicals = c(TRUE, FALSE, NA, TRUE, FALSE, NA),
        all_true = c(TRUE, TRUE, TRUE)),
    string = list(
        strings = c("Apple", NA, "banana", "", "ab cd", "ABC", "a.b"),
        strings_dup = c("x", "y", "x", NA, "y", "y")))

.parity_cache <- new.env()

parity_table <- function(input, vec) {
    if (is.null(.parity_cache[[input]])) {
        y <- if (length(vec) > 1L) rev(vec) else vec
        d <- data.frame(id = sprintf("r%03d", seq_along(vec)), x = vec, y = y,
                        stringsAsFactors = FALSE)
        path <- tempfile(fileext = ".parquet")
        arrow::write_parquet(d, path)
        .parity_cache[[input]] <- list(
            table = DuckDBDataFrame(path, datacols = c("x", "y"), keycol = "id"),
            x = vec, y = y)
    }
    .parity_cache[[input]]
}

# The value of a result, whether it is a column, a table, a table of counts or a
# vector, with the names that base R gives it and DuckDB does not left off
parity_value <- function(res) {
    if (is(res, "DuckDBColumn") || is(res, "DuckDBTable"))
        res <- as.vector(res)
    if (is.table(res))
        return(list(counts = as.vector(res), levels = unname(dimnames(res))))
    unname(res)
}

parity_compare <- function(got, ref, escape = NULL, tolerance = 1e-12) {
    got <- parity_value(got)
    ref <- parity_value(ref)
    if (!is.null(escape)) {
        expect_true(nzchar(escape))
        # NA and NaN are not told apart
        if (is.numeric(got) && is.numeric(ref)) {
            expect_identical(is.na(got), is.na(ref))
            got[is.na(got)] <- 0
            ref[is.na(ref)] <- 0
        }
    }
    expect_equal(got, ref, tolerance = tolerance)
}

parity_run <- function(case) {
    for (group in case$inputs) {
        for (nm in setdiff(names(parity_inputs[[group]]), names(case$skip))) {
            vec <- parity_inputs[[group]][[nm]]
            p <- parity_table(nm, vec)
            label <- sprintf("%s on %s", case$id, nm)
            if (identical(case$expect, "error") || nm %in% case$error_on) {
                expect_error(parity_value(case$f(p$table[["x"]], p$table[["y"]])),
                             label = label)
                next
            }
            ref <- suppressWarnings(case$f(p$x, p$y))
            got <- case$f(p$table[["x"]], p$table[["y"]])
            parity_compare(got, ref, case$escape, case$tolerance %||% 1e-12)
        }
    }
}

`%||%` <- function(a, b) if (is.null(a)) b else a

# The generics that have a method for the DuckDB classes
parity_method_generics <- function() {
    ns <- asNamespace("DuckDBDataFrame")
    out <- character()
    for (g in getGenerics(where = ns)) {
        m <- tryCatch(findMethods(g, where = ns), error = function(e) NULL)
        if (!is.null(m) && any(grepl("DuckDB(Column|Table|OrAtomic)|DuckDBColumnOrAtomic|DuckDBTableOrAtomic", names(m))))
            out <- c(out, as.character(g))
    }
    sort(unique(out))
}
