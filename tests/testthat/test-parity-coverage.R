# A method of a DuckDB column or table has a row in the parity matrix, or a reason
# that it has none. This is the test that fails when a method is added, or a
# member of a group is left out, without one: log(x, base), round, signif and
# pmax(col, 0) were all methods that nothing compared with base R.

test_that("every generic with a method for the DuckDB classes has a parity row or a reason", {
    generics <- parity_method_generics()
    rows <- unique(vapply(parity_cases, `[[`, character(1L), "generic"))
    missing <- setdiff(generics, c(rows, names(NO_PARITY_ROW)))
    expect_identical(missing, character())
    # a reason is a string, and it is not left over for a generic that has a row
    expect_true(all(nzchar(NO_PARITY_ROW)))
    expect_identical(intersect(names(NO_PARITY_ROW), rows), character())
})

test_that("every member of the group generics has a parity row", {
    members <- function(generic) {
        vapply(parity_cases[vapply(parity_cases, function(case) identical(case$generic, generic),
                                   logical(1L))], `[[`, character(1L), "member")
    }
    for (group in c("Math", "Math2", "Ops", "Summary")) {
        expect_identical(setdiff(setdiff(getGroupMembers(group, recursive = TRUE), c("Arith", "Compare", "Logic")), unique(members(group))),
                         character(), label = paste("members of", group, "without a row"))
    }
})

test_that("the parity table has no duplicate case names, and every escape says why", {
    ids <- vapply(parity_cases, function(case) paste(case$generic, case$id), character(1L))
    expect_identical(anyDuplicated(ids), 0L)
    for (case in parity_cases) {
        if (!is.null(case$escape))
            expect_true(is.character(case$escape) && nzchar(case$escape))
        if (!is.null(case$skip))
            expect_true(all(nzchar(case$skip)) && !is.null(names(case$skip)))
    }
})
