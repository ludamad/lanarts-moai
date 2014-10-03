BoolGrid = require "BoolGrid"
mtwist = require "mtwist"
modules = require "core.data"

import print_map, make_tunnel_oper, make_rectangle_criteria, make_rectangle_oper
    from require "@map_util"

import map_place_object, ellipse_points, LEVEL_PADDING, Region, RVORegionPlacer, region_minimum_spanning_tree 
    from require "@generate_util"

import FloodFillPaths, GameInstSet, GameTiles, GameView, util, TileMap
    from require "core"

make_rooms_with_tunnels = (map, rng, scheme) ->
    size = scheme.size
    padded_size = {size[1]+LEVEL_PADDING[1]*2, size[2]+LEVEL_PADDING[2]*2}
    oper = TileMap.random_placement_operator {
        size_range: scheme.rect_room_size_range
        rng: rng
        area: bbox_create(LEVEL_PADDING, size)
        amount_of_placements_range: scheme.rect_room_num_range
        create_subgroup: true
        child_operator: (map, subgroup, bounds) ->
            --Purposefully convoluted for test purposes
            queryfn = () ->
                query = make_rectangle_criteria()
                return query(map, subgroup, bounds)
            oper = make_rectangle_oper(scheme.floor2, scheme.wall2, scheme.wall2_seethrough, queryfn)
            if oper(map, subgroup, bounds)
                --place_instances(rng, map, bounds)
                return true
            return false
    }
 
    -- Apply the binary space partitioning (bsp)
    oper map, TileMap.ROOT_GROUP, bbox_create(LEVEL_PADDING, size)

    tunnel_oper = make_tunnel_oper(rng, scheme.floor1, scheme.wall1, scheme.wall1_seethrough)

    tunnel_oper map, TileMap.ROOT_GROUP, bbox_create(LEVEL_PADDING, size)
    return map

FLAG_ALTERNATE = TileMap.FLAG_CUSTOM1
FLAG_INNER_PERIMETER = TileMap.FLAG_CUSTOM2

