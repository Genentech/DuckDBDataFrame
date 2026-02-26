#' Spatial operations on DuckDBTable objects
#'
#' @description
#' Spatial operations on \linkS4class{DuckDBTable} objects.
#'
#' @section Geometry Creation:
#' In the code snippets below, \code{x} is a DuckDBTable object.
#' \describe{
#'   \item{\code{st_as_sfc(x, ..., crs = NA_integer_, GeoJSON = FALSE, WKB = FALSE)}:}{
#'     Parses WKT (default), GeoJSON, or WKB into GEOMETRY via
#'     \code{ST_GeomFromText}, \code{ST_GeomFromGeoJSON}, or
#'     \code{ST_GeomFromWKB}.
#'   }
#' }
#'
#' @section Geometry Coercion:
#' \describe{
#'   \item{\code{st_as_binary(x, hex = FALSE)}:}{
#'     Converts to WKB (\code{ST_AsWKB}) or hex-encoded WKB
#'     (\code{ST_AsHEXWKB}).
#'   }
#'   \item{\code{st_as_text(x, geojson = FALSE)}:}{
#'     Converts to WKT (\code{ST_AsText}) or GeoJSON
#'     (\code{ST_AsGeoJSON}).
#'   }
#' }
#'
#' @section Geometry Accessors:
#' Scalar properties of each geometry.
#' \describe{
#'   \item{\code{st_dimension(x)}:}{
#'     Topological dimension: 0 (point), 1 (line), or 2 (polygon).
#'   }
#'   \item{\code{st_end_point(x)}:}{
#'     End point of a linestring.
#'   }
#'   \item{\code{st_geometry_type(x)}:}{
#'     Geometry type name as character (e.g. \code{"POINT"},
#'     \code{"POLYGON"}).
#'   }
#'   \item{\code{st_is_closed(x)}:}{
#'     Logical: is the linestring closed (first point = last point)?
#'   }
#'   \item{\code{st_is_empty(x)}:}{
#'     Logical: is the geometry empty?
#'   }
#'   \item{\code{st_is_ring(x)}:}{
#'     Logical: is the linestring both closed and simple?
#'   }
#'   \item{\code{st_is_simple(x)}:}{
#'     Logical: is the geometry simple (e.g. not self-intersecting)?
#'   }
#'   \item{\code{st_is_valid(x)}:}{
#'     Logical: is the geometry valid?
#'   }
#'   \item{\code{st_num_geometries(x)}:}{
#'     Number of geometries in a geometry collection.
#'   }
#'   \item{\code{st_num_interior_rings(x)}:}{
#'     Number of interior rings in a polygon.
#'   }
#'   \item{\code{st_num_points(x)}:}{
#'     Number of points within a geometry.
#'   }
#'   \item{\code{st_start_point(x)}:}{
#'     Start point of a linestring.
#'   }
#' }
#'
#' @section Measurement:
#' \describe{
#'   \item{\code{st_area(x)}:}{
#'     Area of each geometry.
#'   }
#'   \item{\code{st_distance(x, y)}:}{
#'     Euclidean distance from each geometry in \code{x} to \code{y}.
#'     Argument \code{y} accepts WKT character, \code{sfg}, \code{sfc}
#'     (length 1), or \code{call}.
#'   }
#'   \item{\code{st_length(x)}:}{
#'     Length of linestring or multilinestring; zero for points and polygons.
#'   }
#'   \item{\code{st_perimeter(x)}:}{
#'     Perimeter of polygon or multipolygon; zero for points and lines.
#'   }
#' }
#'
#' @section Unary Geometry Operations:
#' Each returns a DuckDBTable with a transformed geometry per row.
#' \describe{
#'   \item{\code{st_boundary(x)}:}{
#'     Geometry boundary.
#'   }
#'   \item{\code{st_buffer(x, dist)}:}{
#'     Buffer by \code{dist} units.
#'   }
#'   \item{\code{st_build_area(x)}:}{
#'     Build area of a geometry.
#'   }
#'   \item{\code{st_centroid(x)}:}{
#'     Centroid point.
#'   }
#'   \item{\code{st_collection_extract(x, type = c("POLYGON", "POINT", "LINESTRING"))}:}{
#'     Extract geometries of given type from collections.
#'   }
#'   \item{\code{st_concave_hull(x, ratio, allow_holes = FALSE)}:}{
#'     Concave hull; \code{ratio} in [0,1] (1 = convex).
#'   }
#'   \item{\code{st_convex_hull(x)}:}{
#'     Convex hull polygon.
#'   }
#'   \item{\code{st_envelope(x)}:}{
#'     Axis-aligned bounding-box polygon.
#'   }
#'   \item{\code{st_exterior_ring(x)}:}{
#'     Exterior ring of a polygon.
#'   }
#'   \item{\code{st_flip_coordinates(x)}:}{
#'     Flip the coordinates of a geometry.
#'   }
#'   \item{\code{st_inscribed_circle(x, dTolerance, ..., nQuadSegs = 30)}:}{
#'     Maximum inscribed circle of polygon; \code{dTolerance} required.
#'   }
#'   \item{\code{st_line_interpolate(line, dist, normalized = FALSE)}:}{
#'     Point at distance \code{dist} along \code{line}; when
#'     \code{normalized = FALSE}, \code{dist} is in line units; when
#'     \code{TRUE}, \code{dist} is fraction in [0,1].
#'   }
#'   \item{\code{st_line_merge(x, directed = FALSE)}:}{
#'     Merge connected line segments.
#'   }
#'   \item{\code{st_line_project(line, point, normalized = FALSE)}:}{
#'     Distance or fraction along \code{line} to nearest point to
#'     \code{point}; \code{normalized} controls units vs fraction.
#'   }
#'   \item{\code{st_line_substring(line, start, end)}:}{
#'     Substring of \code{line} between \code{start} and \code{end} fractions.
#'   }
#'   \item{\code{st_make_valid(x)}:}{
#'     Repair invalid geometry.
#'   }
#'   \item{\code{st_minimum_rotated_rectangle(x)}:}{
#'     Minimum-area rotated bounding rectangle.
#'   }
#'   \item{\code{st_node(x)}:}{
#'     Add nodes at intersection points (noding) for line geometry.
#'   }
#'   \item{\code{st_normalize(x)}:}{
#'     Normalise vertex order.
#'   }
#'   \item{\code{st_point_on_surface(x)}:}{
#'     A point guaranteed to lie on the surface.
#'   }
#'   \item{\code{st_reduce_precision(x, precision)}:}{
#'     Reduce precision of a geometry.
#'   }
#'   \item{\code{st_remove_repeated_points(x)}:}{
#'     Remove repeated points from a geometry.
#'   }
#'   \item{\code{st_reverse(x)}:}{
#'     Reverse vertex order.
#'   }
#'   \item{\code{st_simplify(x, preserveTopology = FALSE, dTolerance = 0.0)}:}{
#'     Simplify geometry.  Uses \code{ST_SimplifyPreserveTopology} when
#'     \code{preserveTopology = TRUE}.
#'   }
#'   \item{\code{st_voronoi(x)}:}{
#'     Voronoi diagram of points (DuckDB: no envelope/tolerance).
#'   }
#' }
#'
#' @section Binary Spatial Predicates:
#' Each takes a second geometry argument \code{y} and returns a BOOLEAN
#' DuckDBTable.  Argument \code{y} accepts a WKT character string, an
#' \code{sfc}/\code{sfg} object from \pkg{sf}, or a \code{call} (raw SQL
#' expression).  Results are usable for row filtering via
#' \code{extractROWS} or \code{subset}.
#' \describe{
#'   \item{\code{st_contains(x, y)}:}{
#'     Does \code{x} contain \code{y}?
#'   }
#'   \item{\code{st_contains_properly(x, y)}:}{
#'     Does \code{x} properly contain \code{y} (boundary excluded)?
#'   }
#'   \item{\code{st_covered_by(x, y)}:}{
#'     Is \code{x} covered by \code{y}?
#'   }
#'   \item{\code{st_covers(x, y)}:}{
#'     Does \code{x} cover \code{y}?
#'   }
#'   \item{\code{st_crosses(x, y)}:}{
#'     Does \code{x} cross \code{y}?
#'   }
#'   \item{\code{st_disjoint(x, y)}:}{
#'     Are \code{x} and \code{y} disjoint?
#'   }
#'   \item{\code{st_equals(x, y)}:}{
#'     Are \code{x} and \code{y} geometrically equal?
#'   }
#'   \item{\code{st_intersects(x, y)}:}{
#'     Do \code{x} and \code{y} intersect?
#'   }
#'   \item{\code{st_is_within_distance(x, y, dist)}:}{
#'     Is \code{x} within \code{dist} of \code{y}?
#'   }
#'   \item{\code{st_overlaps(x, y)}:}{
#'     Does \code{x} overlap \code{y}?
#'   }
#'   \item{\code{st_touches(x, y)}:}{
#'     Does \code{x} touch \code{y}?
#'   }
#'   \item{\code{st_within(x, y)}:}{
#'     Is \code{x} within \code{y}?
#'   }
#'   \item{\code{st_within_properly(x, y)}:}{
#'     Is \code{x} properly within \code{y} (boundary excluded)?
#'   }
#' }
#'
#' @section Binary Set Operations:
#' Each takes a second geometry argument \code{y} (same accepted types as
#' predicates) and returns a GEOMETRY DuckDBTable.
#' \describe{
#'   \item{\code{st_difference(x, y)}:}{
#'     Portion of \code{x} that does not intersect \code{y}.
#'   }
#'   \item{\code{st_intersection(x, y)}:}{
#'     Portion of \code{x} that intersects \code{y}.
#'   }
#'   \item{\code{st_nearest_points(x, y)}:}{
#'     Shortest line between \code{x} and \code{y} (DuckDB \code{ST_ShortestLine}).
#'   }
#'   \item{\code{st_union(x, y)}:}{
#'     Union of \code{x} and \code{y}.  Binary form only at the
#'     DuckDBTable level; aggregate union is available on DuckDBColumn.
#'   }
#' }
#'
#' @author Patrick Aboyoun
#'
#' @seealso
#' \itemize{
#'   \item \code{\link{DuckDBTable-class}} for the main class
#'   \item \code{\link[S4Vectors]{RectangularData}} for the base class
#' }
#'
#' @aliases
#' st_as_sfc.DuckDBTable
#'
#' st_as_binary.DuckDBTable
#' st_as_text.DuckDBTable
#'
#' st_dimension
#' st_dimension.default
#' st_dimension.DuckDBTable
#' st_end_point
#' st_end_point.default
#' st_end_point.DuckDBTable
#' st_geometry_type
#' st_geometry_type.default
#' st_geometry_type.DuckDBTable
#' st_is_closed
#' st_is_closed.default
#' st_is_closed.DuckDBTable
#' st_is_empty
#' st_is_empty.default
#' st_is_empty.DuckDBTable
#' st_is_ring
#' st_is_ring.default
#' st_is_ring.DuckDBTable
#' st_is_simple
#' st_is_simple.default
#' st_is_simple.DuckDBTable
#' st_is_valid.DuckDBTable
#' st_num_geometries
#' st_num_geometries.default
#' st_num_geometries.DuckDBTable
#' st_num_interior_rings
#' st_num_interior_rings.default
#' st_num_interior_rings.DuckDBTable
#' st_num_points
#' st_num_points.default
#' st_num_points.DuckDBTable
#' st_start_point
#' st_start_point.default
#' st_start_point.DuckDBTable
#'
#' st_area.DuckDBTable
#' st_distance
#' st_distance.default
#' st_distance.DuckDBTable
#' st_length
#' st_length.default
#' st_length.DuckDBTable
#' st_perimeter
#' st_perimeter.default
#' st_perimeter.DuckDBTable
#'
#' st_boundary.DuckDBTable
#' st_buffer.DuckDBTable
#' st_build_area
#' st_build_area.default
#' st_build_area.DuckDBTable
#' st_centroid.DuckDBTable
#' st_collection_extract.DuckDBTable
#' st_concave_hull.DuckDBTable
#' st_convex_hull.DuckDBTable
#' st_envelope
#' st_envelope.DuckDBTable
#' st_exterior_ring.DuckDBTable
#' st_flip_coordinates
#' st_flip_coordinates.default
#' st_flip_coordinates.DuckDBTable
#' st_inscribed_circle
#' st_inscribed_circle.default
#' st_inscribed_circle.DuckDBTable
#' st_line_interpolate
#' st_line_interpolate.default
#' st_line_interpolate.DuckDBTable
#' st_line_merge.DuckDBTable
#' st_line_project
#' st_line_project.default
#' st_line_project.DuckDBTable
#' st_line_substring
#' st_line_substring.default
#' st_line_substring.DuckDBTable
#' st_make_valid.DuckDBTable
#' st_minimum_rotated_rectangle.DuckDBTable
#' st_node.DuckDBTable
#' st_normalize.DuckDBTable
#' st_point_on_surface.DuckDBTable
#' st_reduce_precision
#' st_reduce_precision.default
#' st_reduce_precision.DuckDBTable
#' st_remove_repeated_points
#' st_remove_repeated_points.default
#' st_remove_repeated_points.DuckDBTable
#' st_reverse.DuckDBTable
#' st_simplify.DuckDBTable
#' st_voronoi.DuckDBTable
#'
#' st_contains
#' st_contains.default
#' st_contains.DuckDBTable
#' st_contains_properly
#' st_contains_properly.default
#' st_contains_properly.DuckDBTable
#' st_covered_by
#' st_covered_by.default
#' st_covered_by.DuckDBTable
#' st_covers
#' st_covers.default
#' st_covers.DuckDBTable
#' st_crosses
#' st_crosses.default
#' st_crosses.DuckDBTable
#' st_disjoint
#' st_disjoint.default
#' st_disjoint.DuckDBTable
#' st_equals
#' st_equals.default
#' st_equals.DuckDBTable
#' st_intersects.DuckDBTable
#' st_is_within_distance
#' st_is_within_distance.default
#' st_is_within_distance.DuckDBTable
#' st_overlaps
#' st_overlaps.default
#' st_overlaps.DuckDBTable
#' st_touches
#' st_touches.default
#' st_touches.DuckDBTable
#' st_within
#' st_within.default
#' st_within.DuckDBTable
#' st_within_properly
#' st_within_properly.default
#' st_within_properly.DuckDBTable
#'
#' st_difference.DuckDBTable
#' st_intersection.DuckDBTable
#' st_nearest_points.DuckDBTable
#' st_union.DuckDBTable
#'
#' st_collect
#' st_collect.default
#'
#' @include DuckDBTable-class.R
#' @include sql_call.R
#' @include sql_fun.R
#'
#' @keywords utilities methods
#'
#' @name DuckDBTable-spatial
NULL

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Internal geometry-to-SQL helpers
###

