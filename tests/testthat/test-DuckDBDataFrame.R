# Tests the basic functions of a DuckDBDataFrame.
# library(testthat); library(DuckDBDataFrame); source("setup.R"); source("test-DuckDBDataFrame.R")

test_that("basic methods work for a DuckDBDataFrame", {
    df <- DuckDBDataFrame(mtcars_parquet, datacols = colnames(mtcars), keycol = "model")
    checkDuckDBDataFrame(df, mtcars)

    df <- DuckDBDataFrame(mtcars_parquet, datacols = colnames(mtcars), keycol = list(model = rownames(mtcars)))
    checkDuckDBDataFrame(df, mtcars)
    expect_identical(rownames(df), rownames(mtcars))
    expect_identical(as.data.frame(df), mtcars)
    expect_identical(as.matrix(df), as.matrix(mtcars))

    df <- DuckDBDataFrame(infert_parquet)
    checkDuckDBDataFrame(df, infert)

    df <- DuckDBDataFrame(infert_parquet, datacols = colnames(infert))
    checkDuckDBDataFrame(df, infert)
})

test_that("is.na/anyNA work as expected for a DuckDBDataFrame", {
    test_df <- data.frame(
        id = 1:5,
        v = c(1, NA, 3, NA, 5),
        w = c(NA, 2, 3, 4, NA)
    )
    test_path <- tempfile(fileext = ".parquet")
    arrow::write_parquet(test_df, test_path)
    on.exit(unlink(test_path), add = TRUE)

    df <- DuckDBDataFrame(test_path, datacols = c("v", "w"), keycol = "id")

    expected <- as.data.frame(df)
    expected$v <- is.na(expected$v)
    expected$w <- is.na(expected$w)
    checkDuckDBDataFrame(is.na(df), expected)

    expect_true(anyNA(df))

    no_na_df <- DuckDBDataFrame(mtcars_parquet, datacols = c("mpg", "cyl"), keycol = "model")
    expect_false(anyNA(no_na_df))
})

test_that("renaming columns works for a DuckDBDataFrame", {
    df <- DuckDBDataFrame(mtcars_parquet, datacols = colnames(mtcars), keycol = list(model = rownames(mtcars)))
    expected <- mtcars

    replacements <- sprintf("COL%d", seq_len(ncol(df)))
    colnames(df) <- replacements
    colnames(expected) <- replacements
    checkDuckDBDataFrame(df, expected)
})

test_that("renaming rownames works for a DuckDBDataFrame with a keycol", {
    df <- DuckDBDataFrame(mtcars_parquet, datacols = colnames(mtcars), keycol = "model")
    expected <- mtcars

    replacements <- sprintf("ROW%d", seq_len(nrow(df)))
    rownames(df) <- replacements
    rownames(expected) <- setNames(names(df@keycols[[1L]]), df@keycols[[1L]])[rownames(expected)]
    checkDuckDBDataFrame(df, expected)

    df <- DuckDBDataFrame(mtcars_parquet, datacols = colnames(mtcars), keycol = list(model = rownames(mtcars)))
    expected <- mtcars

    replacements <- sprintf("ROW%d", seq_len(nrow(df)))
    rownames(df) <- replacements
    rownames(expected) <- replacements
    checkDuckDBDataFrame(df, expected)
})

test_that("renaming rownames doesn't works for a DuckDBDataFrame with row_number", {
    df <- DuckDBDataFrame(infert_parquet, datacols = colnames(infert))
    checkDuckDBDataFrame(df, infert)
    expect_error(rownames(df) <- sprintf("ROW%d", seq_len(nrow(df))))
})

test_that("slicing by columns works for a DuckDBDataFrame", {
    df <- DuckDBDataFrame(mtcars_parquet, datacols = colnames(mtcars), keycol = list(model = rownames(mtcars)))

    keep <- 1:2
    checkDuckDBDataFrame(df[,keep], mtcars[,keep])

    keep <- colnames(df)[c(4,2,3)]
    checkDuckDBDataFrame(df[,keep], mtcars[,keep])

    keep <- startsWith(colnames(df), "d")
    checkDuckDBDataFrame(df[,keep], mtcars[,keep])

    keep <- 5
    checkDuckDBDataFrame(df[,keep, drop=FALSE], mtcars[,keep, drop=FALSE])

    # Respects mcols.
    copy <- df
    mcols(copy) <- DataFrame(whee=seq_len(ncol(df)))
    copy <- copy[,3:1]
    expect_identical(mcols(copy)$whee, 3:1)

    # Respects metadata.
    copy <- df
    mcols(copy) <- mtcars_mcols
    expect_identical(metadata(copy[["carb"]]),
                     as.list(mtcars_mcols["carb", "description", drop=FALSE]))

    # Respects metadata when extracting columns.
    copy <- df
    mcols(copy) <- mtcars_mcols
    copy <- cbind(copy[, c(2, 4, 6)], copy[[1]])
    expect_identical(mcols(copy), mtcars_mcols[c(2, 4, 6, 1), , drop = FALSE])
})

