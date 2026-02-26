#' Spatial operations on DuckDBColumn objects
#'
#' @description
#' Spatial operations on \linkS4class{DuckDBColumn} objects.
#'
#' @section Geometry Creation:
#' In the code snippets below, \code{x} is a DuckDBColumn object.
#' \describe{
#'   \item{\code{st_as_sfc(x, ..., crs = NA_integer_, GeoJSON = FALSE, WKB = FALSE)}:}{
#'     Parses WKT, GeoJSON, or WKB into GEOMETRY.
#'   }
#' }
#'
#' @section Geometry Coercion:
#' \describe{
#'   \item{\code{st_as_binary(x, hex = FALSE)}:}{
#'     Serialises to WKB or hex-encoded WKB.
#'   }
#'   \item{\code{st_as_text(x, geojson = FALSE)}:}{
#'     Serialises to WKT or GeoJSON.
#'   }
#' }
#'
#' @section Geometry Accessors:
#' Scalar properties of each geometry.
#' \describe{
#'   \item{\code{st_coordinates(x)}:}{
#'     Returns a DuckDBDataFrame with X, Y (and Z, M when present)
#'     coordinate columns.
#'   }
#'   \item{\code{st_dimension(x)}:}{
#'     Topological dimension (0, 1, or 2).
#'   }
#'   \item{\code{st_end_point(x)}:}{
#'     End point of a linestring.
#'   }
#'   \item{\code{st_geometry_type(x)}:}{
#'     Geometry type name as character.
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
#'     Euclidean distance from each geometry to \code{y}.
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
#' Each returns a DuckDBColumn with a transformed geometry per row.
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
#'   \item{\code{st_collection_extract(x, type)}:}{
#'     Extract geometries of given type from collections.
#'   }
#'   \item{\code{st_concave_hull(x, ratio, allow_holes = FALSE)}:}{
#'     Concave hull.
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
#'     Maximum inscribed circle of polygon.
#'   }
#'   \item{\code{st_line_interpolate(line, dist, normalized = FALSE)}:}{
#'     Point at distance \code{dist} along \code{line}.
#'   }
#'   \item{\code{st_line_merge(x, directed = FALSE)}:}{
#'     Merge connected line segments.
#'   }
#'   \item{\code{st_line_project(line, point, normalized = FALSE)}:}{
#'     Distance or fraction along \code{line} to nearest point.
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
#'     Add nodes at intersection points for line geometry.
#'   }
#'   \item{\code{st_normalize(x)}:}{
#'     Normalise vertex order.
#'   }
#'   \item{\code{st_point_on_surface(x)}:}{
#'     A point guaranteed to lie on the surface.
#'   }
#'   \item{\code{st_reverse(x)}:}{
#'     Reverse vertex order.
#'   }
#'   \item{\code{st_reduce_precision(x, precision)}:}{
#'     Reduce precision of a geometry.
#'   }
#'   \item{\code{st_remove_repeated_points(x)}:}{
#'     Remove repeated points from a geometry.
#'   }
#'   \item{\code{st_simplify(x, preserveTopology = FALSE, dTolerance = 0.0)}:}{
#'     Simplify geometry.
#'   }
#'   \item{\code{st_voronoi(x)}:}{
#'     Voronoi diagram.
#'   }
#' }
#'
#' @section Binary Spatial Predicates:
#' Each takes a second geometry argument \code{y} and returns a BOOLEAN
#' DuckDBColumn.  See \code{\link{DuckDBTable-spatial}} for accepted
#' \code{y} types.
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
#' \describe{
#'   \item{\code{st_difference(x, y)}:}{
#'     Portion of \code{x} that does not intersect \code{y}.
#'   }
#'   \item{\code{st_intersection(x, y)}:}{
#'     Portion of \code{x} that intersects \code{y}.
#'   }
#'   \item{\code{st_nearest_points(x, y)}:}{
#'     Shortest line between \code{x} and \code{y}.
#'   }
#'   \item{\code{st_union(x, y)}:}{
#'     Binary: returns a DuckDBColumn.  Aggregate (no \code{y}):
#'     Apply \code{ST_Union_Agg} and materialise to \code{sfc}.
#'   }
#' }
#'
#' @section Aggregate Operations:
#' These methods materialise and return concrete R objects.
#' \describe{
#'   \item{\code{st_bbox(obj)}:}{
#'     Returns a \code{bbox} named numeric vector
#'     \code{c(xmin, ymin, xmax, ymax)} via \code{MIN}/\code{MAX}
#'     of \code{ST_XMin}/\code{ST_YMin}/\code{ST_XMax}/\code{ST_YMax}.
#'   }
#'   \item{\code{st_collect(x)}:}{
#'     Returns an \code{sfc} GEOMETRYCOLLECTION via \code{ST_Collect}.
#'   }
#'   \item{\code{st_union(x)} (no \code{y}):}{
#'     Returns an \code{sfc} via \code{ST_Union_Agg}.
#'   }
#' }
#'
#' @author Patrick Aboyoun
#'
#' @aliases
#' st_as_sfc.DuckDBColumn
#'
#' st_as_binary.DuckDBColumn
#' st_as_text.DuckDBColumn
#'
#' st_coordinates.DuckDBColumn
#' st_dimension.DuckDBColumn
#' st_end_point.DuckDBColumn
#' st_geometry_type.DuckDBColumn
#' st_is_closed.DuckDBColumn
#' st_is_empty.DuckDBColumn
#' st_is_ring.DuckDBColumn
#' st_is_simple.DuckDBColumn
#' st_is_valid.DuckDBColumn
#' st_num_geometries.DuckDBColumn
#' st_num_interior_rings.DuckDBColumn
#' st_num_points.DuckDBColumn
#' st_start_point.DuckDBColumn
#'
#' st_area.DuckDBColumn
#' st_distance.DuckDBColumn
#' st_length.DuckDBColumn
#' st_perimeter.DuckDBColumn
#'
#' st_boundary.DuckDBColumn
#' st_buffer.DuckDBColumn
#' st_build_area.DuckDBColumn
#' st_centroid.DuckDBColumn
#' st_collection_extract.DuckDBColumn
#' st_concave_hull.DuckDBColumn
#' st_convex_hull.DuckDBColumn
#' st_envelope.DuckDBColumn
#' st_exterior_ring.DuckDBColumn
#' st_flip_coordinates.DuckDBColumn
#' st_inscribed_circle.DuckDBColumn
#' st_line_interpolate.DuckDBColumn
#' st_line_merge.DuckDBColumn
#' st_line_project.DuckDBColumn
#' st_line_substring.DuckDBColumn
#' st_make_valid.DuckDBColumn
#' st_minimum_rotated_rectangle.DuckDBColumn
#' st_node.DuckDBColumn
#' st_normalize.DuckDBColumn
#' st_point_on_surface.DuckDBColumn
#' st_reduce_precision.DuckDBColumn
#' st_remove_repeated_points.DuckDBColumn
#' st_reverse.DuckDBColumn
#' st_simplify.DuckDBColumn
#' st_voronoi.DuckDBColumn
#'
#' st_contains.DuckDBColumn
#' st_contains_properly.DuckDBColumn
#' st_covered_by.DuckDBColumn
#' st_covers.DuckDBColumn
#' st_crosses.DuckDBColumn
#' st_disjoint.DuckDBColumn
#' st_equals.DuckDBColumn
#' st_intersects.DuckDBColumn
#' st_is_within_distance.DuckDBColumn
#' st_overlaps.DuckDBColumn
#' st_touches.DuckDBColumn
#' st_within.DuckDBColumn
#' st_within_properly.DuckDBColumn
#'
#' st_difference.DuckDBColumn
#' st_intersection.DuckDBColumn
#' st_nearest_points.DuckDBColumn
#' st_union.DuckDBColumn
#'
#' st_bbox.DuckDBColumn
#' st_collect.DuckDBColumn
#'
#' @seealso
#' \itemize{
#'   \item \code{\link{DuckDBColumn-class}} for the main class
#'   \item \code{\link[S4Vectors]{Vector}} for the base class
#' }
#'
#' @include DuckDBColumn-class.R
#' @include DuckDBTable-spatial.R
#' @include sql_call.R
#' @include sql_fun.R
#'
#' @keywords utilities methods
#'
#' @name DuckDBColumn-spatial
NULL

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Creation methods
###