#' @importFrom sf st_as_text
#' @importFrom dplyr sql
.geom_to_sql <- function(y) {
    if (is.call(y))
        return(y)
    if (is.character(y))
        return(sql(sprintf("ST_GeomFromText('%s')", y)))
    if (inherits(y, "sfg"))
        return(sql(sprintf("ST_GeomFromText('%s')", sf::st_as_text(y))))
    if (inherits(y, "sfc")) {
        if (length(y) != 1L)
            stop("'y' must be a single geometry (sfc of length 1)")
        return(sql(sprintf("ST_GeomFromText('%s')", sf::st_as_text(y[[1L]]))))
    }
    stop("unsupported geometry type: ", class(y)[1L])
}

.st_point_sql <- function(x_expr, y_expr) {
    call("ST_Point", x_expr, y_expr)
}

.st_make_envelope_sql <- function(xmin, ymin, xmax, ymax) {
    sql(sprintf("ST_MakeEnvelope(%s, %s, %s, %s)",
                as.numeric(xmin), as.numeric(ymin),
                as.numeric(xmax), as.numeric(ymax)))
}

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Creation methods
###

#' @exportS3Method sf::st_as_sfc
#' @importFrom sf st_as_sfc
st_as_sfc.DuckDBTable <-
function(x, ..., crs = NA_integer_, GeoJSON = FALSE, WKB = FALSE) {
    fun <- if (isTRUE(WKB)) "ST_GeomFromWKB" else if (isTRUE(GeoJSON))
        "ST_GeomFromGeoJSON" else "ST_GeomFromText"
    sql_call(x, fun)
}

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Coercion methods
###