test_that("extraction of a column yields a DuckDBColumn", {
    df <- DuckDBDataFrame(mtcars_parquet, datacols = colnames(mtcars), keycol = list(model = rownames(mtcars)))

    keep <- 5
    checkDuckDBColumn(df[,keep], setNames(mtcars[,keep], rownames(mtcars)))

    keep <- colnames(df)[5]
    checkDuckDBColumn(df[,keep], setNames(mtcars[,keep], rownames(mtcars)))
})

test_that("conditional slicing by rows works for a DuckDBDataFrame", {
    df <- DuckDBDataFrame(mtcars_parquet, datacols = colnames(mtcars), keycol = list(model = rownames(mtcars)))
    checkDuckDBDataFrame(df[df$cyl > 6,], mtcars[mtcars$cyl > 6,])

    df <- DuckDBDataFrame(infert_parquet)
    expected <- infert[infert$age > 30, ]
    rownames(expected) <- NULL
    checkDuckDBDataFrame(df[df$age > 30, ], expected)
})

test_that("positional slicing by rows works for a DuckDBDataFrame", {
    df <- DuckDBDataFrame(mtcars_parquet, datacols = colnames(mtcars), keycol = list(model = rownames(mtcars)))
    i <- sample(nrow(df))
    checkDuckDBDataFrame(df[i,], mtcars[i,])

    df <- DuckDBDataFrame(infert_parquet)
    i <- c(8,6,7,5,3,9)
    checkDuckDBDataFrame(df[i, ], infert[i, ])
})

test_that("slicing a contiguous integer64 key uses the BETWEEN fast-path", {
    gid <- bit64::as.integer64(1:100)
    df <- DuckDBDataFrame(int64_parquet, datacols = c("x", "y"), keycol = list(gid = gid))
    expected <- data.frame(x = as.numeric(1:100), y = as.numeric(101:200),
                           row.names = as.character(gid))
    checkDuckDBDataFrame(df[10:30, ], expected[10:30, ])

    # A contiguous integer64 range must compile to BETWEEN (enabling row-group
    # pruning), not an IN list: is.integer() is FALSE for integer64, so this path
    # was previously skipped for BIGINT / row-number keys.
    sql <- as.character(dbplyr::sql_render(tblconn(df[10:30, ])))
    expect_true(grepl("BETWEEN", sql, ignore.case = TRUE))
})

test_that("slicing a large key set uses a SEMI JOIN without duplicating rows", {
    ids <- sprintf("id%05d", 1:12000)
    df <- DuckDBDataFrame(bigkeys_parquet, datacols = "x", keycol = list(id = ids))
    keep <- ids[1:11000]
    expected <- data.frame(x = as.numeric(1:11000), row.names = keep)
    checkDuckDBDataFrame(df[keep, , drop = FALSE], expected)

    # A large membership set uses a SEMI JOIN (rendered as WHERE EXISTS), which
    # unlike an INNER JOIN neither duplicates rows nor appends the join column.
    sql <- as.character(dbplyr::sql_render(tblconn(df[keep, , drop = FALSE])))
    expect_true(grepl("SEMI JOIN|EXISTS", sql, ignore.case = TRUE))
    expect_false(grepl("INNER JOIN", sql, ignore.case = TRUE))
})

