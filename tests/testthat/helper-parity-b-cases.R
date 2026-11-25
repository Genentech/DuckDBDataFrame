# The table of cases of the parity matrix. See helper-parity-a-core.R.

.case <- function(id, generic, f, inputs = "numeric", member = NULL, ...) {
    c(list(id = id, generic = generic, member = member %||% id, f = f, inputs = inputs), list(...))
}

.math <- function(fun, inputs = "numeric", ...) {
    f <- match.fun(fun)
    .case(fun, "Math", function(x, y) f(x), inputs, member = fun, ...)
}

.ops <- function(op, inputs = "numeric", ...) {
    f <- match.fun(op)
    # an integer that overflows is NA with a warning in R, and an error in DuckDB
    overflow <- if (op == "+") "int32_edge"
    c(list(.case(paste("col", op, "col"), "Ops", function(x, y) f(x, y), inputs, member = op,
                 error_on = overflow, ...)),
      list(.case(paste("col", op, "scalar"), "Ops", function(x, y) f(x, 2), inputs, member = op, ...)))
}

.summary <- function(fun, inputs = "numeric", ...) {
    f <- match.fun(fun)
    list(.case(fun, "Summary", function(x, y) f(x), inputs, member = fun, ...),
         .case(paste(fun, "na.rm"), "Summary", function(x, y) f(x, na.rm = TRUE), inputs,
               member = fun, ...))
}

.group_rows <- function(...) unlist(list(...), recursive = FALSE)

parity_cases <- c(
    # Math
    list(.math("abs"), .math("sign"), .math("ceiling"), .math("floor"), .math("trunc"),
         .math("exp"), .math("sqrt", "positive"), .math("log", "positive"),
         .math("log10", "positive"), .math("log2", "positive"),
         .math("log1p", "positive"), .math("expm1"),
         .math("cos"), .math("sin"), .math("tan"), .math("cosh"), .math("sinh"),
         .math("tanh"), .math("atan"),
         .math("acos", "unit"), .math("asin", "unit"), .math("atanh", "unit"),
         .math("asinh"), .math("acosh", "ge1"),
         .math("gamma", "positive"), .math("lgamma", "positive")),
    # Math members that the methods do not have are refused, not guessed
    lapply(c("cummax", "cummin", "cumprod", "cumsum", "cospi", "sinpi", "tanpi",
             "digamma", "trigamma"),
           function(fun) .math(fun, "positive", expect = "error")),
    list(.case("log base", "log", function(x, y) log(x, 3), "positive"),
         .case("log base 2", "log", function(x, y) log(x, 2), "positive"),
         .case("log base 10", "log", function(x, y) log(x, 10), "positive")),
    # Math2
    list(.case("round", "Math2", function(x, y) round(x), member = "round"),
         .case("round 1", "Math2", function(x, y) round(x, 1), member = "round"),
         .case("round 2", "Math2", function(x, y) round(x, 2), member = "round"),
         .case("round -1", "Math2", function(x, y) round(x, -1), member = "round"),
         .case("signif", "Math2", function(x, y) signif(x), member = "signif"),
         .case("signif 2", "Math2", function(x, y) signif(x, 2), member = "signif"),
         .case("signif 3", "Math2", function(x, y) signif(x, 3), member = "signif")),
    # Ops
    unlist(lapply(c("+", "-", "*", "/"), .ops), recursive = FALSE),
    unlist(lapply(c("^"), .ops, inputs = "positive"), recursive = FALSE),
    unlist(lapply(c("%%", "%/%"), .ops, inputs = "neg_mod_only"), recursive = FALSE),
    unlist(lapply(c("==", "!=", "<", "<=", ">", ">="), .ops), recursive = FALSE),
    unlist(lapply(c("&", "|"), .ops, inputs = "logical"), recursive = FALSE),
    list(.case("!", "!", function(x, y) !x, "logical"),
         .case("unary minus", "Ops", function(x, y) -x, member = "-")),
    # Summary
    .summary("sum"), .summary("min"), .summary("max"), .summary("range"), .summary("prod"),
    .summary("any", "logical"), .summary("all", "logical"),
    # statistics
    list(.case("mean", "mean", function(x, y) mean(x)),
         .case("mean na.rm", "mean", function(x, y) mean(x, na.rm = TRUE)),
         .case("var", "var", function(x, y) var(x)),
         .case("var na.rm", "var", function(x, y) var(x, na.rm = TRUE)),
         .case("sd", "sd", function(x, y) sd(x)),
         .case("sd na.rm", "sd", function(x, y) sd(x, na.rm = TRUE)),
         .case("median", "median", function(x, y) median(x, na.rm = TRUE)),
         .case("quantile", "quantile", function(x, y) quantile(x, c(0.1, 0.5, 0.9), na.rm = TRUE)),
         .case("IQR", "IQR", function(x, y) IQR(x, na.rm = TRUE)),
         .case("mad", "mad", function(x, y) mad(x, na.rm = TRUE))),
    # parallel extremes
    list(.case("pmax col col", "pmax", function(x, y) pmax(x, y)),
         .case("pmin col col", "pmin", function(x, y) pmin(x, y)),
         .case("pmax col col na.rm", "pmax", function(x, y) pmax(x, y, na.rm = TRUE)),
         .case("pmin col col na.rm", "pmin", function(x, y) pmin(x, y, na.rm = TRUE)),
         .case("pmax col scalar", "pmax", function(x, y) pmax(x, 0)),
         .case("pmin col scalar", "pmin", function(x, y) pmin(x, 0)),
         .case("pmax scalar col", "pmax", function(x, y) pmax(0, x)),
         .case("pmax col scalar na.rm", "pmax", function(x, y) pmax(x, 0, na.rm = TRUE))),
    # missing and infinite values
    list(.case("is.na", "is.na", function(x, y) is.na(x)),
         .case("is.nan", "is.nan", function(x, y) is.nan(x)),
         .case("is.finite", "is.finite", function(x, y) is.finite(x)),
         .case("is.infinite", "is.infinite", function(x, y) is.infinite(x)),
         .case("anyNA", "anyNA", function(x, y) anyNA(x))),
    # sets
    list(.case("%in%", "%in%", function(x, y) x %in% c(1, 3, NA)),
         .case("%in% scalar", "%in%", function(x, y) x %in% 2.5),
         .case("unique", "unique", function(x, y) unique(x)),
         .case("unique fromLast", "unique", function(x, y) unique(x, fromLast = TRUE)),
         .case("table", "table", function(x, y) table(x), c("numeric", "string")),
         .case("table useNA", "table", function(x, y) table(x, useNA = "ifany"), c("numeric", "string"),
               skip = c(with_inf = paste("base R puts NA and NaN in the order in which they occur in",
                                         "the data, and a table of counts has no such order"))),
         .case("head", "head", function(x, y) head(x, 2)),
         .case("tail", "tail", function(x, y) tail(x, 2)),
         .case("length", "length", function(x, y) length(x))),
    # strings
    list(.case("nchar", "nchar", function(x, y) nchar(x), "string"),
         .case("toupper", "toupper", function(x, y) toupper(x), "string"),
         .case("tolower", "tolower", function(x, y) tolower(x), "string"),
         .case("substr", "substr", function(x, y) substr(x, 2, 3), "string"),
         .case("substring", "substring", function(x, y) substring(x, 2, 3), "string"),
         .case("chartr", "chartr", function(x, y) chartr("ab", "xy", x), "string"),
         .case("sub", "sub", function(x, y) sub("a", "Z", x), "string"),
         .case("gsub", "gsub", function(x, y) gsub("b", "Z", x), "string"),
         .case("sub fixed", "sub", function(x, y) sub(".", "Z", x, fixed = TRUE), "string"),
         .case("grepl", "grepl", function(x, y) grepl("a", x), "string"),
         .case("grepl fixed", "grepl", function(x, y) grepl(".", x, fixed = TRUE), "string"),
         .case("startsWith", "startsWith", function(x, y) startsWith(x, "a"), "string"),
         .case("endsWith", "endsWith", function(x, y) endsWith(x, "c"), "string"),
         .case("paste", "paste", function(x, y) paste(x, y), "string"),
         .case("paste0", "paste", function(x, y) paste0(x, "_", y), "string"))
)

