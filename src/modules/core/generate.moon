BoolGrid = require "BoolGrid"
mtwist = require "mtwist"
modules = require "core.data"
import RVOWorld from require "core"
T = modules.get_tilelist_id

import print_map, make_tunnel_oper, make_rectangle_criteria, make_rectangle_oper, place_instances
    from require "@map_util"
import random_square_spawn_object
    from require "@util_generate"

import FloodFillPaths, GameInstSet, GameTiles, GameView, util, TileMap
    from require "core"


PADDING = {10, 10}

make_ellipse = (x, y, w, h, n_points = 16, start_angle = 0) ->
    points = {}
    angle,step = start_angle,(1/n_points* 2 * math.pi)
    for i=1,n_points
        append points, {math.sin(angle) * w + x, math.cos(angle) * h + y}
        angle += step
    return points

Polygon = newtype {
    init: (@x, @y, @w, @h, @points_func) =>
        @points = false
    apply: (args) =>
        @points or= @.points_func(@x, @y, @w, @h, args.n_points or 16, args.angle)
        args.points = @points
        TileMap.polygon_apply(args)
    square_distance: (o) =>
        cx,cy = @center()
        ocx, ocy = o\center()
        dx, dy = cx - ocx, cy - ocy
        return dx*dx + dy*dy

    center: () =>
        return math.floor(@x+@w/2), math.floor(@y+@h/2)
    -- Create a line between the two polygons
    line_connect: (args) =>
        args.from_xy = {@center()}
        args.to_xy = {args.target\center()}
        TileMap.line_apply(args)
    arc_connect: (args) =>
        cx, cy = @center()
        ocx, ocy = args.target\center()
        min_w = math.min(@w,args.target.w) 
        min_h = math.min(@h,args.target.h) 
        w, h = math.abs(cx - ocx) - 1, math.abs(cy - ocy) - 1
        if w < 2 or h < 2 or w > 15 or h > 15
            return @line_connect(args)
        -- Set up the ellipse section for our connection:
        args.width = w * 2
        args.height = h * 2
        args.x, args.y = math.floor((cx+ocx)/2), math.floor((cy+ocy)/2)
        a1 = math.atan2((args.y - cy) / h , (args.x - cx)/w)
        a2 = math.atan2((args.y - ocy) / h, (args.x - ocx)/w)
        args.angle1, args.angle2 = a1 + math.pi/2, (a2 - a1)
        -- args.angle2 = math.atan2(-(args.y - ocy) / h, -(args.x - ocx)/w)
        TileMap.arc_apply(args)
}

-- Returns a list of edges
minimum_spanning_tree = (P) ->
    -- P: The list of polygons
    -- C: The connected set
    C = {false for p in *P}
    C[1] = true -- Start with the first polygon in the 'connected set'
    edge_list = {}
    while true
        -- Find the next edge to add:
        min_sqr_dist = math.huge
        min_i, min_j = nil, nil
        for i=1,#P do if C[i] 
            for j=1,#P do if not C[j]
                sqr_dist = P[i]\square_distance(P[j])
                if sqr_dist < min_sqr_dist
                    min_sqr_dist = sqr_dist
                    min_i, min_j = i, j
        -- All should be connected by this point
        if min_i == nil
            break
        C[min_j] = true
        append edge_list, {P[min_i], P[min_j]}

    return edge_list

-- A scheme based on circles dynamically placed in a room
RVOScheme = newtype {
    init: (boundary = nil) =>
        @rvo = RVOWorld.create(boundary)
        @polygons = {}
    add: (poly, velocity_func) =>
        append @polygons, poly
        {:x, :y, :w, :h} = poly
        poly.max_speed = rawget(poly, "max_speed") or 1
        r = math.max(w,h) -- Be conservative with the radius
        poly.id = @rvo\add_instance(x, y, r, poly.max_speed)
        poly.velocity_func = velocity_func
    step: () =>
        for poly in *@polygons
            {:id, :x, :y, :w, :h, :max_speed} = poly
            vx, vy = poly\velocity_func()
            @rvo\update_instance(id, x, y, math.max(w,h), max_speed, vx, vy)
        @rvo\step()
        for poly in *@polygons
            vx,vy = @rvo\get_velocity(poly.id)
            poly.x, poly.y = math.round(poly.x + vx), math.round(poly.y + vy)
}