#' @exportS3Method sf::st_as_sfc
#' @importFrom sf st_as_sfc
st_as_sfc.DuckDBColumn <-
function(x, ..., crs = NA_integer_, GeoJSON = FALSE, WKB = FALSE) {
    replaceSlots(x, table = st_as_sfc(x@table, GeoJSON = GeoJSON, WKB = WKB),
                 check = FALSE)
}

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Coercion methods
###

#' @exportS3Method sf::st_as_binary
#' @importFrom sf st_as_binary
st_as_binary.DuckDBColumn <- function(x, ..., hex = FALSE) {
    replaceSlots(x, table = st_as_binary(x@table, hex = hex), check = FALSE)
}

#' @exportS3Method sf::st_as_text
#' @importFrom sf st_as_text
st_as_text.DuckDBColumn <- function(x, ..., geojson = FALSE) {
    replaceSlots(x, table = st_as_text(x@table, geojson = geojson), check = FALSE)
}

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Accessor methods
###

#' @exportS3Method sf::st_coordinates
#' @importFrom dplyr summarize
#' @importFrom sf st_coordinates
st_coordinates.DuckDBColumn <- function(x, ...) {
    table <- x@table
    datacols <- table@datacols
    point <- datacols[[1L]]

    # Determine if Z and M dimensions are present
    aggr <- list(z = call("MAX", call("ST_HasZ", point)),
                 m = call("MAX", call("ST_HasM", point)))
    has <- as.data.frame(summarize(tblconn(x, select = FALSE), !!!aggr))

    # Construct dimension columns
    datacols <- datacols[-1L]
    datacols[["X"]] <- call("ST_X", point)
    datacols[["Y"]] <- call("ST_Y", point)
    if (has[["z"]]) datacols[["Z"]] <- call("ST_Z", point)
    if (has[["m"]]) datacols[["M"]] <- call("ST_M", point)

    DuckDBDataFrame(table, datacols = datacols)
}

