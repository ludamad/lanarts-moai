----
-- Generates a world-plan for the game world.
-- This creates the high-level details for the game world, ie everything 
-- other than actual tile details and enemy placements for worlds.
----

-- First decision:
-- What sort of places will be in the game world.

import map_place_object, ellipse_points, 
    LEVEL_PADDING, Region, RVORegionPlacer, 
    random_rect_in_rect, random_ellipse_in_ellipse, 
    ring_region_delta_func, default_region_delta_func,
    random_region_add, region_minimum_spanning_tree
    Tile, tile_operator
        from require "@generate_util"

import print_map, make_tunnel_oper, make_rectangle_criteria, make_rectangle_oper
    from require "@map_util"

import TileMap from require "core"

-- Generation constants and data
FLAG_ALTERNATE = TileMap.FLAG_CUSTOM1
FLAG_INNER_PERIMETER = TileMap.FLAG_CUSTOM2

OVERWORLD_MAX_W, OVERWORLD_MAX_H = 200, 200
OVERWORLD_CONF = (rng) -> {
    map_label: "Plain Valley"
    size: {85, 85}--if rng\random(0,2) == 0 then {135, 85} else {85, 135} 
    number_regions: rng\random(15,30)
    outer_points: () -> 20
    floor1: Tile.create('grass1', false, true)
    floor2: Tile.create('grass2', false, true) 
    wall1: Tile.create('tree', true, true)
    wall2: Tile.create('dungeon_wall', true, false)
    line_of_sight: 8
    rect_room_num_range: {4,10}
    rect_room_size_range: {10,15}
    rvo_iterations: 150
    n_shops: rng\random(2,4)
    n_stairs_down: 3
    n_stairs_up: 0
    connect_line_width: () -> rng\random(2,6)
    region_delta_func: ring_region_delta_func
    room_radius: () ->
        r = 2
        bound = rng\random(1,20)
        for j=1,rng\random(0,bound) do r += rng\randomf(0, 1)
        return r
    -- Dungeon objects/features
    monster_weights: () -> {["Giant Rat"]: 15, ["Cloud Elemental"]: 5}
    n_statues: 10
}

make_rooms_with_tunnels = (map, rng, conf, outer) ->
    oper = TileMap.random_placement_operator {
        size_range: conf.rect_room_size_range
        rng: rng
        area: outer\bbox()
        amount_of_placements_range: conf.rect_room_num_range
        create_subgroup: true
        child_operator: (map, subgroup, bounds) ->
            --Purposefully convoluted for test purposes
            queryfn = () ->
                query = make_rectangle_criteria()
                return query(map, subgroup, bounds)
            oper = make_rectangle_oper(conf.floor2.id, conf.wall2.id, false, queryfn)
            if oper(map, subgroup, bounds)
                --place_instances(rng, map, bounds)
                return true
            return false
    }
 
    -- Apply the binary space partitioning (bsp)
    oper map, TileMap.ROOT_GROUP, outer\bbox()

    tunnel_oper = make_tunnel_oper(rng, conf.floor1.id, conf.wall1.id, true)--conf.wall1_seethrough)

    tunnel_oper map, TileMap.ROOT_GROUP, outer\bbox()
    return map

