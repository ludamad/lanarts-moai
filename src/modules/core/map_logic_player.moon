
import util_movement, util_geometry, util_draw, game_actions, FloodFillPaths from require "core"
statsystem = require "statsystem"
import Display from require "ui"

import ObjectBase, CombatObjectBase, Player, NPC, Projectile from require '@map_object_types'

resources = require 'resources'
modules = require 'core.data'
user_io = require 'user_io'

player_free_ahead = (M, obj, dx, dy) -> (not M.tile_check obj, dx, dy) -- and (not M.tile_check obj, dx*4, dy*4) 
player_free_eventually = (M, obj, dx, dy) -> 
    dx, dy = math.sign_of(dx), math.sign_of(dy)
    for i=(obj.stats.move_speed+1),48
        if player_free_ahead(M, obj, dx*i, dy*i)
            return true
    return false

-- cdx and cdy: If 0, any direction not opposite to dx, dy (respectively) OK. If not 0, only 0 OK.
player_adjust_direction = (M, obj, dx, dy, cdx, cdy, speed) ->
    if not M.tile_check obj, dx, dy
        return dx, dy
    -- Try to find the best choice, within constraints:
    -- Handle cases where one dimension is 0:
    if dx == 0 and cdx > -1 
        if player_free_ahead(M, obj, speed, dy)  then return speed, dy
        if player_free_ahead(M, obj, speed, 0) and player_free_eventually(M, obj, speed, dy) then return speed, 0
    if dx == 0 and cdx < 1 
        if player_free_ahead(M, obj, -speed, dy)  then return -speed, dy
        if player_free_ahead(M, obj, -speed, 0) and player_free_eventually(M, obj, -speed, dy)  then return -speed, 0
    if dy == 0 and cdy < 1
        if player_free_ahead(M, obj, dx, -speed)  then return dx, -speed
        if player_free_ahead(M, obj, 0, -speed) and player_free_eventually(M, obj, dx, -speed) then return 0, -speed
    if dy == 0 and cdy > -1
        if player_free_ahead(M, obj, dx, speed) then return dx, speed
        if player_free_ahead(M, obj, 0, speed) and player_free_eventually(M, obj, dx, speed) then return 0, speed
    -- Handle cases where both dimensions are non-0:
    if dx ~= 0 and dy ~= 0
        if player_free_ahead(M, obj, 0, dy) then return 0, dy
        if player_free_ahead(M, obj, dx, 0) then return dx, 0
    -- No valid direction found:
    return 0,0

player_perform_move = (M, obj, dx, dy) ->
    if dx == 0 and dy == 0
        return 0,0
    if obj.stats.cooldowns.move_cooldown > 0
        return 0,0
    as = obj.action_state
    if as.last_dir_x ~= dx or as.last_dir_y ~= dy
        as.constraint_dir_x, as.constraint_dir_y = dx, dy
        as.last_dir_x, as.last_dir_y = dx, dy
    for speed=obj.stats.move_speed,1,-1
        dx, dy = player_adjust_direction(M, obj, dx, dy, as.constraint_dir_x, as.constraint_dir_y, speed)
        if dx ~= 0 or dy ~= 0
            break
    -- Tighten the constraints
    if as.constraint_dir_x == 0 then as.constraint_dir_x = dx
    if as.constraint_dir_y == 0 then as.constraint_dir_y = dy
    if dx == 0 and dy == 0
        return 0,0
    -- Perform the move
    -- Use Pythagorean theorem:
    mag = math.sqrt(dx*dx + dy*dy)
    if mag > obj.stats.move_speed
        dx, dy = dx/mag*obj.stats.move_speed, dy/mag*obj.stats.move_speed
    obj.x, obj.y = obj.x + dx, obj.y + dy
    -- Moving precludes resting:
    obj.frame += 0.25
    obj.stats.is_resting = false
    return dx, dy

player_perform_action = (M, obj, action) ->
    S, A = obj.stats, obj.stats.attack
    -- Rest only if needed:
    S.is_resting = false
    -- Handling resting due to staying-put
    if S.cooldowns.rest_cooldown <= 0
        needs_hp = (S.hp < S.max_hp and S.hp_regen > 0)
        needs_mp = (S.mp < S.max_mp and S.mp_regen > 0)
        if needs_hp or needs_mp
            -- Rest if we can, and if its useful
            S.is_resting = true

    -- Resolve any special actions queued for this frame
    if action.action_type == game_actions.ACTION_USE_WEAPON
        e = M.objects\get(action.id_target)
        if e and S.cooldowns.action_cooldown <= 0 and util_geometry.object_distance(obj, e) <= A.range
            obj\queue_weapon_attack(action.id_target)

    -- Finally, resolve the movement component of the action
    id_player, step_number, dx, dy = game_actions.unbox_move_component(action)
    assert(id_player == obj.id_player)
    assert(step_number == M.gamestate.step_number)
    return player_perform_move(M, obj, dx, dy)

