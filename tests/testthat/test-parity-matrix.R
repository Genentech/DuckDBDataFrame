# The methods of a DuckDB column give what base R gives on the same values,
# on the edge cases of helper-parity-a-core.R. See that file for what a case is.

for (case in parity_cases) {
    local({
        case <- case
        test_that(sprintf("parity: %s (%s)", case$id, case$generic), {
            parity_run(case)
        })
    })
}
