# DuckDBDataFrame 0.99.37

## Significant changes

- `min()`, `max()`, `sum()`, `range()`, `prod()`, `any()`, `all()`, `mean()`,
  `var()`, `sd()` and `median()` of a `DuckDBColumn` or a `DuckDBTable` with one
  data column now take `na.rm` as base R does. They ignored it before: the
  `Summary` methods, `mean()`, `var()`, `sd()` and `median()` always dropped the
  missing values, so `mean(x)` of a column with an `NA` was the mean of the
  other values, and the column methods did not pass `na.rm` on to the table.
  With `na.rm = FALSE`, the default, a missing value now gives `NA`, as in base
  R, so code that relied on the old result has to pass `na.rm = TRUE`.
- A `NaN` is handled as base R handles it. With `na.rm = FALSE` it gives `NaN`
  for `sum()`, `prod()`, `mean()`, `min()` and `max()`, where `min()` used to
  skip it because DuckDB orders `NaN` above every number, and `NA` for `var()`,
  `sd()` and `median()`. With `na.rm = TRUE` it is dropped, as an `NA` is.
  Before, it was kept, so `sum(x, na.rm = TRUE)` of `c(1, NaN, 3)` was `NaN`.
  A mix of `NA` and `NaN` gives `NA`; base R leaves open which of the two it
  gives.
- An aggregate with nothing left, which is an empty column or `na.rm = TRUE`
  with only missing values, is the value base R gives for an empty set: 0 for
  `sum()`, 1 for `prod()`, `NaN` for `mean()`, `Inf` for `min()` and `-Inf` for
  `max()`. `any()` and `all()` follow the logic of base R for `NA`: `any()` is
  `TRUE` if a value is `TRUE`, and otherwise `NA` if a value is missing.
- `quantile()`, `IQR()` and `mad()` take `na.rm` as well. As in base R,
  `quantile()` and `IQR()` give an error for a missing value or a `NaN` unless
  `na.rm = TRUE`, and `mad()` is `NA` for one.
- `x[j]` of a `DuckDBDataFrame` with one index now selects columns, as it does
  for a `DataFrame`: `df[2]` and `df["y"]` are the second column and the column
  `y`, and `df[c(TRUE, FALSE)]` keeps every other column. It selected rows
  before, so `df[2]` was the second row and `df["y"]` was an error about row
  names. `df[i, ]` and `df[i, j]` still select rows. Code that used `df[i]` for
  rows has to write `df[i, ]`.

## Bug fixes

- `max(x, 100)`, `sum(x, y)` and `range(x, finite = TRUE)` of a `DuckDBColumn` or
  `DuckDBTable` ignored the arguments after the first, so `max(x, 100)` was
  `max(x)`. They are an error now. So are `mad(x, center = 5)` and
  `mad(x, low = TRUE)`, which ignored `center`, `low` and `high` and gave the
  default result.
- `sum()` of an integer column is an integer, as in base R, where it was a
  double. A sum that does not fit in an integer stays a double and is not turned
  into `NA`.
- `unique()` of a `DuckDBColumn` or `DuckDBTable` returned the values in the order
  that DuckDB's `DISTINCT` gives, which is a hash order, so `unique(x)` of a
  column holding `p, q, p, r` could be `q, r, p`. It also ignored `fromLast`.
  It now keeps the first occurrence of each value, or the last with
  `fromLast = TRUE`, in the order of the occurrences that are kept, as base R
  does, where the order is that of the object's own rows: the stored order of
  its keys, with the first key varying fastest for a table with several keys.
- `unique()` of a table that had been subset by its keys, such as
  `unique(df[c("c", "e"), ][["x"]])`, left the key filter out, so it returned
  the values of rows that are not in the subset. It now sees only the rows of the
  subset.
- `is.nan()` on a `DuckDBColumn` or `DuckDBDataFrame` returned `FALSE` for a
  stored `NaN` in a Parquet column that has no `NULL`. It called DuckDB's
  `isnan()`, which in DuckDB 2.0.0 gives `FALSE` for such a column, apparently
  because the Parquet file statistics leave `NaN` out. It now uses the
  comparison that `dbplyr` writes for `is.nan()`, which is not affected, for a
  floating point column. An integer column cannot hold a `NaN`, and that
  comparison cannot format an integer, so `is.nan()` is `FALSE` there.
- `is.na()` and `anyNA()` on a `DuckDBColumn` or `DuckDBDataFrame` had the same
  problem. They test a floating point column for `NaN` as well as for `NULL`,
  through `isnan()`, so a `NaN` in a Parquet column with no `NULL` was not
  missing: `anyNA()` was `FALSE` for a column of `c(1, 2, NaN)`, where base R is
  `TRUE`. They now use the same test as `is.nan()`.
- `%in%` with a table that contains `NaN` failed with a database error on an
  integer column, and had the same `isnan()` problem on a floating point column.
  It now tests for `NaN` as `is.nan()` does and leaves an integer column alone.
- `is.finite()` and `is.infinite()` on a `DuckDBColumn` or `DuckDBDataFrame`
  returned `NA` for a missing value, because DuckDB's `isfinite()` and `isinf()`
  are `NULL` for a `NULL`. Base R gives `FALSE`, so a missing value is now
  `FALSE`.
- `as.matrix()` of a `DuckDBEmbeddings` returned the rows in the order of the
  file, not in the order of the object, which is the stored order of its keys.
  Each row kept its own key, so a lookup by name was right, but `head(x, 3)`,
  `x[2:4, ]`, `as.list(x)` and `realize(x)` gave the right rows in the wrong
  order. The rows now follow the order of the object, as `as.data.frame()` does.
- New exported helper `addRowPosition(x, conn, name)` adds a column that holds
  the position of each row in the order of `x`: the stored order of its keys, with
  the first key varying fastest for a table with several keys. `unique()` uses it,
  and so do the position-based functions of other packages, which used to number
  the rows in the order in which DuckDB scans the file.
- `writeDuckDBTableParquet()`, and so `BiocDuckDB::writeParquet()` of a lazy
  table, wrote `__index__` as the number of the row in the order in which DuckDB
  scans the file, and wrote the rows in that order. For a file that is not in key
  order the index then disagreed with the object: a table with the keys `c, a, d,
  b` in the file and `a, b, c, d` as its own order was written with the index
  `1, 2, 3, 4` on `c, a, d, b`, so a reader that keys the table by `__index__`, as
  `readParquet()` does for a table whose schema is sorted by it, got the rows in
  the order of the file, and `x[1, ]` was a different row after the round trip.
  The index is now the position of the row in the order of the object, which is
  the stored order of its keys, and the rows are written in that order. A table
  numbered by row, and an in-memory data frame, were not affected.
- `writeDuckDBTableParquet()`, and so `BiocDuckDB::writeParquet()` of a lazy
  table, lost the row names of a table whose key stands for names. A table read
  from files that store a number per row, with the names of the rows kept apart,
  has numbers as the values of its key and the names as the names of those values,
  and `rownames()` gives the names. The key column was written from the values, so
  it held the numbers: an experiment that was read and written again came back with
  its samples numbered `1, 2, 3, 4` where they were `cell_c, cell_a, cell_d,
  cell_b`. The key column now holds the names.

## Testing

- New tests check `is.nan()` and `%in%` with `NaN` on a column that holds `NaN`
  and no `NA`, on one that holds both, and on an integer column. They fail on the
  previous code.
- A new test compares `is.na()` and `anyNA()` with base R for columns that hold
  `NaN` and no `NA`, `NaN`, `NA` and infinite values, and integers, and for a
  `DuckDBDataFrame`. It fails on the previous code.
