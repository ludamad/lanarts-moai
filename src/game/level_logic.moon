
import modules, camera, util_movement, util_geometry from require 'game'
user_io = require 'user_io'

-- Step event

_step_objects = (L) ->
    -- Set up directions of all players
    for obj in L.player_iter()
        obj\set_rvo(L, 0,0)

    -- Set up directions of all NPCs
    for obj in L.npc_iter()
        p = L.closest_player(obj)
        if p
            x1,y1,x2,y2 = util_geometry.object_bbox(obj)
            dx, dy = p.paths_to_player\interpolated_direction(x1,y1,x2,y2, obj.speed)
            obj\set_rvo(L, dx, dy)

    -- Run the collision avoidance algorithm
    L.rvo_world\step()
    for obj in L.object_iter()
        vx, vy = obj\get_rvo_velocity(L)
        -- Advance forward
        obj.x, obj.y = obj.x + vx, obj.y + vy

    -- Sync up any data that requires copying after position changes
    for obj in L.object_iter()
        obj\sync(L)

step = (L) ->
    _step_objects(L)

    -- Step the subsystems
    L.collision_world\step()
    L.rvo_world\step()

-- IO Handling

_action_move = (L, dirx, diry, dist) =>
    -- Decide on the path the maximizes distance:
    -- Multiply by '0.72' -- adjustment for directional movement
    total_dx, total_dy, distance = 0,0,0
    correction = if dirx ~= 0 and diry ~= 0 then 0.75 else 1.0
    for dir_pref=0,1
        altdx, altdy, altdist = util_movement.look_ahead(@, L, dir_pref, dirx * correction, diry * correction)
        if altdist > distance
            total_dx, total_dy, distance = altdx, altdy, altdist
    if dirx ~= 0 and diry ~= 0 and distance ~= @speed
        for dir_pref=0,1
            altdx, altdy, altdist = util_movement.look_ahead(@, L, dir_pref, 0, diry)
            if altdist > distance
                total_dx, total_dy, distance = altdx, altdy, altdist

    -- Finally, take that path:
    @x += total_dx
    @y += total_dy

_handle_player_io = (L) =>
    dx,dy=0,0
    if (user_io.key_down "K_UP") or (user_io.key_down "K_W") 
        dy = -1
    elseif (user_io.key_down "K_DOWN") or (user_io.key_down "K_S") 
        dy = 1
    if (user_io.key_down "K_RIGHT") or (user_io.key_down "K_D") 
        dx = 1
    elseif (user_io.key_down "K_LEFT") or (user_io.key_down "K_A") 
        dx = -1
    _action_move(@, L, dx, dy, @speed)

handle_io = (L) ->
    for player in L.player_iter()
        _handle_player_io(player, L)

start = (V) ->
    for inst in V.level.object_iter()
        inst\register_prop(V)

-- Takes view object
pre_draw = (V) ->
    -- print MOAISim.getPerformance()
    if _SETTINGS.headless then return

    for obj in V.level.object_iter()
        obj\update_prop(V)

    for component in *V.ui_components
        -- Step the component
        component()

    -- Update in-focus object
    for obj in V.level.player_iter()
        if camera.camera_is_off_center(V, obj.x, obj.y)
            camera.sharp_center_on(V, obj.x, obj.y)
        else
            camera.center_on(V, obj.x, obj.y)

    -- Update the sight map
    for inst in V.level.player_iter()
       {seen_tile_map: seen, prev_seen_bounds: prev, current_seen_bounds: curr, fieldofview: fov} = inst.vision
       x1,y1,x2,y2 = camera.tile_region_covered(V)
       for y=y1,y2 do for x=x1,x2
            tile = if seen\get(x,y) then 1 else 2
            V.fov_grid\setTile(x, y, tile)
       {x1,y1,x2,y2} = curr
       for y=y1,y2-1 do for x=x1,x2-1
            if fov\within_fov(x,y)
                V.fov_grid\setTile(x, y, 0) -- Currently seen

return {:step, :handle_io, :start, :pre_draw}