test_that(".register_key_table caches an identical large key set and invalidates across a connection release/reacquire", {
    con <- acquireDuckDBConn()
    base_tbl <- dplyr::tbl(con, dplyr::sql("SELECT 1 AS x"))
    set1 <- seq_len(300L) # > .KEY_FILTER_JOIN_THRESHOLD (256)

    reg1 <- DuckDBDataFrame:::.register_key_table(base_tbl, "k", set1)
    name1 <- dbplyr::remote_name(reg1)
    on.exit(try(duckdb::duckdb_unregister(con, name1), silent = TRUE), add = TRUE)
    reg1b <- DuckDBDataFrame:::.register_key_table(base_tbl, "k", set1)
    expect_identical(dbplyr::remote_name(reg1b), name1)

    reg_diff <- DuckDBDataFrame:::.register_key_table(base_tbl, "k", seq_len(301L))
    name_diff <- dbplyr::remote_name(reg_diff)
    on.exit(try(duckdb::duckdb_unregister(con, name_diff), silent = TRUE), add = TRUE)
    expect_false(identical(name_diff, name1))

    # Releasing and reacquiring the connection must not leave the cache
    # pointing at a registration on the now-closed connection: re-registering
    # the same key set afterward must still work against the new connection,
    # not silently reuse a now-nonexistent name.
    releaseDuckDBConn()
    con2 <- acquireDuckDBConn()
    expect_false(identical(con, con2))
    base_tbl2 <- dplyr::tbl(con2, dplyr::sql("SELECT 1 AS x"))
    reg2 <- DuckDBDataFrame:::.register_key_table(base_tbl2, "k", set1)
    on.exit(try(duckdb::duckdb_unregister(con2, dbplyr::remote_name(reg2)), silent = TRUE), add = TRUE)
    expect_equal(nrow(dplyr::collect(reg2)), 300L)
})

test_that("key-filter complement is NULL-safe (no 'NOT IN (NULL)' wipe-out)", {
    con <- acquireDuckDBConn()

    # A single NA in the exclusion set must not turn the predicate into UNKNOWN
    # for every row (the SQL 'NOT IN (..., NULL)' trap that drops all rows).
    duckdb::duckdb_register(con, "test_null_safe", data.frame(k = 1:5))
    on.exit(duckdb::duckdb_unregister(con, "test_null_safe"), add = TRUE)
    conn <- dplyr::tbl(con, "test_null_safe")
    out <- DuckDBDataFrame:::.apply_key_filter(conn, "k", c(2L, 4L, NA_integer_),
                                               complement = TRUE)
    expect_setequal(dplyr::pull(dplyr::collect(out), "k"), c(1L, 3L, 5L))

    # An NA-valued key is retained under complement when NA is not in the set,
    # matching base-R's `!(NA %in% c(2)) == TRUE`.
    duckdb::duckdb_register(con, "test_null_key", data.frame(k = c(1L, 2L, NA, 4L)))
    on.exit(duckdb::duckdb_unregister(con, "test_null_key"), add = TRUE)
    conn2 <- dplyr::tbl(con, "test_null_key")
    got <- dplyr::pull(dplyr::collect(
        DuckDBDataFrame:::.apply_key_filter(conn2, "k", 2L, complement = TRUE)), "k")
    expect_identical(sum(is.na(got)), 1L)
    expect_setequal(got[!is.na(got)], c(1L, 4L))
})

test_that("subset works for a DuckDBDataFrame", {
    df <- DuckDBDataFrame(mtcars_parquet, datacols = colnames(mtcars), keycol = list(model = rownames(mtcars)))
    checkDuckDBDataFrame(subset(df, cyl > 6, mpg:wt), subset(mtcars, cyl > 6, mpg:wt))

    df <- DuckDBDataFrame(infert_parquet)
    expected <- subset(infert, age > 30, education, drop = FALSE)
    rownames(expected) <- NULL
    checkDuckDBDataFrame(subset(df, age > 30, education, drop = FALSE), expected)

    df <- DuckDBDataFrame(infert_parquet)
    expect_identical(unname(as.vector(subset(df, age > 30, case, drop = TRUE))),
                     subset(infert, age > 30, case, drop = TRUE))
})

test_that("head works for a DuckDBDataFrame", {
    df <- DuckDBDataFrame(mtcars_parquet, datacols = colnames(mtcars), keycol = list(model = rownames(mtcars)))
    checkDuckDBDataFrame(head(df, 0), head(mtcars, 0))

    df <- DuckDBDataFrame(mtcars_parquet, datacols = colnames(mtcars), keycol = list(model = rownames(mtcars)))
    checkDuckDBDataFrame(head(df, 20), head(mtcars, 20))

    df <- DuckDBDataFrame(infert_parquet)
    checkDuckDBDataFrame(head(df, 0), head(infert, 0))

    df <- DuckDBDataFrame(infert_parquet)
    checkDuckDBDataFrame(head(df, 20), head(infert, 20))
})