- A new test compares `is.finite()` and `is.infinite()` with base R for columns
  that hold finite values only, infinite values, `NaN`, `NA`, all of these
  together, only `NA`, and integers with `NA`, for a column and for a
  `DuckDBDataFrame`. It fails on the previous code.
- A new test file, `test-aggregates-missing.R`, compares the aggregates above
  with base R, with and without `na.rm`, for a column and for a table, on data
  that holds finite values, an `NA`, a `NaN`, both, only `NA`, infinite values, a
  single value, and a `NaN` with no `NA`. It also covers `any()` and `all()` of a
  logical column with `NA`, the type of an integer `min()` and `max()`, an empty
  table, and the check on `na.rm`. It fails on the previous code.
- The same test file compares `quantile()`, `IQR()` and `mad()` with base R, with
  and without `na.rm`, on the same kinds of data, and checks the integer type of
  `sum()` and the arguments that are now rejected. It fails on the previous code.
- A new test compares `x[j]`, `x[i, ]` and `x[i, j]` of a `DuckDBDataFrame` with
  those of a `DataFrame`. It fails on the previous code.
- New tests compare `unique()` of a column and of a table with base R, with and
  without `fromLast`, for a derived key order, a key order that the user gave,
  `NA` and `NaN`, and a table subset by its keys. The order and the subset tests
  fail on the previous code.
- A new test builds embeddings from a file that is not in key order, with a
  derived and a user-given key order, and checks the rows of `as.matrix()`,
  `head()`, `x[i, ]` and `as.list()` against the order of the object. It fails on
  the previous code.
- New tests write a lazy table whose file is not in key order, with a derived and
  a user-given key order, and check that `__index__` and the order of the rows in
  the file are the positions in the order of the object, that a table keyed by the
  index has its rows in the same positions as the original, that a row-number
  table keeps its index, and that a column of the table with the unusual name
  `__position__` is written unchanged. The first of these fails on the previous
  code.
- A new test writes a lazy table whose key stands for names, from a file that is in
  key order and from one that is not, and checks that the key column holds the
  names, that the index is the position in the order of the object, and that each
  row keeps its value. It fails on the previous code.

# DuckDBDataFrame 0.99.36

## Significant changes

- The keys of a table read from the database now come in a fixed order. A
  character key used to be left in the order that `DISTINCT` emits, which is a
  hash order that changes with the thread count and the row-group layout, so the
  same file could give different rownames in different sessions, `x[1:3, ]` could
  pick different rows, and a value assigned in file order, such as
  `x$y <- v`, could land on the wrong rows. Character keys are now sorted in
  C-locale (byte) order, which is also what DuckDB's `ORDER BY` gives and does not
  depend on the locale, as numeric keys already were. A key list passed as
  `keycol` is still never reordered, so pass one to get a specific order, such
  as the order of the file.
- A key column can no longer have missing values, and a table with a single key
  column can no longer repeat a key. Both are now an error when the table is
  made, naming the column, with a pointer to leaving out `keycol` to number the
  rows instead. Before, a missing character key gave an `NA` rowname, so
  `dim()` said 3 rows where the data had 2 and `show()` failed; a missing
  numeric key was dropped without a word; and a repeated key was counted once by
  `dim()` while aggregates such as `sum()` counted every row. A table with two
  or more key columns, such as an array, is not affected: there a value repeats
  along the other dimensions, and only the combination has to be unique.
- Row subscripts now follow `DataFrame`, or say why they cannot:
  - Negative and zero subscripts work on a table numbered by row. `x[-1, ]`
    used to return no rows.
  - A missing value, an out-of-range number and a name that is not there are
    errors. They used to give an object whose dimensions disagreed with its
    data.
  - A subscript that selects a row more than once is an error. `x[c(1, 1, 2), ]`
    used to report 3 rows and return 2, and fail when printed. A lazy table is a
    view of its source and cannot repeat a row; use `as.data.frame(x)[i, ]`.
  - A table numbered by row can only select rows in increasing order.
    `x[c(3, 1), ]` used to return rows 1 and 3 in file order. A table with a
    `keycol` can still list its rows in another order.
  - On an array, a subscript is bounded by the number of keys in the dimension it
    addresses, as it should be, and not by the number of rows of the table.

## Bug fixes

- A key that is the empty string came back as `NA`: the result was looked up by
  name, which cannot find `""`, so `as.vector(x$a)` gave `NA` for that row and
  `as(x, "DFrame")` had a row named `"NA"`. Results are now put in key order by
  position.
- A lazy filter on a table that had already been subset, such as
  `y <- x[5:20, ]; y[y$a > 12, ]`, rebuilt the keys from `DISTINCT`, which
  reached keys outside the subset. The result had `NA` rownames and more rows
  than data, and the keys lost the order they had. The keys now keep their
  order and stay inside the subset.
- A subscript by name on a table with a key, such as `y["r5", ]`, selected from
  the keys given and not the keys of the table, so a row outside a subset could
  come back. It now selects among the keys the table has.
- `%in%` on a `DuckDBColumn` or `DuckDBDataFrame` returned `NA` for every row
  whose value was missing, and for every row when the table contained an `NA`,
  because it passed the lookup straight to SQL `IN`. It now follows base R: the
  result is never `NA`, `NA` matches only an `NA` in the table, and `NaN`
  matches only a `NaN`. Reported in #6, with a fix proposed by the contributor
  in #7 that this change builds on.
- `%in%` with a `DuckDBColumn` as the table, such as `x %in% y` for two columns
  of a table, returned a plain `logical` with one value per element of the
  table instead of one per element of `x`. A column is an S4Vectors `Vector`,
  so the `(Vector, Vector)` method was chosen and compared the two lazy objects
  with `match()`. A `DuckDBColumn` or `DuckDBTable` on the left with a
  `DuckDBColumn` table now collects the table's values and gives the same
  lazy result as for a vector table.

## Testing

- A new test file, `test-row-order-contract.R`, checks the order and identity of
  rows against `DataFrame`. Unlike the helpers in `setup.R`, which compare
  rownames as sets, it compares them in order, which is why the problems above
  went unnoticed.
- Two existing tests, "positional slicing by rows works" and "[[<- aligns
  correctly on a row-number-keyed table after a numeric-index subset", used an
  index that was not in increasing order on a table numbered by row and passed
  only because the table returned the rows in file order. They now use an
  increasing index, and the first also checks the new error.
- New tests compare `%in%` on a `DuckDBColumn` with base R for numeric columns
  holding `NA` and `NaN` and for a character column, with tables that contain
  `NA`, `NaN`, both, or nothing.
- New tests compare `%in%` with a `DuckDBColumn` as the table with base R, for
  numeric and character columns, a lookup in the same column, an empty table,
  and a table with one column. They fail on the previous code.

# DuckDBDataFrame 0.99.35

## Bug fixes

- `writeDuckDBTableParquet()`, and so `BiocDuckDB::writeParquet()`, failed on a
  table with a column that had been added or changed lazily, such as
  `x$flag <- x$id == "a"`, with a binder error saying the table has no column
  `flag`. Such a column exists only as an expression on the table, and the
  write read the underlying table by column name instead. The write now applies
  the table's column definitions first, so added columns, columns that replace a
  stored one, and columns built from another derived column are written.

# DuckDBDataFrame 0.99.34

## Bug fixes