#' @export
st_dimension.DuckDBColumn <- function(x, ...) {
    replaceSlots(x, table = st_dimension(x@table), check = FALSE)
}

#' @export
st_end_point.DuckDBColumn <- function(x, ...) {
    replaceSlots(x, table = st_end_point(x@table), check = FALSE)
}

#' @export
st_geometry_type.DuckDBColumn <- function(x, ...) {
    replaceSlots(x, table = st_geometry_type(x@table), check = FALSE)
}

#' @export
st_is_closed.DuckDBColumn <- function(x, ...) {
    replaceSlots(x, table = st_is_closed(x@table), check = FALSE)
}

#' @export
st_is_empty.DuckDBColumn <- function(x, ...) {
    replaceSlots(x, table = st_is_empty(x@table), check = FALSE)
}

#' @export
st_is_ring.DuckDBColumn <- function(x, ...) {
    replaceSlots(x, table = st_is_ring(x@table), check = FALSE)
}

#' @export
st_is_simple.DuckDBColumn <- function(x, ...) {
    replaceSlots(x, table = st_is_simple(x@table), check = FALSE)
}

#' @exportS3Method sf::st_is_valid
#' @importFrom sf st_is_valid
st_is_valid.DuckDBColumn <- function(x, ...) {
    replaceSlots(x, table = st_is_valid(x@table), check = FALSE)
}

#' @export
st_num_geometries.DuckDBColumn <- function(x, ...) {
    replaceSlots(x, table = st_num_geometries(x@table), check = FALSE)
}