test_that("tail works for a DuckDBDataFrame", {
    df <- DuckDBDataFrame(mtcars_parquet, datacols = colnames(mtcars), keycol = list(model = rownames(mtcars)))
    checkDuckDBDataFrame(tail(df, 0), tail(mtcars, 0))

    df <- DuckDBDataFrame(mtcars_parquet, datacols = colnames(mtcars), keycol = list(model = rownames(mtcars)))
    checkDuckDBDataFrame(tail(df, 20), tail(mtcars, 20))
})

test_that("unique works for a DuckDBDataFrame", {
    df <- DuckDBDataFrame(mtcars_parquet, datacols = colnames(mtcars), keycol = list(model = rownames(mtcars)))
    expected <- unique(mtcars[,8:11])
    rownames(expected) <- NULL
    checkDuckDBDataFrame(unique(df[,8:11]), expected)
})

test_that("subset assignments that produce errors", {
    df <- DuckDBDataFrame(mtcars_parquet, datacols = colnames(mtcars), keycol = list(model = rownames(mtcars)))
    expect_error(df[1:5,] <- df[9:13,])
    # A correctly-sized plain vector is now supported (see "plain-vector
    # [[<-/replaceCOLS" tests below); $<-/[[<- still reject a mismatched one.
    expect_error(df$some_random_thing <- runif(nrow(df) - 1L))
})

test_that("subset assignments works for a DuckDBDataFrame", {
    df <- DuckDBDataFrame(mtcars_parquet, datacols = colnames(mtcars), keycol = list(model = rownames(mtcars)))

    copy <- df
    copy[,1] <- copy[,1]
    checkDuckDBDataFrame(copy, mtcars)

    copy <- df
    copy[,colnames(df)[2]] <- copy[,colnames(df)[2],drop=FALSE]
    checkDuckDBDataFrame(copy, mtcars)

    copy <- df
    copy[[3]] <- copy[[3]]
    checkDuckDBDataFrame(copy, mtcars)

    copy <- df
    copy[[1]] <- copy[[3]]
    mtcars2 <- mtcars
    mtcars2[[1]] <- mtcars2[[3]]
    checkDuckDBDataFrame(copy, mtcars2)

    copy <- df
    copy[,c(1,2,3)] <- copy[,c(4,5,6)]
    mtcars2 <- mtcars
    mtcars2[,c(1,2,3)] <- mtcars2[,c(4,5,6)]
    checkDuckDBDataFrame(copy, mtcars2)
})

test_that("[[<- accepts a plain vector, for both row-number- and explicitly-keyed tables", {
    for (df in list(DuckDBDataFrame(mtcars_parquet),
                     DuckDBDataFrame(mtcars_parquet, datacols = colnames(mtcars),
                                     keycol = list(model = rownames(mtcars))))) {
        # New column.
        copy <- df
        copy$new_metric <- mtcars$mpg * 2
        expect_equal(as.data.frame(copy)$new_metric, mtcars$mpg * 2)
        expect_equal(ncol(copy), ncol(df) + 1L)

        # Replace an existing column.
        copy <- df
        copy$mpg <- mtcars$mpg + 100
        expect_equal(as.data.frame(copy)$mpg, mtcars$mpg + 100)
        expect_equal(ncol(copy), ncol(df))

        # Scalar recycling.
        copy <- df
        copy$flag <- TRUE
        expect_true(all(as.data.frame(copy)$flag))

        # NA passes through.
        copy <- df
        vals <- mtcars$mpg
        vals[3] <- NA
        copy$mpg_na <- vals
        expect_equal(as.data.frame(copy)$mpg_na, vals)

        # Sequential [[<- calls build on each other, not independently on the
        # original object (the row-identity regression this feature's design
        # review specifically flagged).
        copy <- df
        copy$a <- mtcars$mpg
        copy$b <- mtcars$disp
        result <- as.data.frame(copy)
        expect_equal(result$a, mtcars$mpg)
        expect_equal(result$b, mtcars$disp)

        # Re-replacing an earlier column after later ones were added still
        # aligns correctly (not just appending without disturbing earlier
        # writes).
        copy$a <- mtcars$qsec
        result <- as.data.frame(copy)
        expect_equal(result$a, mtcars$qsec)
        expect_equal(result$b, mtcars$disp)
    }
})

