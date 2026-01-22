#' Call DuckDB SQL Functions on BiocDuckDB Objects
#'
#' @description
#' Apply any DuckDB SQL function to a BiocDuckDB object. This is a low-level
#' interface that provides direct access to DuckDB's extensive SQL function
#' library. The function is applied lazily and only executed when the result
#' is materialized.
#'
#' @param x A BiocDuckDB object (DuckDBTable, DuckDBColumn, DuckDBDataFrame,
#'        or DuckDBAtomicList).
#' @param fun A character string naming the SQL function to call.
#' @param ... Additional arguments passed to the SQL function. Arguments are
#'        coerced to SQL literals or column references as appropriate.
#'
#' @details
#' This function applies the specified SQL function to all data columns in the
#' object. For common operations, consider using dedicated methods or
#' convenience wrappers (e.g., \code{\link{sort}}, \code{\link{unique}},
#' \code{\link{\%in\%}}).
#'
#' Available SQL functions are documented in DuckDB's function reference:
#' \url{https://duckdb.org/docs/sql/functions/overview}
#'
#' @section Argument Handling:
#' Arguments in \code{...} are converted to SQL expressions as follows:
#' \itemize{
#'   \item \strong{Character}: SQL string literal (automatically quoted)
#'   \item \strong{Numeric}: SQL numeric literal
#'   \item \strong{Logical}: SQL boolean literal (TRUE/FALSE)
#'   \item \strong{NULL}: SQL NULL
#'   \item \strong{name/symbol}: SQL column reference (unquoted, from \code{as.name()})
#'   \item \strong{sql()}: Raw SQL expression (from \code{dplyr::sql()}, not quoted)
#' }
#'
#' @return
#' An object of the same class as \code{x} with the SQL function applied to
#' all data columns. The operation is lazy and only executed when the result
#' is materialized via \code{as.vector()}, \code{as.list()}, or similar.
#'
#' @author Patrick Aboyoun
#'
#' @examples
#' sql_call
#' showMethods("sql_call")
#'
#' @aliases
#' sql_call
#'
#' @keywords IO
#'
#' @name sql_call
NULL

#' @export
#' @rdname sql_call
setGeneric("sql_call", function(x, fun, ...) standardGeneric("sql_call"))
