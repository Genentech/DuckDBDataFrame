# Tests the basic functions of a DuckDBColumn.
# library(testthat); library(DuckDBDataFrame); source("setup.R"); source("test-DuckDBColumn.R")

test_that("head works for DuckDBColumn", {
    df <- DuckDBDataFrame(mtcars_parquet, datacols = colnames(mtcars), keycol = list(model = rownames(mtcars)))
    cyl <- df[["cyl"]]

    checkDuckDBColumn(head(cyl, 0), head(setNames(mtcars[["cyl"]], rownames(mtcars)), 0))
    checkDuckDBColumn(head(cyl, 20), head(setNames(mtcars[["cyl"]], rownames(mtcars)), 20))
})

test_that("tail works for DuckDBColumn", {
    df <- DuckDBDataFrame(mtcars_parquet, datacols = colnames(mtcars), keycol = list(model = rownames(mtcars)))
    cyl <- df[["cyl"]]

    checkDuckDBColumn(tail(cyl, 0), tail(setNames(mtcars[["cyl"]], rownames(mtcars)), 0))
    checkDuckDBColumn(tail(cyl, 20), tail(setNames(mtcars[["cyl"]], rownames(mtcars)), 20))
})

test_that("DuckDBColumn can be cast to a different type", {
    df <- DuckDBDataFrame(mtcars_parquet, datacols = colnames(mtcars), keycol = "model")
    cyl <- df[["cyl"]]

    checkDuckDBColumn(cyl, as.vector(cyl))

    type(cyl) <- "integer"
    expected <- as.vector(cyl)
    storage.mode(expected) <- "integer"
    checkDuckDBColumn(cyl, expected)
})

test_that("nonzero functions work for DuckDBColumn", {
    df <- DuckDBDataFrame(mtcars_parquet, datacols = colnames(mtcars), keycol = "model")
    am <- df[["am"]]
    checkDuckDBColumn(is_nonzero(am), is_nonzero(as.vector(am)))
    expect_equal(nzcount(am), nzcount(as.vector(am)))
})

test_that("unique works as expected for a DuckDBColumn", {
    df <- DuckDBDataFrame(mtcars_parquet, datacols = colnames(mtcars), keycol = "model")
    cyl <- df[["cyl"]]
    expected <- unique(as.vector(cyl))
    names(expected) <- NULL
    checkDuckDBColumn(unique(cyl), expected)
})

test_that("Arith methods work as expected for a DuckDBColumn", {
    df <- DuckDBDataFrame(mtcars_parquet, datacols = colnames(mtcars), keycol = "model")
    mpg <- df[["mpg"]]
    disp <- df[["disp"]]

    checkDuckDBColumn(mpg + disp, as.vector(mpg) + as.vector(disp))
    checkDuckDBColumn(+ mpg, + as.vector(mpg))
    checkDuckDBColumn(mpg - 1L, as.vector(mpg) - 1L)
    checkDuckDBColumn(- mpg, - as.vector(mpg))
    checkDuckDBColumn(mpg * 3.14, as.vector(mpg) * 3.14)
    checkDuckDBColumn(1L / mpg, 1L / as.vector(mpg))
    checkDuckDBColumn(3.14 ^ mpg, 3.14 ^ as.vector(mpg))
    checkDuckDBColumn(mpg %% disp, as.vector(mpg) %% as.vector(disp))
    checkDuckDBColumn(mpg %/% 3.14, as.vector(mpg) %/% 3.14)
})

test_that("Compare methods work as expected for a DuckDBColumn", {
    df <- DuckDBDataFrame(mtcars_parquet, datacols = colnames(mtcars), keycol = "model")
    vs <- df[["vs"]]
    am <- df[["am"]]

    checkDuckDBColumn(vs == am, as.vector(vs) == as.vector(am))
    checkDuckDBColumn(vs > 1L, as.vector(vs) > 1L)
    checkDuckDBColumn(vs < 1L, as.vector(vs) < 1L)
    checkDuckDBColumn(1L != vs, 1L != as.vector(vs))
    checkDuckDBColumn(1 <= vs, 1 <= as.vector(vs))
    checkDuckDBColumn(vs >= am, as.vector(vs) >= as.vector(am))
})

test_that("Logic methods work as expected for a DuckDBColumn", {
    df <- DuckDBDataFrame(mtcars_parquet, datacols = colnames(mtcars), keycol = "model")
    mpg <- df[["mpg"]]
    x <- mpg > 15
    y <- mpg < 25

    checkDuckDBColumn(x & y, as.vector(x) & as.vector(y))
    checkDuckDBColumn(x | y, as.vector(x) | as.vector(y))
    checkDuckDBColumn(!x, !as.vector(x))
})