- A numeric or logical subscript on a row-number-keyed table was matched
  against the preserved row numbers instead of against row positions, which
  gave wrong rows once an earlier subset had left gaps in them. For example,
  `x[2:5, ][c(1, 4), ]` returned only the row numbered 4, where a
  `data.frame` returns the rows numbered 2 and 5. Subscripts now count
  the rows of the table being subset, as for a `data.frame`, and `rownames()`
  still keep the original row numbers. Code that indexed a table that had
  already been subset by the original row numbers must now use positions. The
  mapping adds a window function only when the row numbers are no longer
  exactly `1..n`, so the common first subset is unchanged.
- Subsetting a `DuckDBTable`, `DuckDBDataFrame` or `DuckDBColumn` that is keyed
  by row number with a logical `i`, such as `x[keep]` or `x[keep, ]`, failed
  with "unsupported 'i' for row subsetting with row_number", even for
  `x[TRUE]`. Only numeric subscripts were handled, so code that selects rows
  with a logical vector, such as `SpatialFeatureExperiment` picking out one
  sample's geometries, could not use a lazy column. A logical `i` of length 1
  or `nrow(x)` with no `NA`s is now converted to row positions and handled
  like a numeric one. A character `i` still fails, since these tables have no
  row names, and its error now says to use a numeric or logical `i`.

# DuckDBDataFrame 0.99.33

## Bug fixes

- Parquet writes that went through `arrow` always requested `zstd`
  compression, which errors outright on a "minimal" `arrow` build (common in
  CI/Docker images) that was not compiled with zstd codec support.
  `buildParquetCopySQL()` and `.applyFactorLevels()` hardcoded
  `COMPRESSION zstd`/`compression = "zstd"` with no fallback. Added
  `resolveParquetCompression()`, which checks
  `arrow::codec_is_available("zstd")` and falls back to `snappy` (dropping
  the compression level, since DuckDB and `arrow` both error if a
  compression level is paired with a non-zstd codec) when it is not
  available; `buildParquetCopySQL()` gained `compression`/`compression_level`
  arguments defaulting to it. zstd is still preferred whenever it is
  available. `BiocDuckDB` and `DuckDBArray` adopt the same helper for their
  own direct `arrow::write_parquet()`/`write_dataset()` calls. Fixes #1;
  supersedes #2, which only skipped the affected tests rather than fixing
  the underlying writes.

# DuckDBDataFrame 0.99.32

## Bug fixes