test_that("[[<- aligns correctly on a row-number-keyed table after a numeric-index subset", {
    # A numeric-index subset of a row-number-keyed table PRESERVES original
    # row identity (rownames stay "3".."8" for x[3:8,], matching base R's own
    # data.frame indexing convention) rather than renumbering to "1".."6" --
    # .inject_vector()'s join key must reflect that real identity, not assume
    # seq_len(nrow(x)). (A prior, incorrect fix attempt tried to force
    # renumbering here instead and broke "positional slicing by rows works".)
    df <- DuckDBDataFrame(mtcars_parquet)
    sub <- df[3:8, ]
    expect_identical(rownames(sub), as.character(3:8))

    sub$d <- seq_len(nrow(sub)) * 111L
    expect_equal(as.data.frame(sub)$d, seq_len(nrow(sub)) * 111L)

    # A non-contiguous, non-sorted index too. df[i,] doesn't preserve i's
    # order (DuckDB gives no row-order guarantee without an ORDER BY), so the
    # value supplied to $<- must be aligned to sub2's own current row order
    # (via rownames(sub2)), not to i's order -- the same positional contract
    # ordinary base R data.frame $<- has.
    i <- c(8L, 6L, 7L, 5L, 3L, 9L)
    sub2 <- df[i, ]
    ordered_mpg <- mtcars$mpg[as.integer(rownames(sub2))]
    sub2$e <- ordered_mpg
    expect_equal(as.data.frame(sub2)$e, ordered_mpg)
})

test_that(".canonical_row_number_values reuses one allocation per distinct content", {
    # Base R's own tracemem() gives the same object-address string
    # lobstr::obj_addr() wraps, with no extra dependency; untracemem()
    # immediately after avoids leaving copy-tracing enabled on 'x'.
    obj_addr <- function(x) {
        addr <- tracemem(x)
        untracemem(x)
        addr
    }

    df <- DuckDBDataFrame(mtcars_parquet)
    v1 <- DuckDBDataFrame:::.canonical_row_number_values(rownames(df))
    v2 <- DuckDBDataFrame:::.canonical_row_number_values(rownames(df))
    expect_identical(obj_addr(v1), obj_addr(v2))

    sub <- df[3:8, ]
    v3 <- DuckDBDataFrame:::.canonical_row_number_values(rownames(sub))
    expect_false(identical(obj_addr(v1), obj_addr(v3)))
})

test_that("[[<- with a factor value records collevels; a later plain-vector replacement clears it", {
    df <- DuckDBDataFrame(mtcars_parquet)
    grp <- factor(rep(c("a", "b", "c"), length.out = nrow(df)), levels = c("a", "b", "c", "unused"))

    copy <- df
    copy$grp <- grp
    expect_identical(unname(coltypes(copy)["grp"]), "factor")
    expect_equal(as.character(as.data.frame(copy)$grp), as.character(grp))
    # Declared-but-unobserved levels are preserved, not dropped to the
    # observed subset.
    expect_identical(levels(as.data.frame(copy)$grp), levels(grp))

    # Replacing that same column with a plain (non-factor) vector must clear
    # the stale collevels entry -- coltypes() must stop reporting "factor".
    copy$grp <- as.character(grp)
    expect_false(identical(unname(coltypes(copy)["grp"]), "factor"))
})

test_that("$<-/[[<- reject a wrong-length plain vector; [<- on columns recycles with a warning", {
    df <- DuckDBDataFrame(mtcars_parquet)
    expect_error(df$x <- runif(nrow(df) - 1L), "length")

    # Unlike $<-/[[<-, '[<-' on columns inherits S4Vectors' generic DataFrame
    # recycling (with base R's own "not a sub-multiple" warning) before
    # replaceCOLS() ever sees 'value' -- by then it has already been
    # recycled to the right length, the same as for any other DataFrame.
    copy <- df
    expect_warning(copy[, "x"] <- runif(nrow(df) - 1L), "sub-multiple")
    expect_equal(ncol(copy), ncol(df) + 1L)
})