#' @exportS3Method sf::st_as_binary
#' @importFrom sf st_as_binary
st_as_binary.DuckDBTable <- function(x, ..., hex = FALSE) {
    fun <- if (isTRUE(hex)) "ST_AsHEXWKB" else "ST_AsWKB"
    sql_call(x, fun)
}

#' @exportS3Method sf::st_as_text
#' @importFrom sf st_as_text
st_as_text.DuckDBTable <- function(x, ..., geojson = FALSE) {
    fun <- if (isTRUE(geojson)) "ST_AsGeoJSON" else "ST_AsText"
    sql_call(x, fun)
}

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Accessor methods
###

#' @export
st_dimension <- function(x, ...) UseMethod("st_dimension")

#' @export
st_dimension.default <- function(x, ...) sf::st_dimension(x, ...)

#' @export
st_dimension.DuckDBTable <- function(x, ...) {
    sql_call(x, "ST_Dimension")
}

#' @export
st_end_point <- function(x, ...) UseMethod("st_end_point")

#' @export
st_end_point.default <- function(x, ...) {
    stop("st_end_point is not implemented for this class")
}

#' @export
st_end_point.DuckDBTable <- function(x, ...) {
    sql_call(x, "ST_EndPoint")
}

#' @export
st_geometry_type <- function(x, ...) UseMethod("st_geometry_type")