- Filtering a `DuckDBTable`/`DuckDBDataFrame` to a large, moderately-clustered
  integer key subset (e.g. a real biological cell/gene selection, not a
  purely random sample) could crash with a node stack overflow -- a raw,
  uncatchable crash under `callr::r_bg()`, or a catchable "evaluation nested
  too deeply" error elsewhere. `.filter_tblconn()` chooses between an inline
  range filter and a join based only on a *ratio* heuristic
  (`length(ranges) <= max(10, k / 10)`), with no absolute ceiling; a subset
  compressing into thousands of contiguous ranges satisfies that ratio
  easily, and `.build_range_filter()` combines them via an unbounded
  `Reduce(call("|", ...))`, building a call tree thousands of nodes deep.
  Walking that tree (dbplyr's SQL translation, or `deparse()`) can then
  overflow R's C-level node stack. Reported externally with a precise,
  minimal, dependency-free reproduction of the underlying `Reduce()` issue.
  Fixed by also capping the range count at the existing
  `.KEY_FILTER_JOIN_THRESHOLD`, falling back to the already-robust
  join-based path (`.apply_key_filter()`) instead of building new
  tree-balancing machinery for a problem that path already solves. Verified
  directly: reverting just this cap reproduces a real `node stack overflow`
  on the new regression test.
- `BIOCDUCKDB_EXTENSION_REPOSITORY`/`DUCKDB_EXTENSION_REPOSITORY` was
  ignored by `loadExtension()`'s explicit `INSTALL`, so a mirror had no
  effect on a locked-down network. `configureExtensionAutoloading()` only
  set `autoinstall_extension_repository`, which covers DuckDB's *implicit*
  autoloading, not a plain `INSTALL` statement -- the one `loadExtension()`
  actually runs -- which instead consults `custom_extension_repository`,
  never set. `DuckDBSpatial` loads `spatial` this way in its `.onLoad`, so
  every `st_*` call failed with "not in the catalog" behind a mirror.
  Confirmed directly: setting only `autoinstall_extension_repository` to an
  empty local directory let `INSTALL` silently fall through to the public
  repository; setting `custom_extension_repository` instead made `INSTALL`
  error out referencing that local directory by name. Fixed by setting both.
  Thanks to @buyan-kh for the diagnosis, fix, and test (#5, fixing #4).

# DuckDBDataFrame 0.99.31

## Bug fixes

- Fixed a Bioconductor `nebbiolo2` build-report `ERROR` surfacing in
  `BiocDuckDB`'s test suite: `writeDuckDBTableParquet()`'s schema-sampling
  step unconditionally fetches via DuckDB's Arrow export
  (`dbSendQueryArrow()`/`dbFetchArrow()`), which requires the `nanoarrow`
  package. `duckdb` itself only lists `nanoarrow` under its own `Suggests`
  (not a hard dependency), so it is not guaranteed to be installed wherever
  `duckdb` is -- `nebbiolo2` lacked it, failing every test that calls
  `writeParquet()`/`writeDuckDBTableParquet()` with
  `Error in \`require_arrow()\`: The nanoarrow package is required for this
  functionality`. Added `nanoarrow` to this package's own `Suggests` and a
  `requireNamespace("nanoarrow", quietly = TRUE)` guard that falls back to
  the pre-optimization full-file reread when it is not available, so the
  optimization is used when possible but its absence is never a hard error.
  Verified via a new regression test that mocks `requireNamespace()` to
  force the fallback path and confirms it still produces a sample matching
  the full reread exactly.
- Fixed the Bioconductor `nebbiolo2` build-report `ERROR`: a test exercising
  `.canonical_row_number_values()`'s memory deduplication used
  `tracemem()`/`untracemem()` to confirm repeated calls on the same rowname
  values return the identical object rather than a fresh copy. `nebbiolo2`'s
  R build lacks memory-profiling support, so `tracemem()` itself errored
  before the dedup logic was ever exercised. The test now
  `skip_if_not(capabilities("profmem"), ...)` first, verified both on a
  profmem-enabled build (test still runs and passes) and with
  `capabilities()` mocked to report `FALSE` (test now skips cleanly instead
  of erroring).
- Fixed an accompanying `NOTE` for calling an unexported `S4Vectors:::`
  function (`make_rownames_for_RectangularData_display()`) from `show()`
  methods in `DuckDBDataFrame-class.R` and `DuckDBEmbeddings-class.R`.
  Vendored a local `.make_rownames_for_display()` helper instead of reaching
  into `S4Vectors`'s internals.
- Fixed a `NOTE` for `\linkS4class{}` cross-references to classes defined in
  other packages (`DataFrame`, `Vector`, `AtomicList`, `RectangularData`,
  `TransposedDataFrame`, `SplitDataFrameList`, `CharacterList`), which
  `\linkS4class{}` cannot anchor to the defining package on its own. Replaced
  with explicit `\link[pkg]{Target-class}` anchors, matching this package's
  existing convention for the same kind of cross-package class reference.

# DuckDBDataFrame 0.99.30

## Performance

- `writeDuckDBTableParquet()` no longer reads the entire just-written part
  file back through `arrow::read_parquet()` purely to pull the ≤100-row
  sample `writeParquet()` uses for `datapackage.json` schema inference.
  Schema sampling now re-derives the write's own `SELECT` via
  `buildTableSelectSQL()` (dropping the index expression, which would
  otherwise force full materialization before a `LIMIT` can apply) and
  fetches through DuckDB's Arrow export, so wide integer columns still get
  the same `arrow` int64-downcast conversion the old full-file reread
  relied on. The `__index__` sample column, no longer part of that query, is
  synthesized in R from the write's own offset/row-count instead. Schema
  output is unaffected; only how the sample backing it is obtained changed.
- `.get_duckdb_schema()` (behind `coltypes()`, `DuckDBDataFrame`'s `[[`, and
  transitively every `writeParquet()` call via `.hasLazyGeometryColumn()`)
  issued a fresh `DESCRIBE` query, with its dplyr/dbplyr query-construction
  overhead, on every call even though a given `(conn, datacols)` pair's
  schema never changes. It is now memoized in a small `identical()`-keyed
  LRU (following the same content-keyed-env pattern as `DuckDBConnection.R`'s
  `key_table_cache`, including invalidation on `releaseDuckDBConn()`), keyed
  on the raw inputs rather than a hash digest of them, since most of the
  function's cost is the dplyr construction a hash key would still have to
  pay for.

# DuckDBDataFrame 0.99.29

## New features

- `[[<-`/`$<-` and single-column `[<-` on `DuckDBDataFrame` now accept a
  plain in-memory R vector or factor as `value`, not just a lazy
  `DuckDBColumn`/`DuckDBDataFrame` derived from the exact same underlying
  table. `sce$newcol <- some_external_vector` (the single most routine
  operation in `SingleCellExperiment`/`SpatialFeatureExperiment`-style
  workflows) failed outright before this, confirmed via a real spike
  constructing an SCE with `DuckDBDataFrame` colData: without it,
  `DuckDBDataFrame` isn't viable as a `colData` substitute for anything past
  already-fully-annotated, read-only data. A survey of every existing
  "in-memory -> lazy DuckDB" technique in this package suite found literal
  `IN`/`CASE` SQL embedding for small filter sets and `duckdb_register()`
  zero-copy registration + a named-key join for large ones (the pattern
  this suite's own most performance-tuned code, `BiocDuckDB`'s `scran`
  helpers, already moved *to*, away from `copy_to()`-based joins, for
  speed); `dplyr::rows_update()` (an external contributor's own draft for
  this exact feature) has no precedent anywhere in the suite. The new value
  is joined into the table's lazy query by its own existing key column
  (its already-materialized row-number column for the default,
  row-number-keyed case -- never a freshly recomputed `row_number()`, since
  DuckDB's has no `ORDER BY` and isn't guaranteed stable across separate
  evaluations -- or its single named keycol otherwise), always via
  `duckdb_register()` + `left_join()`; no size-gated literal-embedding
  fallback, since the realistic target use case (`colData`-sized tables:
  Visium ~5k spots, Xenium/MERFISH 10k-1M+ cells) essentially never has few
  enough rows for that to matter, so it would only have added bug surface
  for a path that would not run in practice. The registered temp table is
  intentionally never unregistered (the same already-shipped tradeoff as
  `DuckDBSpatial::.as_duckdb_table()`/`DuckDBArray::.duckdb_matmult_copy()`,
  now also documented here): it must survive for the entire remaining
  lifetime of whatever object is built from it. Replacing a factor column
  with a plain vector explicitly clears the stale `collevels` entry, rather
  than leaving `coltypes()` reporting `"factor"` against data that no
  longer is. Multi-column plain-vector assignment
  (`x[, c("a","b")] <- data.frame(...)`) has no existing precedent for its
  shape and is not yet supported.

## Bug fixes

- `.register_key_table()` (used by `.apply_key_filter()` for large
  membership-filter sets) registered a new DuckDB virtual table on every
  call and never unregistered it; since `tblconn()` is not memoized, this
  leaked unboundedly on the shared process-wide connection for an
  explicitly-keyed table whose current key subset exceeds 256 distinct
  values. (Deliberately decoupled from the feature above: it's real but
  orthogonal -- ordinary row-number-keyed `colData` can never trigger it --
  and was already session-bounded, since a process-exit finalizer already
  disconnects the shared connection.) Fixed with a content-keyed cache on
  the connection's own `.duckdb` package environment (a connection object
  itself can't hold a cache: it's an ordinary copy-on-modify R value, and
  `tblconn()` re-extracts it fresh every call), invalidated inside
  `releaseDuckDBConn()` -- confirmed empirically that a registration left
  over from a since-released connection fails immediately and confusingly
  (`dplyr::tbl()` eagerly probes the catalog) if reused on a new one.
- `factor(x)` on a `DuckDBColumn` crashed with a C stack overflow (not a
  catchable R-level error) instead of erroring or returning a result.
  `factor()` calls `order()` when `levels` isn't supplied explicitly;
  `order()` falls back to `xtfrm()` for a class it doesn't recognize, which
  itself falls back to `rank()`, which needs ordering again -- with no
  `xtfrm()` method of its own, `DuckDBColumn` had no base case to stop that
  loop. Added `xtfrm,DuckDBColumn-method`, which materializes first
  (`xtfrm(as.vector(x))`): `order()`/`sort()`/`rank()` all already route
  through `xtfrm()` for an unrecognized class, so the one method covers all
  three. (`sort()` was also checked while fixing this: it no longer
  crashes, but still doesn't actually reorder a `DuckDBColumn`'s rows --
  numeric-index subsetting only supports membership filtering today, not
  the arbitrary reordering/repetition `x[order(x)]` needs. Left open; it's
  a deeper question than this fix, not a quick one.)

# DuckDBDataFrame 0.99.28

## New features

- `rbind()` now works for a `DuckDBTable`/`DuckDBDataFrame` keyed by row
  number (the default construction, i.e. no explicit `keycols`), backed by
  `bindROWS,DuckDBTable-method` (previously an unconditional `stop()`).
  Reported by a user who drafted a candidate implementation around
  `dbplyr::bind_queries()` (`UNION ALL`) and asked whether `rbind()`/`c()`
  not being supported was a design choice. It was deliberate for tables
  with real, named `keycols` (row identity under a named key has no
  well-defined union across tables: colliding or disjoint key values,
  mismatched `dimtbls`, etc.), so that case still errors, now with a
  message naming the offending `keycols`. For the common row-number-keyed
  case, each side's pending `datacols` transformations are resolved via
  `tblconn()` before the union (not the raw `@conn`, which would silently
  drop them), and a fresh row-number key is computed afterward so rows are
  uniquely addressable in the combined table. Tables with different columns
  are supported: missing columns are NULL-filled, as `dplyr::bind_rows()`
  does for in-memory data, but unlike `bind_rows()`, a shared column with a
  different type across tables (e.g. integer vs. character) is implicitly
  cast by DuckDB rather than erroring (values are preserved, not lost, but
  this can mask a real type mismatch in calling code). `collevels` (factor
  levels) are merged across inputs: a shared column must have the *same*
  recorded levels (or not be a factor) in every table supplying it, or
  binding errors — silently preferring one table's levels would let
  `.apply_collevels()` quietly turn another table's values into `NA` on
  collection. Requires `dbplyr >= 2.6.0` (for `bind_queries()`, gated at
  runtime, not pinned in `DESCRIPTION` per house convention). Note `c()` is
  not wired to `bindROWS()` for this class (unlike `rbind()`, which
  dispatches through `BiocGenerics::rbind`'s `RectangularData` method); use
  `rbind()` instead.

# DuckDBDataFrame 0.99.27

## Bug fixes

- `sql_fun,DuckDBTable-method` built its `return_type IN (...)` predicate by
  pasting the user-supplied `return_type` argument directly between
  hardcoded quotes (`paste0("'", return_type, "'", ...)`), with no
  escaping, before sending the query to `dbGetQuery()`. `return_type` was
  validated only as `is.character()`, so a value containing a `'` (e.g.
  `"x') OR 1=1 --"`) broke out of the string literal. Real-world
  exploitability was low (this queries DuckDB's own local, in-process,
  read-only `duckdb_functions()` catalog inside an embedded single-user
  database, no network boundary or cross-tenant data involved), but it was
  the one place in the file not using `DBI::dbQuoteString()` despite DBI
  already being imported in the same method. The parallel
  `function_type IN (...)` predicate built the same way was not actually
  exploitable (`match.arg(..., several.ok = TRUE)` constrains it to a
  fixed enum first) but is fixed the same way for consistency. Both now
  quote via `DBI::dbQuoteString(conn, ...)`.

# DuckDBDataFrame 0.99.26

Reverted

# DuckDBDataFrame 0.99.25

## Bug fixes

- `is.na()` and `anyNA()` on a `DuckDBColumn`, `DuckDBTable`, or
  `DuckDBDataFrame` silently reported no missing values at all, regardless
  of the actual data. Neither class defined its own `is.na`/`anyNA`, so both
  inherited S4Vectors' `Vector`/`List` fallback stubs
  (`rep.int(FALSE, length(x))` and `function(x, recursive = FALSE) FALSE`),
  which exist for abstract `Vector` subclasses with no inherent notion of
  missingness -- the wrong inheritance for a class backed by real,
  well-defined per-row SQL `NULL` semantics. Both now have real methods:
  `is.na()` delegates to `sql_call(x, "is.na")` (dbplyr's SQL translator
  already renders the R function name `is.na` as `IS NULL`, so no new
  query-building code was needed, only reusing the existing `is.finite`/
  `is.infinite`/`is.nan` delegation pattern with a different function name);
  `anyNA()` ORs every data column's "is missing" expression into one per-row
  predicate and evaluates a single `any()` aggregate of it in one query.
  Because `DuckDBDataFrame` extends `DuckDBTable` before `DataFrame`,
  `anyNA()` needed to work correctly for any number of data columns itself
  rather than relying on the S4Vectors per-column `DataFrame` composition,
  which is never reached.
- Fallout from the above, caught by extending the existing `is.finite`/
  `is.infinite`/`is.nan` test to a `special_path` fixture that already
  includes a `NaN`: DuckDB's `x IS NULL` does not treat `NaN` as missing
  (`NaN IS NULL` is `FALSE` in DuckDB), but R's `is.na()` does (`is.na(NaN)`
  is `TRUE`). `is.na()`/`anyNA()` now additionally check `isnan(x)` for
  `"double"`-typed columns specifically, matching R's semantics exactly
  without affecting any other column type.

# DuckDBDataFrame 0.99.24

## Bug fixes

- Opening a directory required *every* file in it to be parquet, so a
  resource directory carrying an ordinary sibling (`_SUCCESS`,
  `_common_metadata`, a README) was left unwrapped and then resolved as a
  catalog table name, failing with a leaked SQL parser error quoting the
  path. The test was also written `any(all(...))`, which is just `all(...)`:
  `all()` already returns a single logical. A directory is now opened when it
  contains *any* parquet part, and the glob targets the parquet extensions
  actually present rather than `**`, which would otherwise hand the siblings
  to `read_parquet()`.

- `DuckDBDataFrame()` now refuses a directory carrying an `_INCOMPLETE`
  marker, naming it in the error. This has to ship together with the change
  above: refusing such a directory was previously only a *side effect* of
  requiring every file to be parquet, so relaxing that test on its own would
  have made an interrupted multi-part write silently readable as partial
  data (verified: it returns the parts written so far, with no error).
  `_INCOMPLETE` is written by BiocDuckDB's `writeStreamingResource()` for the
  duration of a stream.

- `splitParquetPart()` could destroy the data it was splitting. It called
  `unlink()` on the source file *before* copying the new parts into place,
  discarded `file.copy()`'s return value, and left `overwrite = FALSE`, so a
  copy that failed for any reason (a full disk, a permission or filesystem
  error) removed the only copy of the data and then returned **without
  signalling an error**, leaving a manifest pointing at a resource that no
  longer existed. The source file is now moved aside rather than deleted, the
  copy's success is checked, and any failure rolls the directory back to
  exactly its original contents before erroring. The move-aside is needed
  because a newly written part can legitimately have the same name as the
  source file; it stays within the resource directory so it remains a
  same-filesystem rename.
  - Relatedly, a target directory that could not be written to previously
    produced a silent no-op that was reported to the caller as a successful
    split. It now errors.
- `writeDuckDBTableParquet()` dropped factor columns' levels. The lazy write
  path is a SQL `COPY`, and DuckDB has no categorical type, so every factor
  was flattened to plain `VARCHAR`; any level unused in the data was lost
  outright, since it is not recoverable from the written values alone. The
  recorded `collevels` were never consulted, even though the equivalent
  arrow-side fixup already existed in this file for `splitParquetPart()`'s
  own DuckDB round trip. That fixup is now factored into a shared internal
  helper and applied on this path too, before the returned `sample_df` is
  read back, so the caller's schema inference also sees the factors and can
  emit the `categories`/`categoriesOrdered` schema keywords correctly.
  Non-factor columns are untouched.
- The factor-restoration path no longer leaves the parquet files it inspects
  open, which made it fail on Windows. It rewrites each file in place, and
  `splitParquetPart()` additionally renames and then unlinks its source file;
  Windows refuses all three operations while any mapping or handle on the
  file is still live. Two distinct leaks were involved:
  - `arrow`'s default *memory-mapped* read (`[Windows error 1224] The
    requested operation cannot be performed on a file with a user-mapped
    section open`). All reads on this path now pass `mmap = FALSE`. Staging
    the write elsewhere and renaming into place would not have helped, since
    replacing a mapped file is blocked in the same way.
  - An open *file handle*. `.findFactorColumns()` needs only the schema, but
    `open_dataset()` cannot opt out of memory-mapping and `ParquetFileReader`
    has no `Close()` method, so either one leaves the file open until the
    reader is garbage-collected. It now creates its own `ReadableFile`,
    passes that to `ParquetFileReader`, and closes it explicitly; the
    returned `Schema` remains valid afterwards.

  `splitParquetPart()` also drops its DuckDB temporary table before touching
  the source file, rather than at function exit, so nothing on the DuckDB
  side still refers to it either.

  The schema read is now shared by `readParquetSchema()` and
  `.findFactorColumns()` through one internal helper. `readParquetSchema()`
  had the same leak (verified: one open handle per call, now none). It was
  not reachable as a bug, since its only caller appends a new part rather
  than rewriting the file it inspected, but it is exported and one step away
  from the paths that do rewrite. It also no longer reads the file's data
  just to obtain its schema.

  This affected the pre-existing `splitParquetPart()` restoration path as
  well as the new one; it surfaced only now because that function had no
  test coverage before this release.

# DuckDBDataFrame 0.99.23

## Bug fixes

- `coltypes()`/`type()` (and the `show()` header row they drive) now report
  `"factor"` for a character column with a recorded `collevels` entry,
  instead of `"character"`. `collevels` (set by `readParquet()` from the
  schema's `categories`/`categoriesOrdered`, a standard Frictionless Table
  Schema keyword) already correctly restored `factor` columns on
  materialization (`as.data.frame()`, `as.vector()`); only the
  non-materializing type-reporting methods hadn't been taught to look at
  it, so a lazy `DuckDBDataFrame`'s `colData()` display showed
  `<character>` for a column that was, in fact, a factor as soon as you
  pulled it out. `coltypes<-` is unchanged: `"factor"` is not a settable
  cast target, and recasting a factor column's underlying type still
  drops its `collevels` entry as before.

## New features

- Added `levels()`/`nlevels()` methods for `DuckDBColumn`, returning the
  recorded `collevels` levels (or `NULL`/`0`) without materializing the
  column.

# DuckDBDataFrame 0.99.22

## Bug fixes

- `splitParquetPart()` was silently dropping factor columns to plain
  character, and losing any factor level unused in the data outright
  (unrecoverable from the written values alone), because DuckDB has no
  categorical/dictionary SQL type and flattens an Arrow dictionary-encoded
  column to `VARCHAR`. Factor columns (including ordered ones and unused
  levels) are now detected from the source file's schema before the
  DuckDB-based row split and restored on each output part afterward via a
  small, per-part `arrow`-only read/rewrite.

# DuckDBDataFrame 0.99.21

## New features

- Added `splitParquetPart()`, a `parquet-io` helper that rebalances a
  directory's single flat `part-*.parquet` file into `n_parts` smaller
  ones, in place, e.g. after a writer emitted everything into a single
  large `part-0.parquet`. Row order is preserved: part 0 gets the first
  ~1/`n_parts` rows in on-disk order, part 1 the next ~1/`n_parts`, and so
  on, as if the file had simply been cut into contiguous slices. Uses
  DuckDB's `file_row_number` Parquet-reader option and an explicit
  `ORDER BY` on both the bucket assignment and each part's write, since
  neither a bare `ntile() OVER ()` nor an unordered read-back is
  guaranteed to match on-disk order under DuckDB's parallel scan.

## Documentation

- Added the missing `@aliases coerce,DuckDBSelfHits,SelfHits-method` entry
  in `?DuckDBSelfHits-class`; the `setAs("DuckDBSelfHits", "SelfHits", ...)`
  coercion was implemented but not documented, which `R CMD check` flagged
  as a missing documentation entry.

# DuckDBDataFrame 0.99.20

## Documentation

- Replaced em dashes with commas or colons in the vignettes.

# DuckDBDataFrame 0.99.19

## Follow-up review changes

- Renamed the exported low-level generics and helpers to drop the leading dot,
  per the Bioconductor guideline that `.`-prefixed names should not be exported:
  `.keycols` -> `keycols`, `.has_row_number` -> `has_row_number`,
  `.set_row_number` -> `set_row_number`, and
  `.makePrettyCharacterMatrixForDisplay` -> `makePrettyCharacterMatrixForDisplay`.
  These remain the shared cross-package extension API and are now documented on a
  dedicated internal man page (`?DuckDBDataFrame-internals`, marked
  `\keyword{internal}`). Companion packages (DuckDBGRanges, and callers in
  BiocDuckDB) are updated to the new names.
- Design vignette: reworded the lazy-evaluation paragraph to integrate and
  briefly define "predicate" (a row filter such as `mpg > 25`) rather than
  trailing "predicate pushdown, direct Parquet scans".

# DuckDBDataFrame 0.99.18

## Documentation

- Addressed the Bioconductor review of DuckDBDataFrame:
  - Added `URL` and `BugReports` fields to DESCRIPTION.
  - Added a package-level man page (`?DuckDBDataFrame`).
  - Added runnable, demonstrative examples to `sql_call()` and `sql_fun()`.
  - Introduction vignette: added a "Relationship to arrow" section; explained
    construction (a bare path suffices; `datacols`/`keycol` are optional) and the
    `keycol = "model"` versus `keycol = list(model = ...)` forms; clarified that
    adding a computed column changes only the in-memory object (a lazy SQL
    expression) and does not modify the Parquet file; changed the `sql_call()`
    rounding example to `round(., 0)`.
  - Design vignette: expanded construction detail; contrasted `DuckDBTable` with a
    keyless `DuckDBDataFrame` (`identical()` FALSE, `all.equal()` TRUE) and added
    `.has_row_number()` under key-dimension semantics; clarified how dimension
    tables enable partition pruning; added a minimal example of extending
    `DuckDBDataFrame`.
  - Removed the redundant `library(BiocStyle)` call from both vignettes.

## Internal

- Removed the unused internal helper `.get_type()`.

# DuckDBDataFrame 0.99.17

## New features

- Exported `clusterOrderSQL()` and `columnExtents()`, the SQL-side primitives
  behind the `cluster_by` write path. `clusterOrderSQL(conn, subquery_sql,
  cluster_by, available)` lowers a `zorder()` / `hilbert()` / character spec into
  `ORDER BY` expressions for `buildParquetCopySQL(order_cols=)`; `columnExtents()`
  returns per-column finite `[min, max]` over a subquery. These let another
  package (e.g. `DuckDBArray`'s coord-array writer, and a future serving-layout
  builder) cluster a `COPY TO` without re-deriving the Morton / Hilbert generator,
  keeping a single curve implementation across the suite. No behavior change to
  existing exports; this only surfaces internals as a documented API.

# DuckDBDataFrame 0.99.16

## Bug fixes

- `writeDuckDBTableParquet()` no longer drops the row-group size. It gains a
  `row_group_size` argument defaulting to `491520L` (240 x the 2048 DuckDB
  `STANDARD_VECTOR_SIZE`) and threads it into `buildParquetCopySQL()`; previously
  the lazy `DuckDBTable` export passed no size and fell back to DuckDB's 122880
  default while every other writer path (coord arrays, flat arrow) already
  targeted 491520. This affected the wide colData table and lazy-written graph
  edge lists. Faithful repack (row-group count only); the data is unchanged.

# DuckDBDataFrame 0.99.15

## Bug fixes

- `show(<DuckDBSelfHits>)` now `format()`s the hit and node counts before printing
  them, so a graph with more than 2^31 hits (or nodes) reports the true count
  instead of a denormalized double. `nrow()` returns a bit64 `integer64` once the
  count exceeds `.Machine$integer.max`, and `cat()` prints an `integer64`'s
  underlying bit pattern (e.g. `1.377174e-314`) rather than its value; a k=100
  neighbor graph over ~28M cells (~2.78e9 edges) tripped this, while a sub-2^31
  graph printed correctly. Display-only: the edge data was always correct.

# DuckDBDataFrame 0.99.14

## Bug fixes

- `as.matrix(<DuckDBEmbeddings>)` now `unname()`s the row keys before assigning
  them, so an aliased keycol no longer leaves a stray `names` attribute on the
  matrix's `dimnames[[1]]`. `.map_keycol_names()` returns a NAMED character
  vector for an aliased key, and unlike `names<-`, `rownames<-`/`dimnames<-`
  keeps that inner attribute — which broke equality against a plain-rownames
  matrix (e.g. a reduced-dimension round-trip). Regression from the 0.99.7
  query-order label fix.

# DuckDBDataFrame 0.99.13

## Bug fixes

- The cgroup `memory_limit` / `threads` detectors used by `configureOutOfCore()`
  now resolve the job's **own** cgroup subpath from `/proc/self/cgroup` (both
  cgroup v2 unified and v1 per-controller, including combined mounts like
  `cpu,cpuacct`) before falling back to the mount root. A cgroup-constrained
  **non-SLURM** job was previously undetected — the fixed root paths
  (`/sys/fs/cgroup/memory.max`, …) only match when the process runs in the root
  cgroup — so it silently fell back to physical RAM / hardware concurrency, the
  over-commit the defaults are meant to prevent. The mount root stays in the
  search list, so detection never regresses where it already worked. The
  detectors (`.cgroupDirs()`, `.cgroupMemoryBytes()`, `.cgroupCpus()`,
  `.physicalMemoryBytes()`) take injectable path parameters and are now covered
  by fixture-based unit tests.

# DuckDBDataFrame 0.99.12

## Bug fixes

- `configureOutOfCore()` now also defaults DuckDB `threads` to the job's CPU
  allocation when neither `DuckDBDataFrame.threads` nor `BIOCDUCKDB_THREADS` is
  set: the most-restrictive of a SLURM allocation (`SLURM_CPUS_PER_TASK`, or
  `SLURM_CPUS_ON_NODE`) and the cgroup CFS quota (v2 `cpu.max`, v1
  `cpu.cfs_quota_us`/`cpu.cfs_period_us`). DuckDB otherwise defaults threads to
  hardware concurrency, which ignores a SLURM/cgroup cpuset and over-subscribes
  on a shared node — and each extra thread's working memory pushes against the
  same cgroup the `memory_limit` default (0.99.10) targets. When no allocation
  is detected, DuckDB's default is left in place. New internal helpers
  `.slurmCpus()` / `.cgroupCpus()` / `.defaultThreads()`.

# DuckDBDataFrame 0.99.11

## Bug fixes

- `as.vector(<DuckDBColumn>)`, `as.list(<DuckDBAtomicList>)`, and
  `as.data.frame(<DuckDBDataFrame>)` now reorder their query result into the
  object's canonical stored-key order length-safely, extending the
  `as.matrix(<DuckDBEmbeddings>)` fix (0.99.7) to its siblings. They previously
  re-indexed by the stored key vector (`result[rownames(x@table)]`) after
  labelling from the materialized keycol; when the stored key set diverged from
  the materialized rows (a subset filtered through a dimension table, or
  aliased / duplicate keys) that silently NA-padded, first-matched a duplicate,
  or truncated. The reorder now happens only when the stored keys and
  materialized names are a clean 1:1 correspondence and otherwise falls back to
  query order with every value kept paired with its true name; a `row_number`
  key keeps query order (and no longer triggers a full key scan just to
  reorder). New internal helpers `.storedKeysBijective()` / `.reindexByStoredKeys()`.

# DuckDBDataFrame 0.99.10

## Bug fixes

- `configureOutOfCore()` now defaults the DuckDB `memory_limit` to 80% of the
  most-restrictive detected ceiling when neither `DuckDBDataFrame.memory_limit`
  nor `BIOCDUCKDB_MEMORY_LIMIT` is set: an explicit SLURM allocation
  (`SLURM_MEM_PER_NODE`, or `SLURM_MEM_PER_CPU` times `SLURM_CPUS_ON_NODE`), the
  cgroup limit (v2 `memory.max` then v1 `memory.limit_in_bytes`), then physical
  RAM (`/proc/meminfo`). DuckDB's own default is 80% of *physical* RAM, which
  ignores a SLURM / cgroup cap and over-commits — nearly OOM-ing on the first
  large scan of a big out-of-core aggregation instead of spilling. When nothing
  can be detected (e.g. macOS) DuckDB's default is left in place.

# DuckDBDataFrame 0.99.9

## Bug fixes

- `configureOutOfCore()` now always sets and creates (recursively) the DuckDB
  spill `temp_directory`. When neither `DuckDBDataFrame.temp_directory` nor
  `BIOCDUCKDB_TEMP_DIRECTORY` is set it defaults to a `temp` subdirectory of
  `R_user_dir("DuckDBDataFrame", "cache")` instead of relying on DuckDB's
  default under the R session tempdir, and a configured path is created before
  `SET temp_directory`. On batch schedulers whose per-job tempdir (e.g. SLURM
  `/tmp`) is small or cleaned mid-session, a large out-of-core sort/aggregation
  previously failed with "IO Error: Failed to create directory ... No such file
  or directory"; the spill directory is now guaranteed to exist.

# DuckDBDataFrame 0.99.8

## Bug fixes

- Import `as.matrix` methods table from S4Vectors to ensure the methods
  defined in this package are exported.

# DuckDBDataFrame 0.99.7

## Bug fixes

- `as.matrix(<DuckDBEmbeddings>)` now derives row names from the same
  materialized query as the matrix (the keycol column) rather than from the
  stored keycol slot via `rownames()`. For a named key, `rownames()` returns
  `keydimnames()` = the stored `keycols` vector, whose length can diverge from
  the materialized row count (e.g. a subset filtered through a dimtbl, or
  aliased / duplicate keys). That divergence made `show()`/`as.matrix()` on a
  large embedding fail with "length of 'dimnames' [1] not equal to array
  extent". Row names are now consistent with the row count by construction.

# DuckDBDataFrame 0.99.6

## New features

- `buildParquetCopySQL()` gains an `append` argument that emits the DuckDB
  `APPEND` copy option. This lets a `PARTITION_BY` write add new files to an
  existing (hive-partitioned) directory instead of failing "directory is not
  empty", which is what a coord-array append needs (DuckDBArray).

# DuckDBDataFrame 0.99.5

## Bug fixes

- The lazy SQL write path (`writeDuckDBTableParquet()` / `buildTableSelectSQL()`)
  now types the `__index__` column the same way the in-memory writer does,
  instead of always emitting a BIGINT `row_number()`. It `CAST`s the index to a
  type chosen by range (narrowed on a fresh write, `index_max` honored, or pinned
  to part 0's on-disk type on append), so a resource written or appended across
  both write paths keeps one consistent `__index__` type. Previously an
  in-memory part 0 (narrowed) plus a lazy append (BIGINT) produced a
  schema-inconsistent, unreadable resource, and the same table had a different
  index type depending on which path wrote it.

# DuckDBDataFrame 0.99.4

## Bug fixes

- `DuckDBSelfHits()` now fails loudly when `nnode` (or a supplied node id)
  exceeds the 32-bit integer range, instead of letting `as.integer()` silently
  coerce it to `NA` (which corrupted graph reconstruction). Graphs with more
  than ~2.1e9 nodes are not yet supported; the error says so explicitly.

# DuckDBDataFrame 0.99.3

## Bug fixes

- `validateAppendOffset()` now accepts a whole-number append `offset` above the
  32-bit integer range instead of coercing it via `as.integer()` (which produced
  `NA`), and `buildTableSelectSQL()` emits the offset as a full integer literal
  rather than a 32-bit `%d`. Together these let a resource with more than ~2.1e9
  rows stream without the append offset overflowing to `NA`. Offsets within the
  32-bit range are still returned as `integer`, so index-column narrowing is
  unchanged for the common case.

# DuckDBDataFrame 0.99.2

## Bug fixes

- The `transform()` test is now skipped on R (< 4.6.0). The package requires
  R (>= 4.6.0); on older R the paired `S4Vectors` ships a `transform()` whose
  internal evaluation-frame stack-walk fails when `transform()` is called as a
  lazily-forced argument promise. This avoids a spurious test ERROR on the
  R-oldrel build of an unsupported R version.

# DuckDBDataFrame 0.99.1

## Bug fixes

- The `table()` methods for `DuckDBTable` and `DuckDBColumn` now declare `x` as
  a formal argument (`function(x, ...)`), conforming to the `table` generic in
  Bioconductor-devel `BiocGenerics`, which dispatches on `x`
  (`setGeneric("table", signature = "x")`) rather than on `...`. Under the
  previous `function(...)` definition the package failed to install on
  Bioc-devel with a `conformMethod` error ("formal arguments ... omitted in the
  method definition cannot be in the signature"). Behavior is unchanged, and the
  new signature also conforms against the `...`-dispatch generic in the current
  Bioconductor release.

# DuckDBDataFrame 0.9.29

## New features

- `configureCloud()` wires up remote object-storage reads on the shared
  connection: it installs + loads the DuckDB `httpfs` extension up front (so a
  firewalled environment fails early with actionable guidance rather than
  mid-read) and applies `s3_*` credential / region settings (`s3_region`,
  `s3_access_key_id`, `s3_secret_access_key`, `s3_session_token`, `s3_endpoint`,
  `s3_url_style`, `s3_use_ssl`) resolved from R options (`DuckDBDataFrame.s3_*`)
  or `BIOCDUCKDB_S3_*` environment variables, applied after `httpfs` loads
  (DuckDB does not know the `s3_*` settings until then). See `?DuckDBConnection`.

- A dataset backed by a **remote object-storage directory** (`s3://`, `gs://`,
  `http(s)://`, …) now resolves correctly. Because the VFS cannot be listed with
  `list.files()`, the connection wrapper detects a remote URI, calls
  `configureCloud()`, and lets DuckDB's `httpfs` glob expand
  `read_parquet('<uri>/**')` — reads only; writing to object storage stays
  unsupported (see `BiocDuckDB::writeParquet`).