#' @export
st_num_interior_rings.DuckDBColumn <- function(x, ...) {
    replaceSlots(x, table = st_num_interior_rings(x@table), check = FALSE)
}

#' @export
st_num_points.DuckDBColumn <- function(x, ...) {
    replaceSlots(x, table = st_num_points(x@table), check = FALSE)
}

#' @export
st_start_point.DuckDBColumn <- function(x, ...) {
    replaceSlots(x, table = st_start_point(x@table), check = FALSE)
}

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Measurement methods
###

#' @exportS3Method sf::st_area
#' @importFrom sf st_area
st_area.DuckDBColumn <- function(x, ...) {
    replaceSlots(x, table = st_area(x@table), check = FALSE)
}

#' @export
st_distance.DuckDBColumn <- function(x, y, ...) {
    replaceSlots(x, table = st_distance(x@table, y), check = FALSE)
}

#' @export
st_length.DuckDBColumn <- function(x, ...) {
    replaceSlots(x, table = st_length(x@table), check = FALSE)
}

#' @export
st_perimeter.DuckDBColumn <- function(x, ...) {
    replaceSlots(x, table = st_perimeter(x@table), check = FALSE)
}

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Unary operations
###

#' @exportS3Method sf::st_boundary
#' @importFrom sf st_boundary
st_boundary.DuckDBColumn <- function(x) {
    replaceSlots(x, table = st_boundary(x@table), check = FALSE)
}

#' @exportS3Method sf::st_buffer
#' @importFrom sf st_buffer
st_buffer.DuckDBColumn <- function(x, dist, ...) {
    replaceSlots(x, table = st_buffer(x@table, dist), check = FALSE)
}

#' @export
st_build_area.DuckDBColumn <- function(x, ...) {
    replaceSlots(x, table = st_build_area(x@table), check = FALSE)
}

#' @exportS3Method sf::st_centroid
#' @importFrom sf st_centroid
st_centroid.DuckDBColumn <- function(x, ...) {
    replaceSlots(x, table = st_centroid(x@table), check = FALSE)
}

#' @exportS3Method sf::st_collection_extract
#' @importFrom sf st_collection_extract
st_collection_extract.DuckDBColumn <-
function(x, type = c("POLYGON", "POINT", "LINESTRING"), warn = FALSE, ...) {
    replaceSlots(x, table = st_collection_extract(x@table, type, warn),
                 check = FALSE)
}

#' @exportS3Method sf::st_concave_hull
#' @importFrom sf st_concave_hull
st_concave_hull.DuckDBColumn <-
function(x, ratio, ..., allow_holes = FALSE) {
    replaceSlots(x, table = st_concave_hull(x@table, ratio,
                     allow_holes = allow_holes), check = FALSE)
}

#' @exportS3Method sf::st_convex_hull
#' @importFrom sf st_convex_hull
st_convex_hull.DuckDBColumn <- function(x) {
    replaceSlots(x, table = st_convex_hull(x@table), check = FALSE)
}

#' @export
st_envelope.DuckDBColumn <- function(x, ...) {
    replaceSlots(x, table = st_envelope(x@table), check = FALSE)
}

#' @exportS3Method sf::st_exterior_ring
#' @importFrom sf st_exterior_ring
st_exterior_ring.DuckDBColumn <- function(x, ...) {
    replaceSlots(x, table = st_exterior_ring(x@table), check = FALSE)
}

#' @export
st_flip_coordinates.DuckDBColumn <- function(x, ...) {
    replaceSlots(x, table = st_flip_coordinates(x@table), check = FALSE)
}

#' @export
st_inscribed_circle.DuckDBColumn <-
function(x, dTolerance, ..., nQuadSegs = 30) {
    replaceSlots(x, table = st_inscribed_circle(x@table, dTolerance,
                     nQuadSegs = nQuadSegs), check = FALSE)
}

#' @export
st_line_interpolate.DuckDBColumn <-
function(line, dist, ..., normalized = FALSE) {
    replaceSlots(line, table = st_line_interpolate(line@table, dist,
                     normalized = normalized), check = FALSE)
}

