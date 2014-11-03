
import util_movement, util_geometry, util_draw, game_actions, FloodFillPaths from require "core"
statsystem = require "statsystem"
import Display from require "ui"
data = require "core.data"

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
    found = false
    for speed=obj.stats.move_speed,1,-1
        mag = math.sqrt(dx*dx + dy*dy)
        ndx, ndy = player_adjust_direction(M, obj, dx/mag*speed, dy/mag*speed, as.constraint_dir_x, as.constraint_dir_y, speed)
        if ndx ~= 0 or ndy ~= 0
            dx,dy = ndx, ndy
            found = true
            break
    if not found then return
    -- Tighten the constraints
    if as.constraint_dir_x == 0 then as.constraint_dir_x = dx
    if as.constraint_dir_y == 0 then as.constraint_dir_y = dy
    if dx == 0 and dy == 0
        return 0,0
    -- Perform the move
    -- Use Pythagorean theorem:
    dist = math.sqrt(dx*dx + dy*dy)
    if dist > obj.stats.move_speed
        dx, dy = dx/dist*obj.stats.move_speed, dy/dist*obj.stats.move_speed
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
        needs_ep = (S.ep < S.max_ep and S.ep_regen > 0)
        if needs_hp or needs_mp or needs_ep
            -- Rest if we can, and if its useful
            S.is_resting = true

    -- Resolve any special actions queued for this frame
    if action.action_type == game_actions.ACTION_USE_WEAPON
        e = M.objects\get(action.id_target)
        if e and S.cooldowns.action_cooldown <= 0 and util_geometry.object_distance(obj, e) <= A.range
            obj\queue_weapon_attack(M, action.id_target)

    -- Finally, resolve the movement component of the action
    id_player, step_number, dx, dy, will_sprint = game_actions.unbox_move_component(action)
    assert(id_player == obj.id_player)
    assert(step_number == M.gamestate.step_number)

    -- Sprint only if requested:
    S.will_sprint_if_can = (will_sprint)
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
    G = M.gamestate
    action = G.actions\get_action(obj.id_player, G.step_number)
    logS "Player #{obj.id_player} #{M.gamestate.step_number}", action
    dx, dy = player_perform_action(M, obj, action)

MAX_FUTURE_STEPS = 0

FLOOD_FILL = FloodFillPaths.create()
PATHING_TO_MOUSE = false
PATHING_MAP = nil
PATH_X, PATH_Y = nil,nil
ATTACK_MOVE = false

SELECTION_SPRITE = data.get_sprite("selection")
-- TODO Find a better home for the state above
draw_player_target = (M) ->
    if PATHING_TO_MOUSE and PATH_X and PATH_Y and PATHING_MAP == M
        r,g,b = 0.2,1,0.2
        if ATTACK_MOVE
            r,g,b = 1,0.2,0.2
        SELECTION_SPRITE\draw(math.floor(PATH_X/32)*32, math.floor(PATH_Y/32)*32,1,0.5, 0,0, r,g,b)

_set_for_map = (M) ->
    if M ~= PATHING_MAP
        seen = M.player_seen_map(M.gamestate.local_player_id)
        FLOOD_FILL\set_map(M.tilemap, seen)
        PATHING_TO_MOUSE = false
        PATHING_MAP = M
        PATH_X, PATH_Y = nil,nil


REST_COUNT = 0
all_players_resting = (G) ->
    for {:object} in *G.players
        if not object.stats.is_resting
            return false
    return true
