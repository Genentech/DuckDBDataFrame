# DuckDBDataFrame

## DuckDB-Backed Tabular Data Structures for Bioconductor

DuckDBDataFrame provides the foundational infrastructure for DuckDB-backed data structures in Bioconductor. It implements core classes including `DuckDBTable`, `DuckDBDataFrame`, and `DuckDBColumn` that extend Bioconductor's S4Vectors framework to enable efficient, out-of-memory operations on large tabular datasets.

### Why DuckDB for Tabular Data?

DuckDB is an embedded analytical database optimized for OLAP queries—exactly the operations needed for genomic data analysis: aggregations, filters, joins, and window functions. By storing data in Parquet format and querying through DuckDB, we achieve:

- **Out-of-memory processing**: Work with datasets larger than RAM
- **Lazy evaluation**: Operations execute only when needed
- **SQL optimization**: Decades of database engineering optimize your queries
- **Constant memory**: Objects maintain ~175 KB footprint regardless of data size

## Core Classes

### DuckDBTable

The n-dimensional workhorse that powers all DuckDB-backed structures:

```r
library(DuckDBDataFrame)

# Create from data frame
df <- data.frame(
    cell_id = paste0("CELL", 1:1000),
    gene_id = paste0("GENE", 1:500),
    value = rpois(500000, lambda = 2)
)

# Write to Parquet and create DuckDBTable
path <- file.path(tempdir(), "counts.parquet")
arrow::write_parquet(df, path)

table <- DuckDBTable(
    path,
    keycols = list(cell_id = unique(df$cell_id),
                   gene_id = unique(df$gene_id)),
    datacols = "value"
)

# N-dimensional operations work automatically
dim(table)  # [1] 1000 500
table[1:10, 1:5]  # Subset like a matrix
```

### DuckDBDataFrame

Extends S4Vectors `DataFrame` for metadata storage:

```r
# Cell metadata
colData <- DuckDBDataFrame(
    path = "cell_metadata.parquet",
    keycol = "cell_id"
)

# Standard DataFrame operations
colData$condition
subset(colData, condition == "treatment")
```

### DuckDBColumn

Individual column abstraction with SQL operations:

```r
col <- DuckDBColumn(path, datacol = "score", keycol = "variant_id")

# Vector operations
mean(col)
col > 0.5
sort(col)
```

### Other Classes

- **`DuckDBAtomicList`**: List columns stored as nested structures
- **`DuckDBEmbeddings`**: ARRAY[] columns for vector embeddings
- **`DuckDBTransposedDataFrame`**: Efficient transposition view
- **`DuckDBDataFrameList`**: Split data frames

## Key Features

### SQL Function Discovery

`sql_fun()` explores available DuckDB functions:

```r
# Find aggregation functions
sql_fun("agg")

# Find string functions
sql_fun("string")

# Get function documentation
sql_fun("approx_count_distinct", help = TRUE)
```

### Connection Management

Centralized DuckDB connection handling:

```r
# Acquire connection (reference counted)
conn <- acquireDuckDBConn()

# Release when done
releaseDuckDBConn(conn)
```

### MatrixStats Methods

DuckDBTable implements matrixStats directly due to its n-dimensional design:

```r
library(MatrixGenerics)

# Works on any DuckDBTable with nkey >= 2
rowSums(table)
colMeans(table)
rowVars(table)
rowSds(table)
```

This justifies why `DelayedArray`, `SparseArray`, `S4Arrays`, and `MatrixGenerics` are in the Imports—DuckDBTable is inherently n-dimensional.

## SQL Translation

DuckDBDataFrame translates R operations to efficient SQL:

| R Operation | SQL Translation |
|-------------|-----------------|
| `table[i, j]` | `SELECT * FROM table WHERE row IN (...) AND col IN (...)` |
| `subset(df, x > 5)` | `SELECT * FROM df WHERE x > 5` |
| `aggregate()` | `SELECT ... GROUP BY ...` |
| `merge()` / `join()` | `SELECT ... JOIN ... ON ...` |