#' @exportS3Method sf::st_line_merge
#' @importFrom sf st_line_merge
st_line_merge.DuckDBColumn <- function(x, ..., directed = FALSE) {
    replaceSlots(x, table = st_line_merge(x@table, directed = directed),
                 check = FALSE)
}

#' @export
st_line_project.DuckDBColumn <-
function(line, point, ..., normalized = FALSE) {
    replaceSlots(line, table = st_line_project(line@table, point,
                     normalized = normalized), check = FALSE)
}

#' @export
st_line_substring.DuckDBColumn <- function(line, start, end, ...) {
    replaceSlots(line, table = st_line_substring(line@table, start, end), check = FALSE)
}

#' @exportS3Method sf::st_make_valid
#' @importFrom sf st_make_valid
st_make_valid.DuckDBColumn <- function(x, ...) {
    replaceSlots(x, table = st_make_valid(x@table), check = FALSE)
}

#' @exportS3Method sf::st_minimum_rotated_rectangle
#' @importFrom sf st_minimum_rotated_rectangle
st_minimum_rotated_rectangle.DuckDBColumn <- function(x, ...) {
    replaceSlots(x, table = st_minimum_rotated_rectangle(x@table),
                 check = FALSE)
}

#' @exportS3Method sf::st_node
#' @importFrom sf st_node
st_node.DuckDBColumn <- function(x, ...) {
    replaceSlots(x, table = st_node(x@table), check = FALSE)
}

#' @exportS3Method sf::st_normalize
#' @importFrom sf st_normalize
st_normalize.DuckDBColumn <- function(x, ...) {
    replaceSlots(x, table = st_normalize(x@table), check = FALSE)
}

#' @exportS3Method sf::st_point_on_surface
#' @importFrom sf st_point_on_surface
st_point_on_surface.DuckDBColumn <- function(x) {
    replaceSlots(x, table = st_point_on_surface(x@table), check = FALSE)
}

#' @export
st_reduce_precision.DuckDBColumn <- function(x, precision, ...) {
    replaceSlots(x, table = st_reduce_precision(x@table, precision), check = FALSE)
}

#' @export
st_remove_repeated_points.DuckDBColumn <- function(x, ...) {
    replaceSlots(x, table = st_remove_repeated_points(x@table), check = FALSE)
}

#' @exportS3Method sf::st_reverse
#' @importFrom sf st_reverse
st_reverse.DuckDBColumn <- function(x) {
    replaceSlots(x, table = st_reverse(x@table), check = FALSE)
}

#' @exportS3Method sf::st_simplify
#' @importFrom sf st_simplify
st_simplify.DuckDBColumn <-
function(x, preserveTopology = FALSE, dTolerance = 0.0, ...) {
    replaceSlots(x, table = st_simplify(x@table,
                     preserveTopology = preserveTopology,
                     dTolerance = dTolerance), check = FALSE)
}

#' @exportS3Method sf::st_voronoi
#' @importFrom sf st_voronoi
st_voronoi.DuckDBColumn <- function(x, ...) {
    replaceSlots(x, table = st_voronoi(x@table), check = FALSE)
}

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Binary spatial predicates
###

#' @export
st_contains.DuckDBColumn <- function(x, y, ...) {
    replaceSlots(x, table = st_contains(x@table, y), check = FALSE)
}

#' @export
st_contains_properly.DuckDBColumn <- function(x, y, ...) {
    replaceSlots(x, table = st_contains_properly(x@table, y), check = FALSE)
}

#' @export
st_covered_by.DuckDBColumn <- function(x, y, ...) {
    replaceSlots(x, table = st_covered_by(x@table, y), check = FALSE)
}

#' @export
st_covers.DuckDBColumn <- function(x, y, ...) {
    replaceSlots(x, table = st_covers(x@table, y), check = FALSE)
}

#' @export
st_crosses.DuckDBColumn <- function(x, y, ...) {
    replaceSlots(x, table = st_crosses(x@table, y), check = FALSE)
}

