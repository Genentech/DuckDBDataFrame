#' Key Names and Key Count
#'
#' Get the keycols names, keycols dimension names, or keycols count of an object.
#'
#' @param x An object to get the keycols related information.
#' @param value A character vector of keycols dimension names.
#'
#' @author Patrick Aboyoun
#'
#' @examples
#' keynames
#' showMethods("keynames")
#'
#' keydimnames
#' showMethods("keydimnames")
#'
#' nkey
#' showMethods("nkey")
#'
#' @aliases keynames
#' @aliases keydimnames
#' @aliases keydimnames<-
#' @aliases nkey
#' @aliases nkeydim
#'
#' @aliases keynames,DuckDBTable-method
#' @aliases keydimnames,DuckDBTable-method
#' @aliases keydimnames<-,DuckDBTable-method
#' @aliases nkey,DuckDBTable-method
#' @aliases nkeydim,DuckDBTable-method
#'
#' @keywords methods
#'
#' @name keynames
NULL

#'
#' @export
#' @rdname keynames
setGeneric("keynames", function(x) standardGeneric("keynames"))

#' @export
#' @rdname keynames
setGeneric("keydimnames", function(x, value) standardGeneric("keydimnames"))

#' @export
#' @rdname keynames
setGeneric("keydimnames<-", function(x, value) standardGeneric("keydimnames<-"))

#' @export
#' @rdname keynames
setGeneric("nkey", function(x) standardGeneric("nkey"))

#' @export
#' @rdname keynames
setGeneric("nkeydim", function(x) standardGeneric("nkeydim"))