test_that("replaceCOLS accepts a single-column plain vector but not multi-column", {
    for (df in list(DuckDBDataFrame(mtcars_parquet),
                     DuckDBDataFrame(mtcars_parquet, datacols = colnames(mtcars),
                                     keycol = list(model = rownames(mtcars))))) {
        copy <- df
        copy[, "new_metric"] <- mtcars$mpg * 2
        expect_equal(as.data.frame(copy)$new_metric, mtcars$mpg * 2)

        copy <- df
        copy[, 1] <- mtcars$mpg + 1
        expect_equal(as.data.frame(copy)[[1L]], mtcars$mpg + 1)

        # Multi-column plain-vector assignment is not yet supported.
        expect_error(df[, c("a", "b")] <- data.frame(a = mtcars$mpg, b = mtcars$disp))
    }
})

test_that("[[<- works end to end on a real SingleCellExperiment's colData", {
    skip_if_not_installed("SingleCellExperiment")
    sce <- SingleCellExperiment::SingleCellExperiment(
        assays = list(counts = matrix(seq_len(20), nrow = 4)),
        colData = DuckDBDataFrame(mtcars_parquet)[seq_len(5), ])
    sce$qc_pass <- c(TRUE, TRUE, FALSE, TRUE, FALSE)
    expect_equal(unname(as.vector(sce$qc_pass)), c(TRUE, TRUE, FALSE, TRUE, FALSE))
})

test_that("rbind produces errors", {
    df <- DuckDBDataFrame(mtcars_parquet, datacols = colnames(mtcars), keycol = list(model = rownames(mtcars)))
    expect_error(rbind(df, df))
})

test_that("rbind works for row-number-keyed DuckDBDataFrame", {
    a <- DuckDBDataFrame(mtcars_parquet)
    b <- DuckDBDataFrame(mtcars_parquet)

    # Identical columns: matches base rbind() of the same data twice.
    expected <- rbind(mtcars_df, mtcars_df)
    checkDuckDBDataFrame(rbind(a, b), expected)

    # Binding 3+ tables in one call.
    expected3 <- rbind(mtcars_df, mtcars_df, mtcars_df)
    checkDuckDBDataFrame(rbind(a, b, a), expected3)

    # Different (partially overlapping) columns: NULL-filled, like
    # dplyr::bind_rows() for in-memory data frames.
    sub <- a[, c("model", "mpg", "cyl")]
    expected_sub <- dplyr::bind_rows(mtcars_df, as.data.frame(sub))
    rownames(expected_sub) <- NULL
    checkDuckDBDataFrame(rbind(a, sub), expected_sub)

    # checkDuckDBDataFrame() only checks shape for row-number-keyed results
    # (there's no stable row order to compare values against); verify NULL-fill
    # values directly: 'sub'-contributed rows must be NA for dropped columns,
    # 'a'-contributed rows must retain their real values unchanged.
    df_sub <- as.data.frame(rbind(a, sub))
    expect_equal(sum(is.na(df_sub[["disp"]])), nrow(sub))
    expect_setequal(df_sub[["disp"]][!is.na(df_sub[["disp"]])], mtcars_df[["disp"]])

    # 3+ tables with genuinely disjoint (not just subset) non-key columns.
    t1 <- a[, c("model", "mpg", "cyl")]
    t2 <- a[, c("model", "hp", "wt")]
    t3 <- a[, c("model", "qsec")]
    df3 <- as.data.frame(rbind(t1, t2, t3))
    expect_identical(sort(colnames(df3)), sort(c("model", "mpg", "cyl", "hp", "wt", "qsec")))
    expect_equal(nrow(df3), nrow(mtcars_df) * 3L)
    expect_equal(sum(!is.na(df3[["mpg"]])), nrow(mtcars_df))
    expect_equal(sum(!is.na(df3[["hp"]])), nrow(mtcars_df))
    expect_equal(sum(!is.na(df3[["qsec"]])), nrow(mtcars_df))
})