test_that("Math methods work as expected for a DuckDBColumn", {
    df <- DuckDBDataFrame(mtcars_parquet, datacols = colnames(mtcars), keycol = "model")
    mpg <- df[["mpg"]]

    checkDuckDBColumn(abs(mpg), abs(as.vector(mpg)))
    checkDuckDBColumn(sqrt(mpg), sqrt(as.vector(mpg)))
    checkDuckDBColumn(ceiling(mpg), ceiling(as.vector(mpg)))
    checkDuckDBColumn(floor(mpg), floor(as.vector(mpg)))
    checkDuckDBColumn(trunc(mpg), trunc(as.vector(mpg)))

    expect_error(cummax(mpg))
    expect_error(cummin(mpg))
    expect_error(cumprod(mpg))
    expect_error(cumsum(mpg))

    checkDuckDBColumn(log(mpg), log(as.vector(mpg)))
    checkDuckDBColumn(log10(mpg), log10(as.vector(mpg)))
    checkDuckDBColumn(log2(mpg), log2(as.vector(mpg)))
    checkDuckDBColumn(log1p(mpg), log1p(as.vector(mpg)))
})

test_that("%in% works as expected for a DuckDBColumn", {
    df <- DuckDBDataFrame(mtcars_parquet, datacols = colnames(mtcars), keycol = "model")
    carb <- df[["carb"]]

    checkDuckDBColumn(carb %in% c(2, 4, 8), setNames(as.vector(carb) %in% c(2, 4, 8), names(carb)))
})

test_that("Special numeric functions work as expected for a DuckDBColumn", {
    df <- DuckDBDataFrame(special_path, datacols = "x", keycol = list(id = letters[1:4]))
    x <- df[["x"]]

    checkDuckDBColumn(is.finite(x), is.finite(as.vector(x)))
    checkDuckDBColumn(is.infinite(x), is.infinite(as.vector(x)))
    checkDuckDBColumn(is.nan(x), is.nan(as.vector(x)))
})

