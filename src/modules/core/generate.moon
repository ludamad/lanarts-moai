BoolGrid = require "BoolGrid"
mtwist = require "mtwist"
modules = require "core.data"
import RVOWorld from require "core"
T = modules.get_tilelist_id

import print_map, make_tunnel_oper, make_rectangle_criteria, make_rectangle_oper, place_instances
    from require "@map_util"

import FloodFillPaths, GameInstSet, GameTiles, GameView, util, TileMap
    from require "core"


make_ellipse = (x, y, w, h, n_points = 16) ->
    points = {}
    angle,step = 0,(1/n_points* 2 * math.pi)
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
    center: () =>
        return math.floor(@x+@w/2), math.floor(@y+@h/2)
    -- Create a line between the two polygons
    connect: (o, args) =>
        cx,cy = @center()
        ocx, ocy = o\center()
        TileMap.line_apply
}

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
    ROOM_RADIUS = 25
    N_CIRCLES = 30
    RVO_ITERATIONS = 20
    -- An RVO scheme with a circular boundary
    R = RVOScheme.create {make_ellipse ROOM_RADIUS+padding[1], ROOM_RADIUS+padding[2], ROOM_RADIUS, ROOM_RADIUS}

    for i=1,N_CIRCLES
        -- Make radius of the circle:
        r = rng\random(2, 5)
        -- Make a random position within the circular room boundary:
        dist = rng\randomf(ROOM_RADIUS - r)
        ang = rng\randomf(0, 2*math.pi)
        x = math.cos(ang) * dist + ROOM_RADIUS + padding[1]
        y = math.sin(ang) * dist + ROOM_RADIUS + padding[2]
        -- Max drift is 1 tile:
        poly = Polygon.create x, y, r, r, make_ellipse 
        R\add(poly, () => math.sign_of(@x - center_x), math.sign_of(@y - center_y))

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

    -- Connect all the closest polygons:

    return map

generate_circle_scheme_old = (rng) ->
    -- Create an enclosing circle, in clockwise order.
    ROOM_RADIUS = 25
    N_POINTS = 16
    N_CIRCLES = 30
    RVO_ITERATIONS = 20
    boundary = {}
    for i=1,N_POINTS
        x = math.sin(i/N_POINTS * 2 * math.pi) * ROOM_RADIUS  + ROOM_RADIUS + 10
        y = math.cos(i/N_POINTS * 2 * math.pi) * ROOM_RADIUS + ROOM_RADIUS + 10
        append boundary, {x,y}
    
    -- Pass {boundary} as the list of obstacles.
    rvo_world = RVOWorld.create({boundary})

    for i=0,N_CIRCLES-1
        r = rng\randomf(2, 4)
        x = rng\randomf(ROOM_RADIUS - r) + ROOM_RADIUS + 10
        y = rng\randomf(ROOM_RADIUS - r) + ROOM_RADIUS + 10
        -- Max drift is 1 tile:
        rvo_world\add_instance(x, y, r, 1)

    padding = {10, 10}
    size = {50,50}
    padded_size = {size[1]+padding[1]*2, size[2]+padding[2]*2}
    map = TileMap.map_create { 
        size: padded_size
        content: T('dungeon_wall')
        flags: TileMap.FLAG_SOLID
        instances: {}
    }
 
    apply_circle = (x, y, r, n_points, tile) ->
        polygon = {}
        for i=1,n_points
            ang = i/n_points * 2 * math.pi
            append polygon, {math.sin(ang) * r + x, math.cos(ang) * r + y}
        TileMap.polygon_apply {
            map: map
            points: polygon
            area: bbox_create(padding, size)
            operator: add: TileMap.FLAG_SEETHROUGH, remove: TileMap.FLAG_SOLID, content: tile
        }
    for i=1,RVO_ITERATIONS
        for j=0,N_CIRCLES-1
            center_x, center_y = padded_size[1]/2, padded_size[2]/2
            x,y = rvo_world\get_position(j)
            dx, dy = math.sign_of(center_x - x), math.sign_of(center_y - y)
            -- 
            rvo_world\set_preferred_velocity(j, -dx*8, -dy*8)
        rvo_world\step()
        for j=0,N_CIRCLES-1
            x,y = rvo_world\get_position(j)
            vx,vy = rvo_world\get_velocity(j)
            rvo_world\set_position(j, x + vx, y + vy)
    for i=0,N_CIRCLES-1
        x,y = rvo_world\get_position(i)
        r = rvo_world\get_radius(i) + 1
        n_points = rng\random(4,8)
        apply_circle x,y,r, n_points, (if i%5 <= 3 then T('grey_floor') else T('reddish_grey_floor'))

    --print_map(map, map.instances) -- Uncomment to print
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