test_that("rbind merges matching collevels and errors on conflicting ones", {
    dfA <- data.frame(id = 1:3, grp = c("a", "b", "a"))
    dfB <- data.frame(id = 4:5, grp = c("a", "b"))
    pathA <- tempfile(fileext = ".parquet")
    pathB <- tempfile(fileext = ".parquet")
    on.exit(unlink(c(pathA, pathB)))
    arrow::write_parquet(dfA, pathA)
    arrow::write_parquet(dfB, pathB)

    lvls <- list(grp = list(levels = c("a", "b"), ordered = FALSE))
    a <- DuckDBDataFrame(pathA, collevels = lvls)
    b <- DuckDBDataFrame(pathB, collevels = lvls)

    # Same recorded levels on both sides: merges cleanly, no NA introduced.
    combined <- as.data.frame(rbind(a, b))
    expect_false(anyNA(combined[["grp"]]))
    expect_setequal(combined[["grp"]], c("a", "b"))

    # Different recorded levels for the same column: silently keeping one
    # side's levels would have .apply_collevels() turn the other side's
    # values into NA on collection, so this must error instead.
    dfC <- data.frame(id = 6:7, grp = c("x", "y"))
    pathC <- tempfile(fileext = ".parquet")
    on.exit(unlink(pathC), add = TRUE)
    arrow::write_parquet(dfC, pathC)
    c_mismatched <- DuckDBDataFrame(pathC, collevels = list(grp = list(levels = c("x", "y"), ordered = FALSE)))
    expect_error(rbind(a, c_mismatched), "factor levels")

    # One side records 'grp' as a factor, the other doesn't: also a conflict,
    # since 'grp's raw values in the plain-character table may not be a
    # subset of the recorded levels.
    plain <- DuckDBDataFrame(pathB)
    expect_error(rbind(a, plain), "factor levels")
})

test_that("rbind errors when any table has explicit keycols", {
    a <- DuckDBDataFrame(mtcars_parquet)
    keyed <- DuckDBDataFrame(mtcars_parquet, datacols = colnames(mtcars),
                             keycol = list(model = rownames(mtcars)))

    expect_error(rbind(keyed, keyed), "keycols")
    expect_error(rbind(a, keyed), "keycols")
})

test_that("cbind operations that works for DuckDBDataFrame", {
    df <- DuckDBDataFrame(mtcars_parquet, datacols = colnames(mtcars), keycol = list(model = rownames(mtcars)))

    # Same path, we get another PDF.
    checkDuckDBDataFrame(cbind(df, foo=df[["carb"]]), cbind(mtcars, foo=mtcars[["carb"]]))

    # Duplicate names causes unique renaming.
    expected <- cbind(mtcars, mtcars)
    colnames(expected) <- make.unique(colnames(expected), sep="_")
    checkDuckDBDataFrame(cbind(df, df), expected)

    # Duplicate names causes unique renaming.
    expected <- cbind(mtcars, carb=mtcars[["carb"]])
    colnames(expected) <- make.unique(colnames(expected), sep="_")
    checkDuckDBDataFrame(cbind(df, carb=df[["carb"]]), expected)

    # Duplicate names causes unique renaming.
    expected <- cbind(carb=mtcars[["carb"]], mtcars)
    colnames(expected) <- make.unique(colnames(expected), sep="_")
    checkDuckDBDataFrame(cbind(carb=df[["carb"]], df), expected)
})

test_that("cbind operations that produce errors", {
    df <- DuckDBDataFrame(mtcars_parquet, datacols = colnames(mtcars), keycol = list(model = rownames(mtcars)))

    expect_error(cbind(df, mtcars))

    # Different paths causes an error.
    tmp <- tempfile(fileext = ".parquet")
    file.symlink(mtcars_parquet, tmp)
    df2 <- DuckDBDataFrame(tmp, datacols = colnames(mtcars), keycol = list(model = rownames(mtcars)))
    expect_error(cbind(df, df2))
    expect_error(cbind(df, carb=df2[["carb"]]))
})

test_that("cbinding carries forward any metadata", {
    df <- DuckDBDataFrame(mtcars_parquet, datacols = colnames(mtcars), keycol = list(model = rownames(mtcars)))

    df1 <- df
    colnames(df1) <- paste0(colnames(df1), "_1")
    mcols(df1) <- DataFrame(whee="A")

    df2 <- df
    colnames(df2) <- paste0(colnames(df2), "_2")
    mcols(df2) <- DataFrame(whee="B")

    copy <- cbind(df1, df2)
    expect_s4_class(copy, "DuckDBDataFrame")
    expect_identical(mcols(copy)$whee, rep(c("A", "B"), each=ncol(df)))

    mcols(df1) <- NULL
    copy <- cbind(df1, df2)
    expect_s4_class(copy, "DuckDBDataFrame")
    expect_identical(mcols(copy)$whee, rep(c(NA, "B"), each=ncol(df)))

    metadata(df1) <- list(a="YAY")
    metadata(df2) <- list(a="whee")
    copy <- cbind(df1, df2)
    expect_s4_class(copy, "DuckDBDataFrame")
    expect_identical(metadata(copy), list(a="YAY", a="whee"))
})

