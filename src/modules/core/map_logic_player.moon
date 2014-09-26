
import util_movement, util_geometry, util_draw, game_actions from require "core"
statsystem = require "statsystem"

import ObjectBase, CombatObjectBase, Player, NPC, Projectile from require '@map_object_types'

resources = require 'resources'
modules = require 'core.data'
user_io = require 'user_io'

-- Special movement helper

-- 'px' and 'py' are the 'projection' displacements
-- Projections are collision checks to determine how best to skirt around walls we may eventually pass
player_check_for_slide = (L, dx, dy, px, py, checkdx, checkdy) =>
    if (not L.tile_check @, checkdx + dx, checkdy + dy) and (not L.tile_check @, checkdx + px, checkdy + py) 
        return true
    return false

-- Expectation: checkdx & checkdy are dx & dy passed through _biased_round
-- Returns real dx, dy if step succeeded; nil if step failed.
player_look_ahead_step  = (L, dist, dir_pref, dx, dy, currdx, currdy) =>
    -- Control 'p' -- the 'projection' factor
    -- Projections are collision checks to determine how best to skirt around walls we may eventually pass
    PROJECT_STEP = 8
    PROJECT_MAX = 32

    -- This logic is slightly 'duplicated', but there isn't an efficient
    -- way I could think of for handling different dimensions uniformly
    if not L.tile_check @, currdx + dx, currdy + dy
        return dx, dy
    if dx == 0
        p = PROJECT_MAX
        while p > 0
            if dir_pref == 0 and player_check_for_slide(@, L, dy, 0, p*dy, p*dy, currdx, currdy)
                return dy, 0
            if dir_pref == 1 and player_check_for_slide(@, L, -dy, 0, -p*dy, p*dy, currdx, currdy)
                return -dy, 0
            p -= PROJECT_STEP
    if dy == 0
        p = PROJECT_MAX
        while p > 0
            if dir_pref == 0 and player_check_for_slide(@, L, 0, dx, p*dx, p*dx, currdx, currdy, p)
                return 0, dx
            if dir_pref == 1 and player_check_for_slide(@, L, 0, -dx ,p*dx, -p*dx, currdx, currdy, p)
                return 0, -dx
            p -= PROJECT_STEP
    if dx ~= 0 
        dx = (if dx > 0 then dist else -dist)
        if not L.tile_check @, currdx + dx, currdy 
            return dx, 0
    if dy ~= 0
        dy = (if dy > 0 then dist else -dist)
        if not L.tile_check @, currdx, currdy + dy
            return 0, dy
    return nil

signum = (x) -> 
    if x > 0 then 1 
    elseif x < 0 then -1 
    else 0

player_free_ahead = (M, dx, dy) => (not M.tile_check @, dx, dy) -- and (not M.tile_check @, dx*4, dy*4) 
player_free_eventually = (M, dx, dy) => 
    dx, dy = signum(dx), signum(dy)
    for i=(@stats.move_speed+1),48
        if player_free_ahead(@, M, dx*i, dy*i)
            return true
    return false

-- cdx and cdy: If 0, any direction not opposite to dx, dy (respectively) OK. If not 0, only 0 OK.
player_adjust_direction = (M, dx, dy, cdx, cdy, speed) =>
    if not M.tile_check @, dx, dy
        return dx, dy
    -- Try to find the best choice, within constraints:
    -- Handle cases where one dimension is 0:
    if dx == 0 and cdx > -1 
        if player_free_ahead(@, M, speed, dy)  then return speed, dy
        if player_free_ahead(@, M, speed, 0) and player_free_eventually(@, M, speed, dy) then return speed, 0
    if dx == 0 and cdx < 1 
        if player_free_ahead(@, M, -speed, dy)  then return -speed, dy
        if player_free_ahead(@, M, -speed, 0) and player_free_eventually(@, M, -speed, dy)  then return -speed, 0
    if dy == 0 and cdy < 1
        if player_free_ahead(@, M, dx, -speed)  then return dx, -speed
        if player_free_ahead(@, M, 0, -speed) and player_free_eventually(@, M, dx, -speed) then return 0, -speed
    if dy == 0 and cdy > -1
        if player_free_ahead(@, M, dx, speed) then return dx, speed
        if player_free_ahead(@, M, 0, speed) and player_free_eventually(@, M, dx, speed) then return 0, speed
    -- Handle cases where both dimensions are non-0:
    if dx ~= 0 and dy ~= 0
        if player_free_ahead(@, M, 0, dy) then return 0, dy
        if player_free_ahead(@, M, dx, 0) then return dx, 0
    -- No valid direction found:
    return 0,0