player_move_with_velocity = (M, obj, vx, vy) ->
    mag = math.sqrt(vx*vx + vy*vy)
    player_action_move(M, obj, vx / mag, vy / mag, mag)

-- Step event

-- Exported
-- Step a player for a single tick of the time
-- M: The current map
player_step = (M, obj) ->
    -- Set up directions of player
    action = M.gamestate.get_action(obj.id_player)
    if action
        dx, dy = player_perform_action(M, obj, action)
    -- Ensure player does not move in RVO
    obj\set_rvo(M, 0,0, 2, 20)

MAX_FUTURE_STEPS = 0

FLOOD_FILL = FloodFillPaths.create()
PATHING_TO_MOUSE = false
PATHING_MAP = nil
PATH_X, PATH_Y = nil,nil

_set_for_map = (M) ->
    if M ~= PATHING_MAP
        seen = M.player_seen_map(M.gamestate.local_player_id)
        FLOOD_FILL\set_map(M.tilemap, seen)
        PATHING_TO_MOUSE = false
        PATHING_MAP = M
        PATH_X, PATH_Y = nil,nil

-- Exported
-- Handle keyboard and mouse input for a single frame, for this player
-- M: The current map
player_handle_io = (M, obj) ->
    _set_for_map(M)
    G = M.gamestate
    step_number = G.step_number

    while G.get_action(obj.id_player, step_number) 
        -- We already have an action for this frame, think forward
        step_number += 1
        if step_number > G.step_number + MAX_FUTURE_STEPS
            -- We do not want to queue up a huge amount of actions to be sent
            return

    if user_io.mouse_left_down()
        PATHING_TO_MOUSE = true
        PATH_X, PATH_Y = Display.mouse_game_xy()
        dx,dy = PATH_X - obj.x, PATH_Y - obj.y
        dist = math.sqrt(dx*dx + dy*dy)
        dx, dy = dx/dist, dy/dist
        seen = M.player_seen_map(M.gamestate.local_player_id)
        while dist >= 32
            was_seen = seen\get(math.ceil(PATH_X/32), math.ceil(PATH_Y/32))
            if was_seen and not M.tile_check(obj, PATH_X - obj.x, PATH_Y - obj.y, 2)
                break
            PATH_X, PATH_Y = PATH_X - dx*32, PATH_Y - dy*32
            dist -= 32
        -- radius = math.max(math.abs(mx-obj.x), math.abs(my - obj.y))
        FLOOD_FILL\update(PATH_X, PATH_Y, 900)

    dx,dy=0,0

    if (user_io.key_down "K_UP") or (user_io.key_down "K_W") 
        dy = -obj.speed
    elseif (user_io.key_down "K_DOWN") or (user_io.key_down "K_S") 
        dy = obj.speed
    if (user_io.key_down "K_RIGHT") or (user_io.key_down "K_D") 
        dx = obj.speed
    elseif (user_io.key_down "K_LEFT") or (user_io.key_down "K_A") 
        dx = -obj.speed

    -- Arrow keys override mouse movement
    if dx == 0 and dy == 0 and PATHING_TO_MOUSE
        dist = math.max(math.abs(PATH_X-obj.x), math.abs(PATH_Y-obj.y))
        -- Are we 'close enough'?
        if dist < obj.speed
            PATHING_TO_MOUSE = false
        x1,y1,x2,y2 = util_geometry.object_bbox(obj)
        dx, dy = FLOOD_FILL\interpolated_direction(math.ceil(x1),math.ceil(y1),math.floor(x2),math.floor(y2), obj.speed)
        if dx == 0 and dy == 0
            PATHING_TO_MOUSE = false
    else
        PATHING_TO_MOUSE = false

    action = nil
    if user_io.key_down "K_Y"
        e = obj\nearest_enemy(M)
        if e 
            action = game_actions.make_weapon_action G.game_id, obj, step_number, e.id, dx, dy
    -- No special action done?
    if not action 
        action = game_actions.make_move_action G.game_id, obj, step_number, dx, dy
    G.queue_action(action)
    if G.net_handler
        -- Send last two unacknowledged actions (included the one just queued)
        G.net_handler\send_unacknowledged_actions(1)

    if user_io.key_pressed "K_P"
        Projectile.create M, {
            x: obj.x
            y: obj.y
            vx: -1
            vy: -1
            action: "TODO"
        }

return {:player_step, :player_handle_io, :player_perform_action}