#' @export
st_geometry_type.default <- function(x, ...) sf::st_geometry_type(x, ...)

#' @export
st_geometry_type.DuckDBTable <- function(x, ...) {
    sql_call(x, "ST_GeometryType")
}

#' @export
st_is_closed <- function(x, ...) UseMethod("st_is_closed")

#' @export
st_is_closed.default <- function(x, ...) {
    stop("st_is_closed is not implemented for this class")
}

#' @export
st_is_closed.DuckDBTable <- function(x, ...) {
    sql_call(x, "ST_IsClosed")
}

#' @export
st_is_empty <- function(x, ...) UseMethod("st_is_empty")

#' @export
st_is_empty.default <- function(x, ...) sf::st_is_empty(x, ...)

#' @export
st_is_empty.DuckDBTable <- function(x, ...) {
    sql_call(x, "ST_IsEmpty")
}

#' @export
st_is_ring <- function(x, ...) UseMethod("st_is_ring")

#' @export
st_is_ring.default <- function(x, ...) {
    stop("st_is_ring is not implemented for this class")
}

#' @export
st_is_ring.DuckDBTable <- function(x, ...) {
    sql_call(x, "ST_IsRing")
}

#' @export
st_is_simple <- function(x, ...) UseMethod("st_is_simple")

#' @export
st_is_simple.default <- function(x, ...) sf::st_is_simple(x, ...)