generate_circle_tilemap = (map, rng, scheme) ->
    size = scheme.size
    padded_size = map.size
    center_x, center_y = padded_size[1]/2, padded_size[2]/2
    N_CIRCLES = scheme.number_regions
    RVO_ITERATIONS = scheme.rvo_iterations
    -- An RVO scheme with a circular boundary
    outer_points = scheme.outer_points
    R = RVORegionPlacer.create {ellipse_points center_x, center_y, size[1]/2, size[1]/2, outer_points}

    for i=1,N_CIRCLES
        -- Make radius of the circle:
        r = scheme.room_radius()
        -- Make a random position within the circular room boundary:
        dist = rng\randomf(0, 1)
        ang = rng\randomf(0, 2*math.pi)
        x = math.cos(ang) * dist * (size[1]/2 - r) + center_x
        y = math.sin(ang) * dist * (size[2]/2 - r) + center_y
        -- Max drift is 1 tile:
        region = Region.create x, y, r, r, ellipse_points 
        R\add(region, scheme.region_delta_func(map, region))

    for i=1,RVO_ITERATIONS
        R\step()

    for region in *R.regions
        n_points, angle = rng\random(3,10), rng\randomf(0, math.pi)
        if rng\random(4) ~= 1
            region\apply {
                map: map
                area: bbox_create(LEVEL_PADDING, size)
                operator: {add: TileMap.FLAG_SEETHROUGH, remove: TileMap.FLAG_SOLID, content: scheme.floor1}
                :n_points, :angle
            }
        else
            region\apply {
                map: map
                area: bbox_create(LEVEL_PADDING, size)
                operator: {add: {TileMap.FLAG_SEETHROUGH, FLAG_ALTERNATE}, remove: TileMap.FLAG_SOLID, content: scheme.floor2}
                :n_points, :angle
            }

    -- Connect all the closest region pairs:
    edges = region_minimum_spanning_tree(R.regions)
    add_if_unique = (p1,p2) ->
        for {op1, op2} in *edges
            if op1 == p1 and op2 == p2 or op2 == p1 and op1 == p2
                return
        append edges, {p1, p2}

    -- Append all < threshold in distance
    for i=1,#R.regions
        for j=i+1,#R.regions do if rng\random(0,3) == 1
            p1, p2 = R.regions[i], R.regions[j]
            dist = math.sqrt( (p2.x-p1.x)^2+(p2.y-p1.y)^2)
            if dist < rng\random(5,15)
                add_if_unique p1, p2

    for {p1, p2} in *edges
        tile = scheme.floor1
        flags = {TileMap.FLAG_SEETHROUGH}
        if p2.id%5 <= 3 
            tile = scheme.floor2
            append flags, FLAG_ALTERNATE
        if rng\random(4) < 2
            p1\line_connect {
                map: map
                area: bbox_create(LEVEL_PADDING, size)
                target: p2
                line_width: scheme.connect_line_width()
                operator: {matches_none: FLAG_ALTERNATE, add: flags, remove: TileMap.FLAG_SOLID, content: tile}
            }
        else
            p1\arc_connect {
                map: map
                area: bbox_create(LEVEL_PADDING, size)
                target: p2
                line_width: scheme.connect_line_width()
                operator: {matches_none: FLAG_ALTERNATE, add: flags, remove: TileMap.FLAG_SOLID, content: tile}
            }

    -- Diagonal pairs are a bit ugly. We can see through them but not pass them. Just open them up.
    TileMap.erode_diagonal_pairs {:map, :rng, selector: {matches_all: TileMap.FLAG_SOLID}}
    TileMap.perimeter_apply {
        map: map
        candidate_selector: {matches_all: TileMap.FLAG_SOLID}
        inner_selector: {matches_none: TileMap.FLAG_SOLID}
        operator: {add: TileMap.FLAG_PERIMETER}
    }

    remove_alt = {TileMap.FLAG_SEETHROUGH}
    add_alt = {TileMap.FLAG_ALTERNATE}
    if scheme.wall2_seethrough
        remove_alt = {}
        append add_alt, TileMap.FLAG_SEETHROUGH
    TileMap.perimeter_apply {
        map: map
        candidate_selector: {matches_all: TileMap.FLAG_SOLID}
        inner_selector: {matches_all: FLAG_ALTERNATE, matches_none: TileMap.FLAG_SOLID}
        operator: {content: scheme.wall2, remove: remove_alt, add: add_alt}
    }

    make_rooms_with_tunnels map, rng, scheme

    TileMap.perimeter_apply {
        map: map
        candidate_selector: {matches_none: {TileMap.FLAG_SOLID}}
        inner_selector: {matches_all: {TileMap.FLAG_PERIMETER, TileMap.FLAG_SOLID}}
        operator: {add: FLAG_INNER_PERIMETER}
    }

create_map = (G, schemef) ->
    import map_state from require "core"
    scheme = schemef(G.rng)
    padded_size = {scheme.size[1]+LEVEL_PADDING[1]*2, scheme.size[2]+LEVEL_PADDING[2]*2}
    tilemap = TileMap.map_create { 
        size: padded_size
        content: scheme.wall1
        flags: TileMap.FLAG_SOLID + (if scheme.wall1_seethrough then TileMap.FLAG_SEETHROUGH else 0)
        instances: {}
    }
    generate_circle_tilemap(tilemap, G.rng, scheme)
    M = map_state.create_map_state(G, 1, G.rng, scheme.map_label, tilemap, scheme.line_of_sight)
    
    import Feature from require '@map_object_types'
    gen_feature = (sprite, solid) -> (px, py) -> Feature.create M, {x: px*32+16, y: py*32+16, :sprite, :solid}
    for i=1,scheme.n_statues do map_place_object M, gen_feature('statues', true), {
        matches_none: {FLAG_INNER_PERIMETER, TileMap.FLAG_HAS_OBJECT, TileMap.FLAG_SOLID}
    }
    for i=1,scheme.n_shops do map_place_object M, gen_feature('shops', false), {
        matches_none: {TileMap.FLAG_HAS_OBJECT, TileMap.FLAG_SOLID}
    }

    for i=1,scheme.n_stairs_down do map_place_object M, gen_feature('stairs_down', false), {
        matches_none: {TileMap.FLAG_HAS_OBJECT, TileMap.FLAG_SOLID}
    }

    for i=1,scheme.n_stairs_up do map_place_object M, gen_feature('stairs_up', false), {
        matches_none: {TileMap.FLAG_HAS_OBJECT, TileMap.FLAG_SOLID}
    }
    scheme.generate_objects(M)

    return M

return {
    :create_map
    :generate_circle_tilemap
    :FLAG_ALTERNATE, :FLAG_INNER_PERIMETER
}
