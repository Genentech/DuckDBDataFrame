# DuckDBDataFrame 0.9.23

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
    `MODL_DUCKDB_EXTENSION_REPOSITORY` (or the DuckDB-native
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