# DuckDBDataFrame 0.9.28

## New features

- `configureOutOfCore()` sets the DuckDB out-of-core engine knobs
  (`memory_limit`, `threads`, `temp_directory`, `preserve_insertion_order`) on
  the shared connection from R options or `BIOCDUCKDB_*` environment variables
  (see `?DuckDBConnection`). It runs automatically the first time
  `acquireDuckDBConn()` creates the connection, so a large aggregation / sort /
  join can spill instead of being OOM-killed, and a very large export can drop
  insertion-order buffering.

## Changes

- The internal extension-mirror environment variable is now
  `BIOCDUCKDB_EXTENSION_REPOSITORY` (previously
  `MODL_DUCKDB_EXTENSION_REPOSITORY`); the DuckDB-native
  `DUCKDB_EXTENSION_REPOSITORY` fallback is unchanged.

# DuckDBDataFrame 0.9.27

## New features

- `writeParquet(..., cluster_by = )` clusters rows on write so DuckDB row-group zonemaps
  prune range queries. `cluster_by` is a character vector (lexicographic ordering),
  `zorder(cols)` (a Morton / Z-order space-filling code over any number of numeric columns,
  lowered SQL-side to a generated bit-interleave `ORDER BY` — no extension needed), or
  `hilbert(cols)` (the native DuckDB `spatial` `ST_Hilbert`, exactly two numeric columns,
  better locality, requires the spatial extension). Space-filling keys compute per-column
  extents with one cheap `MIN/MAX` scan and bake them into a pushed-down `ORDER BY`, so the
  DuckDB write path never materializes the table. A single physical order clusters one key:
  supplying `cluster_by` overrides the default `__index__` ordering. New exported
  `zorder()` / `hilbert()` constructors and `clusterSort()` (the in-memory counterpart used
  by the materializing `data.frame` / `DataFrame` write path). This generalizes the
  coord-indexed points layout (DuckDBSpatial) to any multi-dimensional range-queried table
  (spatial points, embeddings / reducedDims, genomic-interaction bins).

