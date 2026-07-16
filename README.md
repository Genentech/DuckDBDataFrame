# DuckDBDataFrame

*A DuckDB-backed S4Vectors DataFrame — out-of-core tabular data, stored as Parquet.*

## Overview

`DuckDBDataFrame` provides a [S4Vectors](https://bioconductor.org/packages/S4Vectors)
`DataFrame` backed by [DuckDB](https://duckdb.org) over columnar **Parquet**. It
behaves like an ordinary `DataFrame` --- `$`, `[`, `mcols()`, `cbind()` --- but the
data stays **on disk** and operations are recorded as lazy SQL queries, so you can
subset, add computed columns, and aggregate **without loading the table into memory**.

It is the tabular foundation of the **BiocDuckDB** suite: `DuckDBArray` (a
DuckDB-backed `DelayedArray`) and `DuckDBGRanges` (a DuckDB-backed `GRanges`) both
build on the underlying `DuckDBTable` abstraction.

The package ships five classes: `DuckDBTable` (the n-dimensional SQL-backed table),
`DuckDBDataFrame` (its 2-D `DataFrame` case), `DuckDBColumn` (a single atomic
column), `DuckDBAtomicList` (DuckDB `LIST[]` columns), and `DuckDBEmbeddings`
(fixed-length `ARRAY[n]` columns).

## Installation

```r
# once available from Bioconductor:
if (!require("BiocManager")) install.packages("BiocManager")
BiocManager::install("DuckDBDataFrame")
```

## Quick start

```r
library(DuckDBDataFrame)
library(arrow)

mtcars_df <- cbind(model = rownames(mtcars), mtcars)
path <- tempfile(fileext = ".parquet")
write_parquet(mtcars_df, path)

df <- DuckDBDataFrame(path, datacols = colnames(mtcars),
                      keycol = list(model = mtcars_df$model))

df[df$mpg > 25, c("mpg", "cyl")]    # lazy, on-disk subset
df$efficiency <- df$mpg / df$hp      # lazy computed column
```

`$` returns a column (a `DuckDBColumn`, still lazy) that materializes with
`as.vector()`; `mcols()` and the rest of the `DataFrame` API work as usual. DuckDB's
SQL functions are reachable via `sql_fun()` / `sql_call()`, and the shared connection
via `dbconn()`.

## When to use DuckDBDataFrame

A good fit when the table is **larger than memory** (or you want to keep memory
free), when the workload is **columnar** (filtering, aggregation, selecting a few
columns of a wide table), or when the data already lives on disk as **Parquet** that
other tools should read. An in-memory `DataFrame` remains preferable for small tables
and for row-wise or heavy random-access work.

## Documentation

- **Introduction to DuckDBDataFrame** — motivation, construction, and the common
  operations (`vignettes/DuckDBDataFrame.Rmd`).
- **Design and extension of DuckDBDataFrame** — the `DuckDBTable` abstraction, SQL
  translation, connection model, and how other packages extend it, for developers
  (`vignettes/DuckDBDataFrame-design.Rmd`).

## License

MIT License. Copyright Genentech, Inc., 2026.
