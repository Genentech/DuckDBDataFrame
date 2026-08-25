# DuckDBDataFrame 0.99.24

## Bug fixes

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