# Inputs that the group "neg_mod_only" names: the remainder is compared on the
# numbers that have a remainder in both systems
parity_inputs[["neg_mod_only"]] <- list(neg_mod = parity_inputs$numeric$neg_mod,
                                        finite = parity_inputs$numeric$finite)

# Methods that return the object, a part of it, or something that is not a
# value that base R has an equal of, with the reason that each has no row
NO_PARITY_ROW <- c(
    "show" = "display", "showAsCell" = "display", "tblconn" = "the query behind the object",
    "dbconn" = "the connection", "sql_call" = "a call of any SQL function, which has no base R equal",
    "sql_fun" = "a call of any SQL function, which has no base R equal",
    "names" = "accessor", "names<-" = "accessor", "keycols" = "accessor", "dimtbls" = "accessor",
    "dimtbls<-" = "accessor", "type" = "accessor", "type<-" = "accessor",
    "has_row_number" = "accessor", "keynames" = "accessor", "keydimnames" = "accessor",
    "keydimnames<-" = "accessor", "nkey" = "accessor", "nkeydim" = "accessor",
    "as.vector" = "the way that values are collected, run by every row",
    "as.data.frame" = "the way that values are collected, run by every row",
    "as.env" = "accessor", "extractROWS" = "subsetting, in test-DuckDBColumn.R",
    "extractCOLS" = "subsetting, in test-DuckDBTable.R", "[" = "subsetting, in test-DuckDBTable.R",
    "bindCOLS" = "binding, in test-DuckDBTable.R", "bindROWS" = "binding, in test-DuckDBTable.R",
    "colnames" = "accessor", "colnames<-" = "accessor", "coltypes" = "accessor",
    "coltypes<-" = "accessor", "nrow" = "accessor", "ncol" = "accessor", "rownames" = "accessor",
    "elementNROWS" = "list lengths, in test-DuckDBAtomicList.R",
    "is_nonzero" = "sparse arrays have their own tests in DuckDBArray",
    "is_sparse" = "sparse arrays have their own tests in DuckDBArray",
    "nzcount" = "sparse arrays have their own tests in DuckDBArray",
    "realize" = "materialization", "levels" = "factor accessor", "nlevels" = "factor accessor",
    "split" = "list result, in test-DuckDBColumn.R", "xtfrm" = "ordering key",
    "paste2" = "variant of paste with its own tests", "pmax2" = "unused generic")
