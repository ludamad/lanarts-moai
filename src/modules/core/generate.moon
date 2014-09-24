BoolGrid = require "BoolGrid"
mtwist = require "mtwist"
modules = require "core.data"
import RVOWorld from require "core"
T = modules.get_tilelist_id

import print_map, make_tunnel_oper, make_rectangle_criteria, make_rectangle_oper, place_instances
    from require "@map_util"

import FloodFillPaths, GameInstSet, GameTiles, GameView, util, TileMap
    from require "core"


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
        @points or= @.points_func(@x, @y, @w, @h, args.n_points or 16)
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
        w, h = math.abs(cx - ocx) - min_w, math.abs(cy - ocy) - min_h
        if w < 2 or h < 2
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

generate_circle_scheme = (rng) ->
    padding = {10, 10}
    size = {50,50}
    padded_size = {size[1]+padding[1]*2, size[2]+padding[2]*2}
    center_x, center_y = padded_size[1]/2, padded_size[2]/2
    N_CIRCLES = 40--rng\random(6,15)
    RVO_ITERATIONS = 200
    -- An RVO scheme with a circular boundary
    outer_points = 20--rng\random(3,20)
    start_angle = 0--rng\randomf(0,2*math.pi)
    R = RVOScheme.create {make_ellipse center_x, center_y, size[1]/2, size[1]/2, outer_points, start_angle}

    for i=1,N_CIRCLES
        -- Make radius of the circle:
        r = 2
        for j=1,4 do r += rng\random(0, 2)
        -- Make a random position within the circular room boundary:
        dist = rng\randomf(0, 1)
        ang = rng\randomf(0, 2*math.pi)
        x = math.cos(ang) * dist * (size[1]/2 - r) + center_x
        y = math.sin(ang) * dist * (size[2]/2 - r) + center_y
        -- Max drift is 1 tile:
        poly = Polygon.create x, y, r, r, make_ellipse 
        local vfunc 
        if rng\random(0, 2) == 1
            vfunc = () => math.sign_of(@x - center_x)*2, math.sign_of(@y - center_y)*2
        else
            vfunc = () => math.sign_of(center_x - @x)*2, math.sign_of(center_y - @y)*2
        R\add(poly, vfunc)

    map = TileMap.map_create { 
        size: padded_size
        content: T('dungeon_wall')
        flags: TileMap.FLAG_SOLID
        instances: {}
    }
    for i=1,RVO_ITERATIONS
        R\step()

    for polygon in *R.polygons
        tile = (if polygon.id%5 <= 3 then T('grey_floor') else T('reddish_grey_floor'))
        polygon\apply {
            map: map
            area: bbox_create(padding, size)
            operator: {add: TileMap.FLAG_SEETHROUGH, remove: TileMap.FLAG_SOLID, content: tile}
            n_points: rng\random(4,8)
        }

    -- Connect all the closest polygon pairs:
    for {p1, p2} in *minimum_spanning_tree(R.polygons)
        tile = (if p2.id%5 <= 3 then T('grey_floor') else T('reddish_grey_floor'))
        p1\arc_connect {
            map: map
            area: bbox_create(padding, size)
            target: p2
            line_width: 2
            operator: {add: TileMap.FLAG_SEETHROUGH, remove: TileMap.FLAG_SOLID, content: tile}
        }

    TileMap.perimeter_apply {
        map: map
        operator: {add: TileMap.FLAG_PERIMETER}
    }
    return map

generate_test_model = (rng) ->
    padding = {10, 10}
    size = {120, 80}
    padded_size = {size[1]+padding[1]*2, size[2]+padding[2]*2}

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
    oper map, TileMap.ROOT_GROUP, bbox_create(padding, size)

    tunnel_oper = make_tunnel_oper(rng)

    tunnel_oper map, TileMap.ROOT_GROUP, bbox_create({0,0}, padded_size)

    --print_map(map, map.instances) -- Uncomment to print
    return map

-- Simple model for exemplary purposes
generate_empty_model = (rng) ->
    padding = {10, 10}
    size = {48, 20}
    padded_size = {size[1]+padding[1]*2, size[2]+padding[2]*2}
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

return {:generate_circle_scheme, :generate_test_model, :generate_empty_model}
