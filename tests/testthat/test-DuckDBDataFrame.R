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
    expect_error(df[,"foobar"] <- runif(nrow(df)))
    expect_error(df$some_random_thing <- runif(nrow(df)))
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

test_that("rbind produces errors", {
    df <- DuckDBDataFrame(mtcars_parquet, datacols = colnames(mtcars), keycol = list(model = rownames(mtcars)))
    expect_error(rbind(df, df))
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