#' @export
st_disjoint.DuckDBColumn <- function(x, y, ...) {
    replaceSlots(x, table = st_disjoint(x@table, y), check = FALSE)
}

#' @export
st_equals.DuckDBColumn <- function(x, y, ...) {
    replaceSlots(x, table = st_equals(x@table, y), check = FALSE)
}

#' @exportS3Method sf::st_intersects
#' @importFrom sf st_intersects
st_intersects.DuckDBColumn <- function(x, y, ...) {
    replaceSlots(x, table = st_intersects(x@table, y), check = FALSE)
}

#' @export
st_is_within_distance.DuckDBColumn <- function(x, y, dist, ...) {
    replaceSlots(x, table = st_is_within_distance(x@table, y, dist),
                 check = FALSE)
}

#' @export
st_overlaps.DuckDBColumn <- function(x, y, ...) {
    replaceSlots(x, table = st_overlaps(x@table, y), check = FALSE)
}

#' @export
st_touches.DuckDBColumn <- function(x, y, ...) {
    replaceSlots(x, table = st_touches(x@table, y), check = FALSE)
}

#' @export
st_within.DuckDBColumn <- function(x, y, ...) {
    replaceSlots(x, table = st_within(x@table, y), check = FALSE)
}

#' @export
st_within_properly.DuckDBColumn <- function(x, y, ...) {
    replaceSlots(x, table = st_within_properly(x@table, y), check = FALSE)
}

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Binary spatial set operations
###

#' @exportS3Method sf::st_difference
#' @importFrom sf st_difference
st_difference.DuckDBColumn <- function(x, y, ...) {
    replaceSlots(x, table = st_difference(x@table, y), check = FALSE)
}

#' @exportS3Method sf::st_intersection
#' @importFrom sf st_intersection
st_intersection.DuckDBColumn <- function(x, y, ...) {
    replaceSlots(x, table = st_intersection(x@table, y), check = FALSE)
}

#' @exportS3Method sf::st_nearest_points
#' @importFrom sf st_nearest_points
st_nearest_points.DuckDBColumn <- function(x, y, ...) {
    replaceSlots(x, table = st_nearest_points(x@table, y), check = FALSE)
}

#' @exportS3Method sf::st_union
#' @importFrom sf st_union
st_union.DuckDBColumn <- function(x, y, ...) {
    if (missing(y)) {
        table <- x@table
        geom <- table@datacols[[1L]]
        aggr <- list(geom = call("ST_AsText", call("ST_Union_Agg", geom)))
        res <- as.data.frame(dplyr::summarize(
            tblconn(x, select = FALSE), !!!aggr))
        sf::st_as_sfc(res$geom)
    } else {
        replaceSlots(x, table = st_union(x@table, y), check = FALSE)
    }
}

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Aggregate spatial operations
###

#' @exportS3Method sf::st_bbox
#' @importFrom sf st_bbox
#' @importFrom dplyr summarize
st_bbox.DuckDBColumn <- function(obj, ...) {
    table <- obj@table
    geom <- table@datacols[[1L]]
    aggr <- list(
        xmin = call("MIN", call("ST_XMin", geom)),
        ymin = call("MIN", call("ST_YMin", geom)),
        xmax = call("MAX", call("ST_XMax", geom)),
        ymax = call("MAX", call("ST_YMax", geom))
    )
    res <- as.data.frame(dplyr::summarize(
        tblconn(obj, select = FALSE), !!!aggr))
    structure(
        c(xmin = res$xmin, ymin = res$ymin,
          xmax = res$xmax, ymax = res$ymax),
        class = "bbox"
    )
}

#' @export
st_collect.DuckDBColumn <- function(x, ...) {
    table <- x@table
    geom <- table@datacols[[1L]]
    aggr <- list(geom = call("ST_AsText", call("ST_Collect", call("list", geom))))
    res <- as.data.frame(dplyr::summarize(
        tblconn(x, select = FALSE), !!!aggr))
    sf::st_as_sfc(res$geom)
}