# DuckDBDataFrame 0.9.25

## New features

- Exported `loadExtension()`, which installs (if needed) and loads a DuckDB
  extension on a connection. It was already used internally to load `spatial` /
  `httpfs`; exporting it lets companion packages ensure their required extension
  is available on the shared connection — e.g. `DuckDBSpatial` now installs and
  loads `spatial` on load via `loadExtension(acquireDuckDBConn(), "spatial")`.

# DuckDBDataFrame 0.9.24

## New features

- `DuckDBTable()` and `DuckDBDataFrame()` gain a `collevels` argument that
  restores `factor` (and ordered-factor) columns on materialization. Levels are
  carried on the object and applied lazily when a column is collected, so
  `readParquet()` can recover factors recorded in a product's schema. Columns
  that are cast or otherwise transformed away from a character type are left
  untouched.
- Reading a column whose DuckDB type cannot be represented faithfully in R now
  emits a one-time warning: 128-bit integers (`HUGEINT`/`UHUGEINT`) and wide
  `DECIMAL` (precision > 15) collapse to `double`, and unsigned 64-bit
  (`UBIGINT`) collapses to signed `integer64`.

# DuckDBDataFrame 0.9.23

## Bug fixes

- Row subsetting by key no longer risks silently dropping every row. A key
  filter whose complement (exclusion) set contained an `NA` compiled to SQL
  `NOT IN (..., NULL)`, which evaluates to `UNKNOWN` for *all* rows and returned
  an empty result. `NA`-valued keys are now handled explicitly and never emitted
  inside an `IN` list, reproducing base-R `%in%` semantics.

