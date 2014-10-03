import RVOWorld, TileMap from require "core"

LEVEL_PADDING = {10, 10}

----
-- Polygon based regions

ellipse_points = (x, y, w, h, n_points = 16, start_angle = 0) ->
    points = {}
    angle,step = start_angle,(1/n_points* 2 * math.pi)
    for i=1,n_points
        append points, {math.sin(angle) * w + x, math.cos(angle) * h + y}
        angle += step
    return points

Region = newtype {
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
    -- Create a line between the two regions
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
region_minimum_spanning_tree = (R) ->
    -- R: The list of regions
    -- C: The connected set
    C = {false for p in *R}
    C[1] = true -- Start with the first polygon in the 'connected set'
    edge_list = {}
    while true
        -- Find the next edge to add:
        min_sqr_dist = math.huge
        min_i, min_j = nil, nil
        for i=1,#R do if C[i] 
            for j=1,#R do if not C[j]
                sqr_dist = R[i]\square_distance(R[j])
                if sqr_dist < min_sqr_dist
                    min_sqr_dist = sqr_dist
                    min_i, min_j = i, j
        -- All should be connected by this point
        if min_i == nil
            break
        C[min_j] = true
        append edge_list, {R[min_i], R[min_j]}

    return edge_list

-- A scheme based on circles dynamically placed in a room
RVORegionPlacer = newtype {
    init: (boundary = nil) =>
        @rvo = RVOWorld.create(boundary)
        @regions = {}
    add: (poly, velocity_func) =>
        append @regions, poly
        {:x, :y, :w, :h} = poly
        poly.max_speed = rawget(poly, "max_speed") or 1
        r = math.max(w,h) -- Be conservative with the radius
        poly.id = @rvo\add_instance(x, y, r, poly.max_speed)
        poly.velocity_func = velocity_func
    step: () =>
        for poly in *@regions
            {:id, :x, :y, :w, :h, :max_speed} = poly
            vx, vy = poly\velocity_func()
            @rvo\update_instance(id, x, y, math.max(w,h), max_speed, vx, vy)
        @rvo\step()
        for poly in *@regions
            vx,vy = @rvo\get_velocity(poly.id)
            poly.x, poly.y = math.round(poly.x + vx), math.round(poly.y + vy)
}


----
-- Map square placement

DEFAULT_SELECTOR = {matches_none: {TileMap.FLAG_SOLID, TileMap.FLAG_HAS_OBJECT}}
map_place_object = (M, spawner, selector = DEFAULT_SELECTOR) ->
    sqr = TileMap.find_random_square {
        map: M.tilemap
        rng: M.rng
        :selector
        operator: add: TileMap.FLAG_HAS_OBJECT
    }
    if not sqr
        return false
    {px, py} = sqr

    spawner(px, py)
    return true

return {
    :LEVEL_PADDING, :ellipse_points, :Region, :RVORegionPlacer, :region_minimum_spanning_tree, :map_place_object
}