make_rooms_with_tunnels = (map, rng, scheme) ->
    size = scheme.size
    padded_size = {size[1]+PADDING[1]*2, size[2]+PADDING[2]*2}
    oper = TileMap.random_placement_operator {
        size_range: scheme.rect_room_size_range
        rng: rng
        area: bbox_create(PADDING, size)
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
    oper map, TileMap.ROOT_GROUP, bbox_create(PADDING, size)

    tunnel_oper = make_tunnel_oper(rng, scheme.floor1, scheme.wall1, scheme.wall1_seethrough)

    tunnel_oper map, TileMap.ROOT_GROUP, bbox_create(PADDING, size)
    return map

FLAG_ALTERNATE = TileMap.FLAG_CUSTOM1
FLAG_INNER_PERIMETER = TileMap.FLAG_CUSTOM2

generate_circle_tilemap = (map, rng, scheme) ->
    size = scheme.size
    padded_size = map.size
    center_x, center_y = padded_size[1]/2, padded_size[2]/2
    N_CIRCLES = scheme.number_polygons
    RVO_ITERATIONS = scheme.rvo_iterations
    -- An RVO scheme with a circular boundary
    outer_points = scheme.outer_points
    R = RVOScheme.create {make_ellipse center_x, center_y, size[1]/2, size[1]/2, outer_points}

    for i=1,N_CIRCLES
        -- Make radius of the circle:
        r = scheme.room_radius()
        -- Make a random position within the circular room boundary:
        dist = rng\randomf(0, 1)
        ang = rng\randomf(0, 2*math.pi)
        x = math.cos(ang) * dist * (size[1]/2 - r) + center_x
        y = math.sin(ang) * dist * (size[2]/2 - r) + center_y
        -- Max drift is 1 tile:
        poly = Polygon.create x, y, r, r, make_ellipse 
        R\add(poly, scheme.polygon_delta_func(map, poly))

    for i=1,RVO_ITERATIONS
        R\step()

    for polygon in *R.polygons
        n_points, angle = rng\random(3,10), rng\randomf(0, math.pi)
        if rng\random(4) ~= 1
            polygon\apply {
                map: map
                area: bbox_create(PADDING, size)
                operator: {add: TileMap.FLAG_SEETHROUGH, remove: TileMap.FLAG_SOLID, content: scheme.floor1}
                :n_points, :angle
            }
        else
            polygon\apply {
                map: map
                area: bbox_create(PADDING, size)
                operator: {add: {TileMap.FLAG_SEETHROUGH, FLAG_ALTERNATE}, remove: TileMap.FLAG_SOLID, content: scheme.floor2}
                :n_points, :angle
            }

    -- Connect all the closest polygon pairs:
    edges = minimum_spanning_tree(R.polygons)
    -- Fuzzy matching & edge adding:
    for p1 in *R.polygons
        if rng\random(0,3) ~= 1
            break
        min_dist, best = math.huge, nil
        for p2 in *R.polygons
            if p1 == p2 or rng\random(0,3) ~= 1
                break
            dist = p1\square_distance(p2)
            if dist < min_dist
                min_dist = dist
                best = p2
        if best
            already_have_edge = false
            for {op1, op2} in *edges
                if op1 == p1 and op2 == best or op2 == p1 and op1 == best
                    already_have_edge = true
                    break
            if not already_have_edge
                append edges, {p1, best}
    for {p1, p2} in *minimum_spanning_tree(R.polygons)
        tile = scheme.floor1
        flags = {TileMap.FLAG_SEETHROUGH}
        if p2.id%5 <= 3 
            tile = scheme.floor2
            append flags, FLAG_ALTERNATE
        if rng\random(4) < 2
            p1\line_connect {
                map: map
                area: bbox_create(PADDING, size)
                target: p2
                line_width: scheme.connect_line_width()
                operator: {matches_none: FLAG_ALTERNATE, add: flags, remove: TileMap.FLAG_SOLID, content: tile}
            }
        else            
            p1\arc_connect {
                map: map
                area: bbox_create(PADDING, size)
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

    return map

generate_test_model = (rng) ->
    size = {120, 80}
    padded_size = {size[1]+PADDING[1]*2, size[2]+PADDING[2]*2}

    map = TileMap.map_create { 
        size: padded_size
        content: T('dungeon_wall')
        flags: TileMap.FLAG_SOLID
        instances: {}
    }

    oper = TileMap.random_placement_operator {
        size_range: {6,9}
        rng: rng
        amount_of_placements_range: {20, 20}
        create_subgroup: true
        child_operator: (map, subgroup, bounds) ->
            --Purposefully convoluted for test purposes
            queryfn = () ->
                query = make_rectangle_criteria()
                return query(map, subgroup, bounds)
            oper = make_rectangle_oper(queryfn)
            if oper(map, subgroup, bounds)
                --place_instances(rng, map, bounds)
                return true
            return false
    }
 
    -- Apply the binary space partitioning (bsp)
    oper map, TileMap.ROOT_GROUP, bbox_create(PADDING, size)

    tunnel_oper = make_tunnel_oper(rng)

    tunnel_oper map, TileMap.ROOT_GROUP, bbox_create({0,0}, padded_size)

    --print_map(map, map.instances) -- Uncomment to print
    return map

-- Simple model for exemplary purposes
generate_empty_model = (rng) ->
    size = {48, 20}
    padded_size = {size[1]+PADDING[1]*2, size[2]+PADDING[2]*2}
    map = TileMap.map_create { 
        size: padded_size
        content: T('dungeon_wall')
        flags: TileMap.FLAG_SOLID
        instances: {}
    }
 
    TileMap.rectangle_apply {
        map: map
        area: bbox_create(padding, size)
        fill_operator: add: TileMap.FLAG_SEETHROUGH, remove: TileMap.FLAG_SOLID, content: T('grey_floor')
    }

    --print_map(map, map.instances) -- Uncomment to print
    return map

create_map = (G, schemef) ->
    import map_state from require "core"
    scheme = schemef(G.rng)
    padded_size = {scheme.size[1]+PADDING[1]*2, scheme.size[2]+PADDING[2]*2}
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
    for i=1,scheme.n_statues do random_square_spawn_object M, gen_feature('statues', true), {
        matches_none: {FLAG_INNER_PERIMETER, TileMap.FLAG_HAS_OBJECT, TileMap.FLAG_SOLID}
    }
    for i=1,scheme.n_shops do random_square_spawn_object M, gen_feature('shops', false), {
        matches_none: {TileMap.FLAG_HAS_OBJECT, TileMap.FLAG_SOLID}
    }

    for i=1,scheme.n_stairs_down do random_square_spawn_object M, gen_feature('stairs_down', false), {
        matches_none: {TileMap.FLAG_HAS_OBJECT, TileMap.FLAG_SOLID}
    }

    for i=1,scheme.n_stairs_up do random_square_spawn_object M, gen_feature('stairs_up', false), {
        matches_none: {TileMap.FLAG_HAS_OBJECT, TileMap.FLAG_SOLID}
    }
    scheme.generate_objects(M)

    return M

return {
    :create_map
    :generate_circle_tilemap, :generate_test_model, :generate_empty_model
    :FLAG_ALTERNATE, :FLAG_INNER_PERIMETER
}
