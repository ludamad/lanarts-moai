
import camera, util_movement, util_geometry, util_draw, game_actions from require "core"
import StatUtils from require "stats.stats"
resources = require 'resources'
modules = require 'core.data'
user_io = require 'user_io'

-- Special movement helper

_action_move = (M, dirx, diry, dist) =>
    -- Decide on the path the maximizes distance:
    -- Multiply by '0.72' -- adjustment for directional movement
    total_dx, total_dy, distance = 0,0,0
    for dir_pref=0,1
        altdx, altdy, altdist = util_movement.look_ahead(@, M, dir_pref, dirx, diry)
        if altdist > distance
            total_dx, total_dy, distance = altdx, altdy, altdist
    if dirx ~= 0 and diry ~= 0 and distance ~= @speed
        mag_factor = math.sqrt(dirx*dirx + diry*diry) / math.abs(diry)
        for dir_pref=0,1
            altdx, altdy, altdist = util_movement.look_ahead(@, M, dir_pref, 0, diry * mag_factor)
            if altdist > distance
                total_dx, total_dy, distance = altdx, altdy, altdist

    -- Finally, take that path:
    @x += total_dx
    @y += total_dy
    if dirx ~= 0 or diry ~= 0
        @frame += 0.1

-- Pseudomethod
_handle_player_move = (M, dx, dy) =>
    if dx ~= 0 and dy ~= 0 then 
        dx *= 0.75
        dy *= 0.75
    _action_move(@, M, dx, dy, @speed)

_handle_action = (M, obj, action) ->
    if action.action_type == game_actions.ACTION_NONE
        return
    elseif action.action_type == game_actions.ACTION_MOVE
        id_player, step_number, dx, dy = game_actions.unbox_move_action(action)
        assert(id_player == obj.id_player)
        assert(step_number == M.gamestate.step_number)
        _handle_player_move(obj, M, dx, dy)

_action_move_with_velocity = (M, vx, vy) =>
    mag = math.sqrt(vx*vx + vy*vy)
    _action_move(@, M, vx / mag, vy / mag, mag)

-- Step event

_step_objects = (M) ->
    -- Step all stat contexts
    for obj in *M.combat_object_list
        StatUtils.stat_context_on_step(obj.stat_context)

    -- Set up directions of all players
    for obj in *M.player_list
        action = M.gamestate.get_action(obj.id_player)
        if action
            _handle_action(M, obj, action)
        obj\set_rvo(M, 0,0)

    -- Set up directions of all NPCs
    for obj in M.npc_iter()
        p = M.closest_player(obj)
        if p
            x1,y1,x2,y2 = util_geometry.object_bbox(obj)
            dx, dy = p.paths_to_player\interpolated_direction(x1,y1,x2,y2, obj.speed)
            obj\set_rvo(M, dx, dy)

    -- Run the collision avoidance algorithm
    M.rvo_world\step()
    -- for obj in M.npc_iter()
    --     vx, vy = obj\get_rvo_velocity(M)
    --     -- Advance forward
    --     if vx ~= 0 or vy ~= 0
    --         _action_move_with_velocity(obj, M, vx, vy)

    -- Sync up any data that requires copying after position changes
    for obj in *M.object_list
        obj\sync(M)

step = (M) ->
    _step_objects(M)

    -- Step the subsystems
    M.collision_world\step()
    M.rvo_world\step()

-- IO Handling

MAX_FUTURE_STEPS = 0

rdx,rdy = _RNG\random(-1,2),_RNG\random(-1,2)

_handle_player_io = (M) =>
    G = M.gamestate
    step_number = G.step_number
    while G.get_action(@id_player, step_number) 
        -- We already have an action for this frame, think forward
        step_number += 1
        if step_number > G.step_number + MAX_FUTURE_STEPS
            -- We do not want to queue up a huge amount of actions to be sent
            return

    dx,dy=0,0
    if (user_io.key_down "K_UP") or (user_io.key_down "K_W") 
        dy = -1
    elseif (user_io.key_down "K_DOWN") or (user_io.key_down "K_S") 
        dy = 1
    if (user_io.key_down "K_RIGHT") or (user_io.key_down "K_D") 
        dx = 1
    elseif (user_io.key_down "K_LEFT") or (user_io.key_down "K_A") 
        dx = -1

    if G.gametype ~= "single_player"
        if dx==0 and dy==0 then 
            dx,dy = rdx,rdy
            if _RNG\random(15) == 1
                rdx,rdy = _RNG\random(-1,2),_RNG\random(-1,2)

    action = game_actions.make_move_action @, step_number, dx, dy
    G.queue_action(action)
    -- if G.net_handler
        -- Send last two unacknowledged actions (included the one just queued)
        -- G.net_handler\send_unacknowledged_actions(2)

handle_io = (M) ->
    if (user_io.key_pressed "K_ESCAPE")
        os.exit()
    for player in *M.player_list
        if M.gamestate.is_local_player(player)
            _handle_player_io(player, M)

start = (V) -> nil
    -- for inst in *V.map.object_list
    --     inst\register_prop(V)

_text_style = with MOAITextStyle.new()
    \setColor 1,1,0 -- Yellow
    \setFont (resources.get_font 'Gudea-Regular.ttf')
    \setSize 14

_draw_text = (V, text, obj, dx, dy) ->
    util_draw.put_text V.ui_layer, _text_style, text, obj.x + dx, obj.y + dy

-- Takes view object
pre_draw = (V) ->
    util_draw.reset_draw_cache()

    for obj in *V.map.player_list
        _draw_text(V, V.gamestate.player_name(obj), obj, 0, -25)

    -- print MOAISim.getPerformance()
    if _SETTINGS.headless then return

    for obj in *V.map.object_list
        obj\pre_draw(V)

    -- Update in-focus object
    pobj = V.map.local_player()
    if pobj ~= nil -- Do we have a local player?
        if camera.camera_is_off_center(V, pobj.x, pobj.y)
            camera.sharp_center_on(V, pobj.x, pobj.y)
        else
            camera.center_on(V, pobj.x, pobj.y)

    -- Update the sight map

    x1,y1,x2,y2 = camera.tile_region_covered(V)
    for y=y1,y2 do for x=x1,x2
        tile = 2
        for inst in *V.map.player_list
            seen = inst.vision.seen_tile_map
            fov = inst.vision.fieldofview
            if seen\get(x,y) then tile = 1
        V.fov_grid\setTile(x, y, tile)

    for inst in *V.map.player_list
       {x1,y1,x2,y2} = inst.vision.current_seen_bounds
       fov = inst.vision.fieldofview
       for y=y1,y2-1 do for x=x1,x2-1
            if fov\within_fov(x,y)
                V.fov_grid\setTile(x, y, 0) -- Currently seen

    for component in *V.ui_components
        -- Step the component
        component()

draw = (V) ->
    -- Immediate mode drawing. TODO Reevaluate if needed
    for inst in *V.map.object_list
        inst\draw(V)

return {:step, :handle_io, :start, :pre_draw, :draw}