test_that("Special spatial functions work as expected for a DuckDBColumn", {
    df <- DuckDBDataFrame(spatial_path)
    df <- df[which(!is.na(spatial_wkt)),]

    x <- df[["geometry"]]
    type <- df[["type"]]
    sfc <- st_as_sfc(spatial_wkt[!is.na(spatial_wkt)])

    query_pt_sfc <- st_sfc(st_point(c(30, 10)))
    query_poly_sfc <- st_sfc(st_polygon(list(
        matrix(c(0,0, 100,0, 100,100, 0,100, 0,0), ncol = 2, byrow = TRUE))))
    query_line_sfc <- st_sfc(st_linestring(
        matrix(c(0,0, 50,50), ncol = 2, byrow = TRUE)))
    query_overlap_sfc <- st_sfc(st_polygon(list(
        matrix(c(25,5, 50,50, 5,25, 25,5), ncol = 2, byrow = TRUE))))
    far_pt_sfc <- st_sfc(st_point(c(999, 999)))

    ## Coercion methods
    wkt <- st_as_text(x)
    checkDuckDBColumn(st_as_text(st_as_sfc(wkt)), st_as_text(sfc))
    checkDuckDBColumn(st_as_binary(st_as_sfc(wkt), hex = TRUE), st_as_binary(sfc, hex = TRUE))
    checkDuckDBColumn(st_as_binary(x, hex = TRUE), st_as_binary(sfc, hex = TRUE))
    checkDuckDBColumn(st_as_text(x), st_as_text(sfc))

    # Geometry accessors
    expect_equal(as.matrix(st_coordinates(x[c(17,20)])), st_coordinates(sfc[c(13,15)]),
                 check.attributes = FALSE)
    checkDuckDBColumn(st_dimension(x), rep(c(1,0,2,0,2), c(5,3,4,3,3)))
    checkDuckDBColumn(st_end_point(x), rep(c("POINT (40 40)", NA), c(1,17)))
    checkDuckDBColumn(st_geometry_type(x), as.character(st_geometry_type(sfc)))
    checkDuckDBColumn(st_is_empty(x), st_is_empty(sfc))
    checkDuckDBColumn(st_is_simple(x), st_is_simple(sfc))
    checkDuckDBColumn(st_is_valid(x), st_is_valid(sfc))
    # st_is_closed, st_is_ring have no equivalent
    line_df <- df[df$type %in% c("linestring", "multilinestring"), ]
    if (nrow(line_df) > 0L) {
        closed <- st_is_closed(line_df[["geometry"]])
        expect_s4_class(closed, "DuckDBColumn")
        expect_identical(length(closed), nrow(line_df))
        ## LINESTRING(30 10, 10 30, 40 40) is not closed
        expect_false(as.vector(closed)[1])
        ring <- st_is_ring(line_df[["geometry"]])
        expect_identical(length(ring), nrow(line_df))
    }
    checkDuckDBColumn(st_num_geometries(x), c(1,0,1,2,0,1,4,0,1,2,2,0,1,0,1,1,1,0))
    checkDuckDBColumn(st_num_interior_rings(x), rep(c(NA,0,1,0),c(15,1,1,1)))
    checkDuckDBColumn(st_num_points(x), c(3,0,3,7,0,1,4,0,5,9,14,0,1,0,1,5,9,0))
    checkDuckDBColumn(st_start_point(x), rep(c("POINT (30 10)", NA), c(1,17)))

    # Measurement methods
    checkDuckDBColumn(st_area(x), st_area(sfc))
    checkDuckDBColumn(st_distance(x, sfc[13]), st_distance(sfc, sfc[13]))
    checkDuckDBColumn(st_length(x), st_length(sfc))
    checkDuckDBColumn(st_perimeter(x), st_perimeter(sfc))

    # Unary operations
    checkDuckDBColumn(st_boundary(x), st_boundary(sfc))
    checkDuckDBColumn(st_buffer(x, 1), st_buffer(sfc, 1))
    checkDuckDBColumn(st_build_area(x),
                      rep(c("GEOMETRYCOLLECTION EMPTY", "POLYGON ((30 10, 10 20, 20 40, 40 40, 30 10))",
                            "MULTIPOLYGON (((5 10, 10 20, 40 10, 15 5, 5 10)), ((10 40, 45 40, 30 20, 10 40)))",
                            "MULTIPOLYGON (((45 20, 30 5, 10 10, 10 30, 20 35, 45 20), (20 25, 20 15, 30 20, 20 25)), ((45 30, 20 45, 40 40, 45 30)))",
                            "GEOMETRYCOLLECTION EMPTY",
                            "POLYGON ((30 10, 10 20, 20 40, 40 40, 30 10))",
                            "POLYGON ((35 10, 10 20, 15 40, 45 45, 35 10), (20 30, 30 20, 35 35, 20 30))",
                            "GEOMETRYCOLLECTION EMPTY"), c(8,1,1,1,4,1,1,1)))
    checkDuckDBColumn(st_centroid(x), st_centroid(sfc))
    checkDuckDBColumn(st_reduce_precision(st_collection_extract(st_voronoi(x), "POLYGON")[1L], 1),
                      "MULTIPOLYGON (((13 70, 70 70, 70 13, 70 -20, -20 -20, -20 70, 13 70)))")
    checkDuckDBColumn(st_concave_hull(x, 0.5), st_concave_hull(sfc, 0.5))
    checkDuckDBColumn(st_convex_hull(x), st_convex_hull(sfc))
    checkDuckDBColumn(st_envelope(x),
                      c("POLYGON ((10 10, 40 10, 40 40, 10 40, 10 10))",
                        "POINT EMPTY",
                        "POLYGON ((10 10, 40 10, 40 40, 10 40, 10 10))",
                        "POLYGON ((10 10, 40 10, 40 40, 10 40, 10 10))",
                        "POINT EMPTY", "POINT (30 10)",
                        "POLYGON ((10 10, 40 10, 40 40, 10 40, 10 10))",
                        "POINT EMPTY",
                        "POLYGON ((10 10, 40 10, 40 40, 10 40, 10 10))",
                        "POLYGON ((5 5, 45 5, 45 40, 5 40, 5 5))",
                        "POLYGON ((10 5, 45 5, 45 45, 10 45, 10 5))",
                        "POINT EMPTY", "POINT (30 10)", "POINT EMPTY",
                        "POINT (40 40)",
                        "POLYGON ((10 10, 40 10, 40 40, 10 40, 10 10))",
                        "POLYGON ((10 10, 45 10, 45 45, 10 45, 10 10))",
                        "POINT EMPTY"))
    checkDuckDBColumn(st_exterior_ring(x),
                      c(rep(NA, 15), "LINESTRING (30 10, 40 40, 20 40, 10 20, 30 10)",
                        "LINESTRING (35 10, 45 45, 15 40, 10 20, 35 10)", "LINESTRING EMPTY"))
    checkDuckDBColumn(st_flip_coordinates(x),
                      c("LINESTRING (10 30, 30 10, 40 40)",
                        "LINESTRING EMPTY",
                        "MULTILINESTRING ((10 30, 30 10, 40 40))",
                        "MULTILINESTRING ((10 10, 20 20, 40 10), (40 40, 30 30, 20 40, 10 30))",
                        "MULTILINESTRING EMPTY",
                        "MULTIPOINT (10 30)",
                        "MULTIPOINT (40 10, 30 40, 20 20, 10 30)",
                        "MULTIPOINT EMPTY",
                        "MULTIPOLYGON (((10 30, 40 40, 40 20, 20 10, 10 30)))",
                        "MULTIPOLYGON (((20 30, 40 45, 40 10, 20 30)), ((5 15, 10 40, 20 10, 10 5, 5 15)))",
                        "MULTIPOLYGON (((40 40, 45 20, 30 45, 40 40)), ((35 20, 30 10, 10 10, 5 30, 20 45, 35 20), (20 30, 15 20, 25 20, 20 30)))",
                        "MULTIPOLYGON EMPTY",
                        "POINT (10 30)",
                        "POINT EMPTY",
                        "POINT (40 40)",
                        "POLYGON ((10 30, 40 40, 40 20, 20 10, 10 30))",
                        "POLYGON ((10 35, 45 45, 40 15, 20 10, 10 35), (30 20, 35 35, 20 30, 30 20))",
                        "POLYGON EMPTY"))
    checkDuckDBColumn(st_reduce_precision(st_inscribed_circle(x[12L], 0.01), 1),
                      "POLYGON ((34 23, 34 21, 33 19, 31 17, 30 16, 28 15, 26 14, 24 14, 22 14, 20 15, 18 16, 17 17, 15 19, 14 21, 14 23, 14 25, 14 27, 14 29, 15 30, 17 32, 18 33, 20 34, 22 35, 24 35, 26 35, 28 34, 30 33, 31 32, 33 30, 34 29, 34 27, 34 25, 34 23))")
    checkDuckDBColumn(st_line_interpolate(df[df$type == "linestring", "geometry"][1], 5, normalized = FALSE),
                      st_line_interpolate(sfc[1], 5, normalized = FALSE))
    checkDuckDBColumn(st_line_interpolate(df[df$type == "linestring", "geometry"][1], 0.5, normalized = TRUE),
                      st_line_interpolate(sfc[1], 0.5, normalized = TRUE))
    checkDuckDBColumn(st_line_merge(df[df$type == "multilinestring", "geometry"]),
                      st_line_merge(sfc[3:5]))
    checkDuckDBColumn(st_line_merge(df[df$type == "multilinestring", "geometry"], directed = TRUE),
                      st_line_merge(sfc[3:5], directed = TRUE))
    checkDuckDBColumn(st_line_project(df[df$type == "linestring", "geometry"][1], query_pt_sfc),
                      st_line_project(sfc[1], query_pt_sfc))
    checkDuckDBColumn(st_line_project(df[df$type == "linestring", "geometry"][1], query_pt_sfc, normalized = TRUE),
                      st_line_project(sfc[1], query_pt_sfc, normalized = TRUE))
    checkDuckDBColumn(st_reduce_precision(st_line_substring(x[1L], 0.25, 0.75), 1), "LINESTRING (19 21, 10 30, 26 35)")
    checkDuckDBColumn(st_make_valid(x), st_make_valid(sfc))
    checkDuckDBColumn(st_minimum_rotated_rectangle(x), st_minimum_rotated_rectangle(sfc))
    line_idx <- which(st_geometry_type(sfc) == "LINESTRING" & !st_is_empty(sfc))[1L]
    if (!is.na(line_idx)) {
        checkDuckDBColumn(st_node(df[line_idx, "geometry"]), st_node(sfc[line_idx]))
    }
    checkDuckDBColumn(st_normalize(x), st_normalize(sfc))
    checkDuckDBColumn(st_point_on_surface(x), st_point_on_surface(sfc))
    checkDuckDBColumn(st_reverse(x), st_reverse(sfc))
    checkDuckDBColumn(st_remove_repeated_points(x), as.vector(x))
    checkDuckDBColumn(st_simplify(x), st_simplify(sfc))
    checkDuckDBColumn(st_voronoi(x), st_voronoi(sfc))

    ## Binary spatial predicates
    checkDuckDBColumn(st_contains(x, query_pt_sfc), st_contains(sfc, query_pt_sfc))
    checkDuckDBColumn(st_contains_properly(x, query_pt_sfc), st_contains_properly(sfc, query_pt_sfc))
    checkDuckDBColumn(st_covered_by(x, query_poly_sfc), st_covered_by(sfc, query_poly_sfc))
    checkDuckDBColumn(st_covers(x, query_pt_sfc), st_covers(sfc, query_pt_sfc))
    checkDuckDBColumn(st_crosses(x, query_line_sfc), st_crosses(sfc, query_line_sfc))
    checkDuckDBColumn(st_disjoint(x, far_pt_sfc), st_disjoint(sfc, far_pt_sfc))
    checkDuckDBColumn(st_equals(x, query_pt_sfc), st_equals(sfc, query_pt_sfc))
    checkDuckDBColumn(st_intersects(x, query_pt_sfc), st_intersects(sfc, query_pt_sfc))
    checkDuckDBColumn(st_is_within_distance(x, query_pt_sfc, 5), st_is_within_distance(sfc, query_pt_sfc, dist = 5))
    checkDuckDBColumn(st_overlaps(x, query_overlap_sfc), st_overlaps(sfc, query_overlap_sfc))
    checkDuckDBColumn(st_touches(x, query_pt_sfc), st_touches(sfc, query_pt_sfc))
    checkDuckDBColumn(st_within(x, query_poly_sfc), st_within(sfc, query_poly_sfc))
    checkDuckDBColumn(st_within_properly(x, query_poly_sfc), st_within_properly(sfc, query_poly_sfc))

    ## Binary set operations
    checkDuckDBColumn(st_difference(x, query_pt_sfc)[1], "LINESTRING (30 10, 10 30, 40 40)")
    checkDuckDBColumn(st_intersection(x, query_poly_sfc)[1], "LINESTRING (30 10, 10 30, 40 40)")
    checkDuckDBColumn(st_nearest_points(x, query_pt_sfc), st_nearest_points(sfc, query_pt_sfc))
    checkDuckDBColumn(st_union(x, query_pt_sfc), st_union(sfc, query_pt_sfc))

    ## Aggregate operations
    bbox_result <- st_bbox(x)
    expect_s3_class(bbox_result, "bbox")
    expect_equal(as.numeric(bbox_result), as.numeric(st_bbox(sfc)))

    collect_result <- st_collect(x)
    expect_s3_class(collect_result, "sfc")
    expect_length(collect_result, 1L)

    union_result <- st_union(x)
    expect_s3_class(union_result, "sfc")
    expect_length(union_result, 1L)
})