#' @export
st_is_simple.DuckDBTable <- function(x, ...) {
    sql_call(x, "ST_IsSimple")
}

#' @exportS3Method sf::st_is_valid
#' @importFrom sf st_is_valid
st_is_valid.DuckDBTable <- function(x, ...) {
    sql_call(x, "ST_IsValid")
}

#' @export
st_num_geometries <- function(x, ...) UseMethod("st_num_geometries")

#' @export
st_num_geometries.default <- function(x, ...) {
    stop("st_num_geometries is not implemented for this class")
}
#' @export
st_num_geometries.DuckDBTable <- function(x, ...) {
    sql_call(x, "ST_NumGeometries")
}

#' @export
st_num_interior_rings <- function(x, ...) UseMethod("st_num_interior_rings")

#' @export
st_num_interior_rings.default <- function(x, ...) {
    stop("st_num_interior_rings is not implemented for this class")
}
#' @export
st_num_interior_rings.DuckDBTable <- function(x, ...) {
    sql_call(x, "ST_NumInteriorRings")
}

#' @export
st_num_points <- function(x, ...) UseMethod("st_num_points")

#' @export
st_num_points.default <- function(x, ...) {
    stop("st_num_points is not implemented for this class")
}

#' @export
st_num_points.DuckDBTable <- function(x, ...) {
    sql_call(x, "ST_NumPoints")
}

#' @export
st_start_point <- function(x, ...) UseMethod("st_start_point")

#' @export
st_start_point.default <- function(x, ...) {
    stop("st_start_point is not implemented for this class")
}

#' @export
st_start_point.DuckDBTable <- function(x, ...) {
    sql_call(x, "ST_StartPoint")
}

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Measurement methods
###

#' @exportS3Method sf::st_area
#' @importFrom sf st_area
st_area.DuckDBTable <- function(x, ...) {
    sql_call(x, "ST_Area")
}

#' @export
st_distance <- function(x, y, ...) UseMethod("st_distance")

#' @export
st_distance.default <- function(x, y, ...) sf::st_distance(x, y, ...)

#' @export
st_distance.DuckDBTable <- function(x, y, ...) {
    sql_call(x, "ST_Distance", .geom_to_sql(y))
}

#' @export
st_length <- function(x, ...) UseMethod("st_length")

#' @export
st_length.default <- function(x, ...) sf::st_length(x, ...)

#' @export
st_length.DuckDBTable <- function(x, ...) {
    sql_call(x, "ST_Length")
}

#' @export
st_perimeter <- function(x, ...) UseMethod("st_perimeter")

#' @export
st_perimeter.default <- function(x, ...) sf::st_perimeter(x, ...)

#' @export
st_perimeter.DuckDBTable <- function(x, ...) {
    sql_call(x, "ST_Perimeter")
}

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Unary operations
###

#' @exportS3Method sf::st_boundary
#' @importFrom sf st_boundary
st_boundary.DuckDBTable <- function(x) {
    sql_call(x, "ST_Boundary")
}

#' @exportS3Method sf::st_buffer
#' @importFrom sf st_buffer
st_buffer.DuckDBTable <- function(x, dist, ...) {
    sql_call(x, "ST_Buffer", as.numeric(dist))
}

#' @export
st_build_area <- function(x, ...) UseMethod("st_build_area")

#' @export
st_build_area.default <- function(x, ...) {
    stop("st_build_area is not implemented for this class")
}