## Internal changes

- The BETWEEN fast-path for contiguous key ranges (which enables Parquet
  row-group pruning) now also fires for `integer64` keys. Because `is.integer()`
  is `FALSE` for `integer64`, the fast-path was previously skipped for exactly
  the `BIGINT` / row-number keycols where it matters most, falling back to an
  `IN` list.
- Membership subsetting for large key sets now uses a `SEMI JOIN` rather than an
  `INNER JOIN` against the temporary key table. `SEMI JOIN` is the correct
  membership primitive: it neither duplicates rows when the key repeats nor
  appends the join column.
- Lowered the key-set size at which filtering switches from an inline `IN` list
  to a temporary-table `SEMI`/`ANTI JOIN` (from 10000 to 256). Large inline `IN`
  lists dominate DuckDB's SQL compile time, so the crossover belongs in the low
  hundreds.

# DuckDBDataFrame 0.9.22

## Internal changes

- Reworked DuckDB extension handling toward a plug-and-play experience.
  Connections no longer eagerly `INSTALL` `spatial`/`httpfs` from the public CDN
  on every connect (which made an optional, spatial-only concern everyone's
  problem). Instead `acquireDuckDBConn()` now:
  - enables DuckDB **autoloading**, so extensions are fetched and loaded on first
    use of a function that needs them;
  - honors an optional **internal extension mirror** for restricted networks via
    `BIOCDUCKDB_EXTENSION_REPOSITORY` (or the DuckDB-native
    `DUCKDB_EXTENSION_REPOSITORY`);
  - eagerly `LOAD`s only extensions **already present** in the extension directory
    (a local, offline-safe operation), so a pre-provisioned or air-gapped cache
    just works.
- As a result, non-spatial workflows no longer make any network attempt for
  extensions on connect. `loadExtension()` is retained as a helper for explicit
  or vendored loading.

# DuckDBDataFrame 0.9.21

## Documentation

- Restructured the vignettes into a user-first set:
  *Introduction to DuckDBDataFrame* (motivation, construction, and the common
  operations) and *Design and extension of DuckDBDataFrame* (the `DuckDBTable`
  abstraction, SQL translation, connection model, and extension points, for
  developers).
- Rewrote the README.

## Internal changes

- Install and load DuckDB extensions into a writable extension directory
  (honoring `DUCKDB_EXTENSION_DIRECTORY`), so extension use works on shared or
  read-only R libraries; optional extensions degrade gracefully.
- Minor code-style cleanups flagged by `BiocCheck`: replaced `sapply()` with
  `setNames(lapply(...))` where names must be preserved, used `seq_len()` in
  place of `1:n`, and tidied condition-signal messages.
