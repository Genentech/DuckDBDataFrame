#' Find Compatible DuckDB SQL Functions for BiocDuckDB Objects
#'
#' @description
#' Query DuckDB's function catalog to find SQL functions that are compatible
#' with a BiocDuckDB object's data type. This is useful for discovering what
#' operations can be performed on a particular column type.
#'
#' @param x A BiocDuckDB object (DuckDBTable, DuckDBColumn, DuckDBDataFrame,
#'        or DuckDBAtomicList).
#' @param function_type Optional character vector of function types to filter for.
#'        If NULL (default), returns all function types. Options:
#'        "scalar", "aggregate", "macro", "table", "pragma", "table_macro"
#' @param return_type Optional character vector of return types to filter for.
#'        If NULL (default), returns all functions. Common values:
#'        "BOOLEAN", "INTEGER", "DOUBLE", "VARCHAR", "ANY",
#'        "INTEGER[]", "DOUBLE[]", "VARCHAR[]", "ANY[]", etc.
#' @param description Logical; if TRUE, include function descriptions in output.
#'        Default is FALSE.
#'
#' @details
#' This function queries DuckDB directly via DESCRIBE to get the column's exact
#' type (e.g., INTEGER[], DOUBLE[], VARCHAR[]), then searches duckdb_functions()
#' for functions that accept that type as the first parameter. It matches both
#' the exact type and generic types (T[], ANY[], ANY) that work with any type.
#' 
#' The results are grouped by function name with distinct return types collected
#' into a list for functions that have multiple overloads.
#'
#' @return
#' A data.frame with the following columns:
#' \itemize{
#'   \item \strong{function_name}: Name of the function
#'   \item \strong{alias_of}: If this is an alias, the canonical function name
#'   \item \strong{function_type}: Type of function (scalar, aggregate, etc.)
#'   \item \strong{return_type}: List of distinct return types for this function
#'   \item \strong{description}: (if \code{description = TRUE}) Function description
#' }
#'
#' @author Patrick Aboyoun
#'
#' @examples
#' sql_fun
#' showMethods("sql_fun")
#'
#' @aliases
#' sql_fun
#'
#' @keywords IO
#'
#' @name sql_fun
NULL

#' @export
#' @rdname sql_fun
setGeneric("sql_fun",
    function(x, function_type = NULL, return_type = NULL, description = FALSE)
        standardGeneric("sql_fun"))