#' @export
st_build_area.DuckDBTable <- function(x, ...) {
    sql_call(x, "ST_BuildArea")
}

#' @exportS3Method sf::st_centroid
#' @importFrom sf st_centroid
st_centroid.DuckDBTable <- function(x, ...) {
    sql_call(x, "ST_Centroid")
}

.collection_extract_type_to_int <- function(type) {
    type <- match.arg(type, c("POINT", "LINESTRING", "POLYGON"))
    switch(type, POINT = 1L, LINESTRING = 2L, POLYGON = 3L)
}

#' @exportS3Method sf::st_collection_extract
#' @importFrom sf st_collection_extract
st_collection_extract.DuckDBTable <-
function(x, type = c("POLYGON", "POINT", "LINESTRING"), warn = FALSE, ...) {
    type_int <- .collection_extract_type_to_int(type)
    sql_call(x, "ST_CollectionExtract", type_int)
}

#' @exportS3Method sf::st_concave_hull
#' @importFrom sf st_concave_hull
st_concave_hull.DuckDBTable <-
function(x, ratio, ..., allow_holes = FALSE) {
    sql_call(x, "ST_ConcaveHull", as.numeric(ratio), allow_holes)
}

#' @exportS3Method sf::st_convex_hull
#' @importFrom sf st_convex_hull
st_convex_hull.DuckDBTable <- function(x) {
    sql_call(x, "ST_ConvexHull")
}

#' @export
st_envelope <- function(x, ...) UseMethod("st_envelope")

#' @export
st_envelope.DuckDBTable <- function(x, ...) {
    sql_call(x, "ST_Envelope")
}

#' @exportS3Method sf::st_exterior_ring
#' @importFrom sf st_exterior_ring
st_exterior_ring.DuckDBTable <- function(x, ...) {
    sql_call(x, "ST_ExteriorRing")
}

#' @export
st_flip_coordinates <- function(x, ...) UseMethod("st_flip_coordinates")

#' @export
st_flip_coordinates.default <- function(x, ...) {
    stop("st_flip_coordinates is not implemented for this class")
}

#' @export
st_flip_coordinates.DuckDBTable <- function(x, ...) {
    sql_call(x, "ST_FlipCoordinates")
}

#' @export
#' @importFrom S4Vectors endoapply
st_inscribed_circle <- function(x, ...) UseMethod("st_inscribed_circle")

#' @export
#' @importFrom sf st_inscribed_circle
st_inscribed_circle.default <- function(x, ...) sf::st_inscribed_circle(x, ...)

#' @export
st_inscribed_circle.DuckDBTable <-
function(x, dTolerance, ..., nQuadSegs = 30) {
    stopifnot(!missing(dTolerance), is.numeric(dTolerance), length(dTolerance) == 1L)
    dtol <- as.numeric(dTolerance)
    FUN <- function(j) {
        mic <- call("ST_MaximumInscribedCircle", j, dtol)
        center <- call("struct_extract", mic, "center")
        radius <- call("struct_extract", mic, "radius")
        call("ST_Buffer", center, radius)
    }
    datacols <- endoapply(x@datacols, FUN)
    replaceSlots(x, datacols = datacols, check = FALSE)
}

#' @export
#' @importFrom S4Vectors endoapply
st_line_interpolate <- function(line, dist, ...) UseMethod("st_line_interpolate")

#' @export
#' @importFrom sf st_line_interpolate
st_line_interpolate.default <- function(line, dist, ...) {
    sf::st_line_interpolate(line, dist, ...)
}

#' @export
st_line_interpolate.DuckDBTable <-
function(line, dist, ..., normalized = FALSE) {
    stopifnot(is.numeric(dist), length(dist) == 1L)
    d <- as.numeric(dist)
    FUN <- function(j) {
        frac <- if (normalized) d
                else call("/", d, call("ST_Length", j))
        call("ST_LineInterpolatePoint", j, frac)
    }
    datacols <- endoapply(line@datacols, FUN)
    replaceSlots(line, datacols = datacols, check = FALSE)
}

#' @exportS3Method sf::st_line_merge
#' @importFrom sf st_line_merge
st_line_merge.DuckDBTable <- function(x, ..., directed = FALSE) {
    sql_call(x, "ST_LineMerge", directed)
}

#' @export
st_line_project <- function(line, point, ...) UseMethod("st_line_project")

#' @export
#' @importFrom sf st_line_project
st_line_project.default <- function(line, point, ...) {
    sf::st_line_project(line, point, ...)
}