-- Exported
-- Handle keyboard and mouse input for a single frame, for this player
-- M: The current map
player_handle_io = (M, obj) ->
    _set_for_map(M)
    G = M.gamestate
    step_number = G.step_number

    if all_players_resting(M.gamestate)
        REST_COUNT += 1
    else
        REST_COUNT = 0
    if REST_COUNT >= 5
        MOAISim.setStep(1 / (_SETTINGS.frames_per_second*2) )
    else
        MOAISim.setStep(1 / _SETTINGS.frames_per_second)

    while G.actions\get_action(obj.id_player, step_number) 
        -- We already have an action for this frame, think forward
        step_number += 1
        if step_number > G.step_number + MAX_FUTURE_STEPS
            -- We do not want to queue up a huge amount of actions to be sent
            return

    mx, my = user_io.mouse_xy()
    disp_w, disp_h = Display.display_size()
    mouse_on_sidebar = (mx > disp_w - 150)
    if user_io.mouse_left_down() and not mouse_on_sidebar
        PATHING_TO_MOUSE = true
        ATTACK_MOVE = (user_io.key_down "K_Y")
        PATH_X, PATH_Y = Display.mouse_game_xy()
        dx,dy = PATH_X - obj.x, PATH_Y - obj.y
        dist = math.sqrt(dx*dx + dy*dy)
        dx, dy = dx/dist, dy/dist
        seen = M.player_seen_map(M.gamestate.local_player_id)
        while dist >= 32
            tx, ty = math.ceil(PATH_X / 32), math.ceil(PATH_Y / 32)
            if tx < 1 or tx > M.tilemap_width or ty < 1 or ty > M.tilemap_height
                break
            was_seen = seen\get(tx, ty)
            if was_seen and not M.tile_check(obj, PATH_X - obj.x, PATH_Y - obj.y, 8)
                break
            PATH_X, PATH_Y = PATH_X - dx*32, PATH_Y - dy*32
            dist -= 32
        -- radius = math.max(math.abs(mx-obj.x), math.abs(my - obj.y))
        tx, ty = math.ceil(PATH_X / 32), math.ceil(PATH_Y / 32)
        if tx < 1 or tx > M.tilemap_width or ty < 1 or ty > M.tilemap_height
            PATHING_TO_MOUSE = false
        else
            FLOOD_FILL\update(PATH_X, PATH_Y, 900)


    dx,dy=0,0

    if (user_io.key_down "K_UP") or (user_io.key_down "K_W") 
        dy = -obj.stats.move_speed
    elseif (user_io.key_down "K_DOWN") or (user_io.key_down "K_S") 
        dy = obj.stats.move_speed
    if (user_io.key_down "K_RIGHT") or (user_io.key_down "K_D") 
        dx = obj.stats.move_speed
    elseif (user_io.key_down "K_LEFT") or (user_io.key_down "K_A") 
        dx = -obj.stats.move_speed

    -- Arrow keys override mouse movement
    if dx == 0 and dy == 0 and PATHING_TO_MOUSE
        dist = math.max(math.abs(PATH_X-obj.x), math.abs(PATH_Y-obj.y))
        -- Are we 'close enough'?
        if dist < obj.stats.move_speed
            PATHING_TO_MOUSE = false
        x1,y1,x2,y2 = util_geometry.object_bbox(obj)
        dx, dy = FLOOD_FILL\interpolated_direction(math.ceil(x1),math.ceil(y1),math.floor(x2),math.floor(y2), obj.stats.move_speed)
        if dx == 0 and dy == 0
            PATHING_TO_MOUSE = false
    else
        -- if dx == 0 and dy == 0 and user_io.mouse_left_down() and not mouse_on_sidebar
        --     mx, my = Display.mouse_game_xy()
        --     dx, dy = util_geometry.towards(obj.x, obj.y, mx, my, obj.stats.move_speed)

        PATHING_TO_MOUSE = false

    will_sprint = (user_io.key_down "K_U")

    action = nil
    if user_io.key_down "K_Y" or (PATHING_TO_MOUSE and ATTACK_MOVE)
        e = obj\nearest_enemy(M)
        if e and obj\can_see(e)
            if dx == 0 and dy == 0 and util_geometry.object_distance(e, obj) > obj.stats.attack.range
                dx, dy = util_geometry.object_towards(obj, e, obj.stats.move_speed)
            action = game_actions.make_weapon_action G.game_id, obj, step_number, e.id, dx, dy, will_sprint

    -- No special action done?
    if not action 
        action = game_actions.make_move_action G.game_id, obj, step_number, dx, dy, will_sprint
    G.actions\queue_action(action)
    if G.net_handler
        -- Send last two unacknowledged actions (included the one just queued)
        G.net_handler\send_unacknowledged_actions()


return {:player_step, :player_handle_io, :player_perform_action, :draw_player_target}