## Quick Start

```r
library(DuckDBDataFrame)

# Create sample data
df <- data.frame(
    sample_id = rep(paste0("S", 1:100), each = 1000),
    gene = rep(paste0("GENE", 1:1000), 100),
    count = rpois(100000, lambda = 5),
    tpm = runif(100000, 0, 100)
)

# Write to Parquet
path <- file.path(tempdir(), "expression.parquet")
arrow::write_parquet(df, path)

# Create DuckDBTable
expr_table <- DuckDBTable(
    path,
    keycols = list(
        sample_id = unique(df$sample_id),
        gene = unique(df$gene)
    ),
    datacols = c("count", "tpm")
)

# Use like a matrix
dim(expr_table)           # [1] 100 1000
expr_table[1:5, 1:10]     # Subset
rowSums(expr_table)       # Aggregate
```

## Performance Characteristics

### Memory Efficiency

```r
# In-memory matrix: 76 MB
mat <- matrix(rpois(10e6, 2), nrow = 10000)
object.size(mat)  # 80,000,112 bytes

# DuckDBTable: 175 KB metadata + disk storage
arrow::write_parquet(
    data.frame(i = rep(1:10000, 1000),
               j = rep(1:1000, each = 10000),
               value = as.vector(mat)),
    "matrix.parquet"
)
ddb_mat <- DuckDBTable("matrix.parquet",
                       keycols = list(i = 1:10000, j = 1:1000),
                       datacols = "value")
object.size(ddb_mat)  # 179,176 bytes (450x smaller!)
```

### Lazy Evaluation

```r
# These operations are lazy—no data loaded yet
filtered <- table[table$score > 0.5, ]
sorted <- sort(filtered, by = "score")

# Evaluation happens here
result <- as.data.frame(sorted)
```

## Integration with Bioconductor

DuckDBDataFrame serves as the foundation for:

- **DuckDBArray**: Uses DuckDBTable for DelayedMatrix backend
- **DuckDBGRanges**: Uses DuckDBDataFrame for genomic ranges
- **BiocDuckDB**: Uses all classes for *Experiment objects

## When to Use DuckDBDataFrame

**Recommended for:**
- Large tabular data that doesn't fit in memory
- Metadata for millions of cells/samples/variants
- When you need SQL expressiveness in R
- Building custom DuckDB-backed S4 classes

**Consider alternatives when:**
- Data fits in memory (use `DataFrame`)
- You need mutable data structures (DuckDB is read-only)
- Complex nested structures (consider JSON/HDF5)

## Documentation

See the **[DuckDBDataFrame Classes](vignettes/DuckDBDataFrame-classes.Rmd)** vignette for detailed examples of:
- DuckDBTable construction and operations
- DuckDBDataFrame for metadata
- DuckDBColumn vector operations
- DuckDBAtomicList for list columns
- DuckDBEmbeddings for vector embeddings

## Installation

```r
# From GitHub (development)
# install.packages("remotes")
remotes::install_github("your-org/DuckDBDataFrame")
```

## Dependencies

DuckDBDataFrame depends on:
- **Bioconductor**: S4Vectors, IRanges, BiocGenerics, DelayedArray, SparseArray, S4Arrays, MatrixGenerics
- **DuckDB ecosystem**: duckdb, arrow, DBI
- **Tidyverse**: dplyr, dbplyr, tibble, rlang
- **Spatial**: sf (for spatial types)
- **Numeric**: bit64 (for large integers)

## Contributing

Contributions are welcome! Please:
- Report issues through the GitHub issue tracker
- Follow Bioconductor coding standards
- Include unit tests for new features
- Update documentation

## License

DuckDBDataFrame is licensed under the MIT License. See the LICENSE file for details.

## Acknowledgements

Special thanks to:
- The Bioconductor project for infrastructure and community
- The DuckDB team for their excellent analytical database
- The Apache Arrow project for the Parquet format