#' @export
st_line_project.DuckDBTable <-
function(line, point, ..., normalized = FALSE) {
    pt_sql <- .geom_to_sql(point)
    FUN <- function(j) {
        frac <- call("ST_LineLocatePoint", j, pt_sql)
        if (normalized) frac else call("*", frac, call("ST_Length", j))
    }
    datacols <- endoapply(line@datacols, FUN)
    replaceSlots(line, datacols = datacols, check = FALSE)
}

#' @export
st_line_substring <- function(line, start, end, ...) UseMethod("st_line_substring")

#' @export
st_line_substring.default <- function(line, start, end, ...) {
    stop("st_line_substring is not implemented for this class")
}

#' @export
st_line_substring.DuckDBTable <- function(line, start, end, ...) {
    sql_call(line, "ST_LineSubstring", as.numeric(start), as.numeric(end))
}

#' @exportS3Method sf::st_make_valid
#' @importFrom sf st_make_valid
st_make_valid.DuckDBTable <- function(x, ...) {
    sql_call(x, "ST_MakeValid")
}

#' @exportS3Method sf::st_minimum_rotated_rectangle
#' @importFrom sf st_minimum_rotated_rectangle
st_minimum_rotated_rectangle.DuckDBTable <- function(x, ...) {
    sql_call(x, "ST_MinimumRotatedRectangle")
}

#' @exportS3Method sf::st_node
#' @importFrom sf st_node
st_node.DuckDBTable <- function(x, ...) {
    sql_call(x, "ST_Node")
}

#' @exportS3Method sf::st_normalize
#' @importFrom sf st_normalize
st_normalize.DuckDBTable <- function(x, ...) {
    sql_call(x, "ST_Normalize")
}

#' @exportS3Method sf::st_point_on_surface
#' @importFrom sf st_point_on_surface
st_point_on_surface.DuckDBTable <- function(x) {
    sql_call(x, "ST_PointOnSurface")
}

#' @export
st_reduce_precision <- function(x, precision, ...) UseMethod("st_reduce_precision")

#' @export
st_reduce_precision.default <- function(x, precision, ...) {
    stop("st_reduce_precision is not implemented for this class")
}

#' @export
st_reduce_precision.DuckDBTable <- function(x, precision, ...) {
    sql_call(x, "ST_ReducePrecision", as.numeric(precision))
}

#' @export
st_remove_repeated_points <- function(x, ...) UseMethod("st_remove_repeated_points")

#' @export
st_remove_repeated_points.default <- function(x, ...) {
    stop("st_remove_repeated_points is not implemented for this class")
}

#' @export
st_remove_repeated_points.DuckDBTable <- function(x, ...) {
    sql_call(x, "ST_RemoveRepeatedPoints")
}

#' @exportS3Method sf::st_reverse
#' @importFrom sf st_reverse
st_reverse.DuckDBTable <- function(x) {
    sql_call(x, "ST_Reverse")
}

#' @exportS3Method sf::st_simplify
#' @importFrom sf st_simplify
st_simplify.DuckDBTable <-
function(x, preserveTopology = FALSE, dTolerance = 0.0, ...) {
    fun <- if (isTRUE(preserveTopology)) "ST_SimplifyPreserveTopology"
           else "ST_Simplify"
    sql_call(x, fun, as.numeric(dTolerance))
}

#' @exportS3Method sf::st_voronoi
#' @importFrom sf st_voronoi
st_voronoi.DuckDBTable <- function(x, ...) {
    sql_call(x, "ST_VoronoiDiagram")
}

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Binary spatial predicates
###

#' @export
st_contains <- function(x, y, ...) UseMethod("st_contains")

#' @export
st_contains.default <- function(x, y, ...) sf::st_contains(x, y, ...)

#' @export
st_contains.DuckDBTable <- function(x, y, ...) {
    sql_call(x, "ST_Contains", .geom_to_sql(y))
}

#' @export
st_contains_properly <- function(x, y, ...) UseMethod("st_contains_properly")

#' @export
st_contains_properly.default <- function(x, y, ...) {
    sf::st_contains_properly(x, y, ...)
}

#' @export
st_contains_properly.DuckDBTable <- function(x, y, ...) {
    sql_call(x, "ST_ContainsProperly", .geom_to_sql(y))
}

#' @export
st_covered_by <- function(x, y, ...) UseMethod("st_covered_by")

#' @export
st_covered_by.default <- function(x, y, ...) sf::st_covered_by(x, y, ...)

#' @export
st_covered_by.DuckDBTable <- function(x, y, ...) {
    sql_call(x, "ST_CoveredBy", .geom_to_sql(y))
}

#' @export
st_covers <- function(x, y, ...) UseMethod("st_covers")