generate_area = (map, rng, conf, outer) ->
    size = conf.size
    R = RVORegionPlacer.create {outer.points}

    for i=1,conf.number_regions
        -- Make radius of the circle:
        r, n_points, angle = conf.room_radius(),rng\random(3,10) ,rng\randomf(0, math.pi)
        random_region_add rng, r*2,r*2, n_points, conf.region_delta_func(map, rng, outer), angle, R, outer\bbox(), true

    R\steps(conf.rvo_iterations)

    for region in *R.regions
        tile = (if rng\random(4) ~= 1 then conf.floor1 else conf.floor2)
        region\apply {
            map: map, area: outer\bbox(), operator: (tile_operator tile)
        }

    -- Connect all the closest region pairs:
    edges = region_minimum_spanning_tree(R.regions)
    add_edge_if_unique = (p1,p2) ->
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
                add_edge_if_unique p1, p2

    for {p1, p2} in *edges
        tile = conf.floor1
        flags = {}
        if p2.id%5 <= 3 
            tile = conf.floor2
            append flags, FLAG_ALTERNATE
        f = (if rng\random(4) < 2 then p1.line_connect else p1.arc_connect)
        f p1, {
            map: map, area: outer\bbox(), target: p2
            line_width: conf.connect_line_width()
            operator: (tile_operator tile, {matches_none: FLAG_ALTERNATE, add: flags})
        }

    -- Diagonal pairs are a bit ugly. We can see through them but not pass them. Just open them up.
    TileMap.erode_diagonal_pairs {:map, :rng, area: outer\bbox(), selector: {matches_all: TileMap.FLAG_SOLID}}
    -- Detect the perimeter, important for the winding-tunnel algorithm.
    TileMap.perimeter_apply {
        map: map
        area: outer\bbox()
        candidate_selector: {matches_all: TileMap.FLAG_SOLID}
        inner_selector: {matches_none: TileMap.FLAG_SOLID}
        operator: {add: TileMap.FLAG_PERIMETER}
    }

    TileMap.perimeter_apply {
        map: map
        area: outer\bbox()
        candidate_selector: {matches_all: TileMap.FLAG_SOLID}
        inner_selector: {matches_all: FLAG_ALTERNATE, matches_none: TileMap.FLAG_SOLID}
        operator: tile_operator conf.wall2 
    }

    make_rooms_with_tunnels map, rng, conf, outer

    TileMap.perimeter_apply {
        map: map
        area: outer\bbox()
        candidate_selector: {matches_none: {TileMap.FLAG_SOLID}}
        inner_selector: {matches_all: {TileMap.FLAG_PERIMETER, TileMap.FLAG_SOLID}}
        operator: {add: FLAG_INNER_PERIMETER}
    }

generate_overworld = (rng) ->
    conf = OVERWORLD_CONF(rng)
    {PW,PH} = LEVEL_PADDING
    outer = Region.create(1+PW,1+PH,OVERWORLD_MAX_W-PW,OVERWORLD_MAX_H-PH)
    -- Generate regions in a large area, crop them later
    major_regions = RVORegionPlacer.create {outer.points}
    map = TileMap.map_create { 
        size: {OVERWORLD_MAX_W, OVERWORLD_MAX_H}
        content: conf.wall1.id
        flags: conf.wall1.add_flags
        regions: major_regions, map_label: conf.map_label, line_of_sight: conf.line_of_sight
    }

    for i=1,2
        {w,h} = {rng\random(50,85),rng\random(50, 85)}
        -- Takes region parameters, region placer, and region outer ellipse bounds:
        random_region_add rng, w, h, conf.outer_points(), conf.region_delta_func(map, rng, outer), 0,
            major_regions, outer\bbox()

    -- major_regions\steps(conf.rvo_iterations)

    conf = OVERWORLD_CONF(rng)
    for region in *major_regions.regions
        -- region\apply{:map, operator: tile_operator conf.wall2}
        generate_area(map, rng, conf, region)
        -- conf.floor1 = Tile.create('dungeon_wall', false, true)
        -- conf.floor2 = Tile.create('dungeon_wall', false, true)

    return map

generate_game_map = (G, map) ->
    import map_state from require "core"
    import map_place_object, map_place_monsters from require "@generate_objects"
    import Feature from require '@map_object_types'
    
    M = map_state.create_map_state(G, 1, G.rng, map.map_label, map, map.line_of_sight)
    gen_feature = (sprite, solid) -> (px, py) -> 
        Feature.create M, {x: px*32+16, y: py*32+16, :sprite, :solid}

    for region in *map.regions
        area = region\bbox()
       -- for i=1,conf.n_statues do map_place_object M, gen_feature('statues', true), {
       --     matches_none: {FLAG_INNER_PERIMETER, TileMap.FLAG_HAS_OBJECT, TileMap.FLAG_SOLID}
       -- }, area
       -- for i=1,conf.n_shops do map_place_object M, gen_feature('shops', false), {
       --     matches_none: {TileMap.FLAG_HAS_OBJECT, TileMap.FLAG_SOLID}
       -- }, area

       -- for i=1,conf.n_stairs_down do map_place_object M, gen_feature('stairs_down', false), {
       --     matches_none: {TileMap.FLAG_HAS_OBJECT, TileMap.FLAG_SOLID}
       -- }, area

       -- for i=1,conf.n_stairs_up do map_place_object M, gen_feature('stairs_up', false), {
       --     matches_none: {TileMap.FLAG_HAS_OBJECT, TileMap.FLAG_SOLID}
       -- }, area
        map_place_monsters OVERWORLD_CONF.monster_weights, area
    return M

return {
    :generate_overworld, :generate_game_map
}