test_that("extracting duplicate columns produces errors", {
    df <- DuckDBDataFrame(mtcars_parquet, datacols = colnames(mtcars), keycol = list(model = rownames(mtcars)))
    expect_error(df[,c(1,1,2,2,3,4,3,5)])
})

test_that("coersion to a DFrame works for a DuckDBDataFrame", {
    md <- list(title = "Motor Trend Car Road Tests",
               description = "The data was extracted from the 1974 Motor Trend US magazine, and comprises fuel consumption and 10 aspects of automobile design and performance for 32 automobiles (1973–74 models).")

    mc <- DataFrame(description = c("Miles/(US) gallon", "Number of cylinders",
                                    "Displacement (cu.in.)", "Gross horsepower",
                                    "Rear axle ratio", "Weight (1000 lbs)",
                                    "1/4 mile time", "Engine (0 = V-shaped, 1 = straight)",
                                    "Transmission (0 = automatic, 1 = manual)",
                                    "Number of forward gears", "Number of carburetors"),
                    row.names = colnames(mtcars))

    ddb <- DuckDBDataFrame(mtcars_parquet, datacols = colnames(mtcars), keycol = list(model = rownames(mtcars)))
    metadata(ddb) <- md
    mcols(ddb) <- mc

    dframe <- as(mtcars, "DFrame")
    metadata(dframe) <- md
    mcols(dframe) <- mc

    expect_identical(as(ddb, "DFrame"), dframe)
    expect_identical(realize(ddb), dframe)
})

test_that("as.env works for a DuckDBDataFrame", {
    df <- DuckDBDataFrame(mtcars_parquet, datacols = colnames(mtcars), keycol = list(model = rownames(mtcars)))
    env <- as.env(df)
    expect_identical(env[["mpg"]], df[["mpg"]])
    expect_identical(env[["cyl"]], df[["cyl"]])
    expect_identical(env[["disp"]], df[["disp"]])
    expect_identical(env[["hp"]], df[["hp"]])
    expect_identical(env[["drat"]], df[["drat"]])
    expect_identical(env[["wt"]], df[["wt"]])
    expect_identical(env[["qsec"]], df[["qsec"]])
    expect_identical(env[["vs"]], df[["vs"]])
    expect_identical(env[["am"]], df[["am"]])
    expect_identical(env[["gear"]], df[["gear"]])
    expect_identical(env[["carb"]], df[["carb"]])
})

test_that("column replacement works for a DuckDBDataFrame", {
    df <- DuckDBDataFrame(mtcars_parquet, datacols = colnames(mtcars), keycol = list(model = rownames(mtcars)))
    expected <- mtcars

    df[["wt"]] <- df[["wt"]] * 1000
    expected[["wt"]] <- expected[["wt"]] * 1000
    checkDuckDBDataFrame(df, expected)

    df$gpm <- 1 / df$mpg
    expected$gpm <- 1 / expected$mpg
    checkDuckDBDataFrame(df, expected)

    df$mpg <- NULL
    expected$mpg <- NULL
    checkDuckDBDataFrame(df, expected)
})

test_that("transform works for a DuckDBDataFrame", {
    # The package requires R (>= 4.6.0). On older R the paired S4Vectors ships a
    # transform() that resolves the evaluation frame via an internal stack-walk
    # (.find_named_arg_enclos), which fails when transform() is invoked as a
    # lazily-forced argument promise (as it is here through checkDuckDBDataFrame).
    # This was fixed upstream in the S4Vectors that pairs with R (>= 4.6.0).
    skip_if(getRversion() < "4.6.0", "requires R (>= 4.6.0) for S4Vectors transform()")
    df <- DuckDBDataFrame(mtcars_parquet, datacols = colnames(mtcars), keycol = list(model = rownames(mtcars)))
    checkDuckDBDataFrame(transform(df, wt = wt * 1000, gpm = 1 / mpg),
                         transform(mtcars, wt = wt * 1000, gpm = 1 / mpg))
})