#' @export
st_covers.default <- function(x, y, ...) sf::st_covers(x, y, ...)

#' @export
st_covers.DuckDBTable <- function(x, y, ...) {
    sql_call(x, "ST_Covers", .geom_to_sql(y))
}

#' @export
st_crosses <- function(x, y, ...) UseMethod("st_crosses")

#' @export
st_crosses.default <- function(x, y, ...) sf::st_crosses(x, y, ...)

#' @export
st_crosses.DuckDBTable <- function(x, y, ...) {
    sql_call(x, "ST_Crosses", .geom_to_sql(y))
}

#' @export
st_disjoint <- function(x, y, ...) UseMethod("st_disjoint")

#' @export
st_disjoint.default <- function(x, y, ...) sf::st_disjoint(x, y, ...)

#' @export
st_disjoint.DuckDBTable <- function(x, y, ...) {
    sql_call(x, "ST_Disjoint", .geom_to_sql(y))
}

#' @export
st_equals <- function(x, y, ...) UseMethod("st_equals")

#' @export
st_equals.default <- function(x, y, ...) sf::st_equals(x, y, ...)

#' @export
st_equals.DuckDBTable <- function(x, y, ...) {
    sql_call(x, "ST_Equals", .geom_to_sql(y))
}

#' @exportS3Method sf::st_intersects
#' @importFrom sf st_intersects
st_intersects.DuckDBTable <- function(x, y, ...) {
    sql_call(x, "ST_Intersects", .geom_to_sql(y))
}

#' @export
st_is_within_distance <- function(x, y, ...) UseMethod("st_is_within_distance")

#' @export
st_is_within_distance.default <- function(x, y, ...) {
    sf::st_is_within_distance(x, y, ...)
}

#' @export
st_is_within_distance.DuckDBTable <- function(x, y, dist, ...) {
    sql_call(x, "ST_DWithin", .geom_to_sql(y), as.numeric(dist))
}

#' @export
st_overlaps <- function(x, y, ...) UseMethod("st_overlaps")

#' @export
st_overlaps.default <- function(x, y, ...) sf::st_overlaps(x, y, ...)

#' @export
st_overlaps.DuckDBTable <- function(x, y, ...) {
    sql_call(x, "ST_Overlaps", .geom_to_sql(y))
}

#' @export
st_touches <- function(x, y, ...) UseMethod("st_touches")

#' @export
st_touches.default <- function(x, y, ...) sf::st_touches(x, y, ...)

#' @export
st_touches.DuckDBTable <- function(x, y, ...) {
    sql_call(x, "ST_Touches", .geom_to_sql(y))
}

#' @export
st_within <- function(x, y, ...) UseMethod("st_within")

#' @export
st_within.default <- function(x, y, ...) sf::st_within(x, y, ...)

#' @export
st_within.DuckDBTable <- function(x, y, ...) {
    sql_call(x, "ST_Within", .geom_to_sql(y))
}

#' @export
st_within_properly <- function(x, y, ...) UseMethod("st_within_properly")

#' @export
st_within_properly.default <- function(x, y, ...) {
    t(sf::st_contains_properly(y, x, ...))
}

#' @export
st_within_properly.DuckDBTable <- function(x, y, ...) {
    sql_call(x, "ST_WithinProperly", .geom_to_sql(y))
}

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Binary spatial set operations
###

#' @exportS3Method sf::st_difference
#' @importFrom sf st_difference
st_difference.DuckDBTable <- function(x, y, ...) {
    sql_call(x, "ST_Difference", .geom_to_sql(y))
}

#' @exportS3Method sf::st_intersection
#' @importFrom sf st_intersection
st_intersection.DuckDBTable <- function(x, y, ...) {
    sql_call(x, "ST_Intersection", .geom_to_sql(y))
}

#' @exportS3Method sf::st_nearest_points
#' @importFrom sf st_nearest_points
st_nearest_points.DuckDBTable <- function(x, y, ...) {
    sql_call(x, "ST_ShortestLine", .geom_to_sql(y))
}

#' @exportS3Method sf::st_union
#' @importFrom sf st_union
st_union.DuckDBTable <- function(x, y, ...) {
    if (missing(y))
        stop("'y' is required for st_union on DuckDBTable; ",
             "use st_union on DuckDBColumn for aggregate union")
    sql_call(x, "ST_Union", .geom_to_sql(y))
}

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Aggregate spatial operations (generic and default only)
###

#' @export
st_collect <- function(x, ...) UseMethod("st_collect")

#' @export
st_collect.default <- function(x, ...) sf::st_combine(x, ...)