-- Pseudomethod
player_perform_move = (M, dx, dy) =>
    if dx == 0 and dy == 0
        return
    dx, dy = dx * @stats.move_speed, dy * @stats.move_speed
    as = @action_state
    if as.last_dir_x ~= dx or as.last_dir_y ~= dy
        as.constraint_dir_x, as.constraint_dir_y = dx, dy
        as.last_dir_x, as.last_dir_y = dx, dy
    for speed=@stats.move_speed,1,-1
        dx, dy = player_adjust_direction(@, M, dx, dy, as.constraint_dir_x, as.constraint_dir_y, speed)
        if dx ~= 0 or dy ~= 0
            break
    -- Tighten the constraints
    if as.constraint_dir_x == 0 then as.constraint_dir_x = dx
    if as.constraint_dir_y == 0 then as.constraint_dir_y = dy
    -- Perform the move
    -- Use Pythagorean theorem:
    mag = math.sqrt(dx*dx + dy*dy)
    if mag > @stats.move_speed
        dx, dy = dx/mag*@stats.move_speed, dy/mag*@stats.move_speed
    @x, @y = @x + dx, @y + dy
    @stats.cooldowns.rest_cooldown = math.max(@stats.cooldowns.rest_cooldown, statsystem.REST_COOLDOWN)

player_perform_action = (M, obj, action) ->
    -- Resolve any special actions queued for this frame
    if action.action_type == game_actions.ACTION_USE_WEAPON
        obj\attack(M)

    -- Finally, resolve the movement component of the action
    id_player, step_number, dx, dy = game_actions.unbox_move_component(action)
    assert(id_player == obj.id_player)
    assert(step_number == M.gamestate.step_number)
    player_perform_move(obj, M, dx, dy)

player_move_with_velocity = (M, vx, vy) =>
    mag = math.sqrt(vx*vx + vy*vy)
    player_action_move(@, M, vx / mag, vy / mag, mag)

-- Step event

-- Exported
-- Step a player for a single tick of the time
-- M: The current map
player_step = (M) =>
    S = @stats

    -- Set up directions of player
    action = M.gamestate.get_action(@id_player)
    if action
        player_perform_action(M, @, action)
    -- Ensure player does not move in RVO
    @set_rvo(M, 0,0, 2, 20)

MAX_FUTURE_STEPS = 0

-- Exported
-- Handle keyboard and mouse input for a single frame, for this player
-- M: The current map
player_handle_io = (M) =>
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

    -- if G.gametype ~= "single_player"
    --     if dx==0 and dy==0 then 
    --         dx,dy = rdx,rdy
    --         if _RNG\random(15) == 1
    --             rdx,rdy = _RNG\random(-1,2),_RNG\random(-1,2)

    local action
    if user_io.key_pressed "K_Y"
        action = game_actions.make_weapon_action @, step_number, dx, dy
    else
        action = game_actions.make_move_action @, step_number, dx, dy
    G.queue_action(action)
    -- if G.net_handler
        -- Send last two unacknowledged actions (included the one just queued)
        -- G.net_handler\send_unacknowledged_actions(2)

    if user_io.key_pressed "K_P"
        Projectile.create M, {
            x: @x
            y: @y
            vx: -1
            vy: -1
            action: "TODO"
        }

return {:player_step, :player_handle_io, :player_perform_action}