test_that("Summary methods work as expected for a DuckDBColumn", {
    df <- DuckDBDataFrame(mtcars_parquet, datacols = colnames(mtcars), keycol = "model")
    mpg <- df[["mpg"]]
    am <- df[["am"]]
    expect_identical(max(mpg), max(as.vector(mpg)))
    expect_identical(min(mpg), min(as.vector(mpg)))
    expect_identical(range(mpg), range(as.vector(mpg)))
    expect_equal(prod(mpg), prod(as.vector(mpg)))
    expect_equal(sum(mpg), sum(as.vector(mpg)))
    expect_identical(any(am == 0L), any(as.vector(am) == 0L))
    expect_identical(all(am == 0L), all(as.vector(am) == 0L))
})

test_that("Other aggregate methods work as expected for a DuckDBColumn", {
    df <- DuckDBDataFrame(mtcars_parquet, datacols = colnames(mtcars), keycol = "model")
    mpg <- df[["mpg"]]
    expect_equal(mean(mpg), mean(as.vector(mpg)))
    expect_equal(median(mpg), median(as.vector(mpg)))
    expect_equal(var(mpg), var(as.vector(mpg)))
    expect_equal(sd(mpg), sd(as.vector(mpg)))
    expect_equal(mad(mpg), mad(as.vector(mpg)))
    expect_equal(mad(mpg, constant = 1), mad(as.vector(mpg), constant = 1))

    expect_equal(quantile(mpg), quantile(as.vector(mpg)))
    expect_equal(quantile(mpg, probs = seq(0, 1, by = 0.05)), quantile(as.vector(mpg), probs = seq(0, 1, by = 0.05)))
    expect_equal(quantile(mpg, names = FALSE), quantile(as.vector(mpg), names = FALSE))
    expect_equal(quantile(mpg, type = 1), quantile(as.vector(mpg), type = 1))

    expect_equal(IQR(mpg), IQR(as.vector(mpg)))
    expect_equal(IQR(mpg, type = 1), IQR(as.vector(mpg), type = 1))

    gear <- df[["gear"]]
    carb <- df[["carb"]]
    expect_equal(table(gear, carb), table(gear = as.vector(gear), carb = as.vector(carb)))
})
