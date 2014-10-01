
import util_movement, util_geometry, util_draw, game_actions from require "core"

import ObjectBase, CombatObjectBase, Player, NPC, Projectile, NPC_RANDOM_WALK, NPC_CHASING from require '@map_object_types'

resources = require 'resources'
statsystem = require 'statsystem'
modules = require 'core.data'
user_io = require 'user_io'

THRESH_MIN_DIST = 2

DIST_SORT = (a,b) -> a.__dist < b.__dist
TABLE_CACHED = {}
npc_list = (M) ->
    table.clear(TABLE_CACHED)
    for npc in *M.npc_list
        append TABLE_CACHED, npc
    return TABLE_CACHED

-- Exported
-- Step a player for a single tick of the time
-- M: The current map
npc_step_all = (M) ->

    -- Try to force synchronization
    M.rvo_world\clear()
    for obj in *M.combat_object_list
        obj.id_rvo = M.rvo_world\add_instance(obj.x, obj.y, obj.radius, obj.stats.move_speed)
    -----

    -- Set up directions of all NPCs
    npcs = [npc for npc in *M.npc_list]
    for obj in *npcs
        -- Disable player resting near danger:
        for p in *M.player_list
            if util_geometry.object_distance(obj, p) < 300 and p\can_see(obj)
                p.stats.cooldowns.rest_cooldown = math.max(p.stats.cooldowns.rest_cooldown, statsystem.REST_COOLDOWN)
                p.stats.is_resting = false

        dx, dy = 0,0
        p, dist = obj\nearest_enemy(M)
        S, A = obj.stats, obj.stats.attack
        speed = S.move_speed
        can_act = (S.cooldowns.action_cooldown <= 0)
        can_move = (S.cooldowns.move_cooldown <= 0)

        if not p or dist > obj.npc_type.max_chase_dist
            obj.ai_target = false
            obj.ai_action = NPC_RANDOM_WALK
        elseif dist <= obj.npc_type.min_chase_dist
            obj.ai_target = p
            obj.ai_action = NPC_CHASING
        -- Are we bumbling about randomly?
        if obj.ai_action == NPC_RANDOM_WALK
            if can_move 
                -- Random heading
                -- Take last angle, apply random turn
                dir = math.atan2(obj.ai_vy, obj.ai_vx) + M.rng\randomf(-math.pi/10, math.pi/10)
                dx, dy = math.cos(dir) * speed/2, math.sin(dir) * speed/2
            -- Don't consider below logic
        -- Resolve actions, for near-enough enemies
        elseif can_act and (dist <= A.range)
            obj\queue_weapon_attack(p.id)
        elseif can_move
            x1,y1,x2,y2 = util_geometry.object_bbox(obj)
            dx, dy = p.paths_to_player\interpolated_direction(math.ceil(x1),math.ceil(y1),math.floor(x2),math.floor(y2), speed)
        obj\set_rvo(M, dx, dy)
        -- Temporary storage, just for this function:
        obj.ai_vx, obj.ai_vy = dx, dy
        obj.__dist = dist
        obj.__moved = false

    -- Run the collision avoidance algorithm
    M.rvo_world\step()

    -- Sort NPCs by distance to their target
    table.sort npcs, DIST_SORT

    -- Move NPCs
    for obj in *npcs
        local vx, vy
        vx, vy = obj\get_rvo_velocity(M)
        -- Are we close to a wall?
        if M.tile_check(obj, vx, vy, obj.radius)
            -- Then ignore RVO, problematic near walls
            vx, vy = obj.ai_vx, obj.ai_vy
        -- Otherwise, proceed according to RVO

        -- If we are on direct course with a wall, adjust heading:
        if M.tile_check(obj, vx, vy)
            -- Try random rotations (rationale: guarantee to preserve momentum, and not move directly backwards):
            case = M.rng\random(0,4)
            if case==0 and not M.tile_check(obj, -vy, vx) then vx, vy = -vy, vx
            elseif case==1 and not M.tile_check(obj, vy, vx) then vx, vy = vy, vx
            elseif case==2 and not M.tile_check(obj, vy, -vx) then vx, vy = vy, -vx
            elseif case==3 and not M.tile_check(obj, -vy, -vx) then vx, vy = -vy, -vx
            else vx, vy = 0,0
            -- Update for turning logic (if random walk)
            obj.ai_vx, obj.ai_vy = vx, vy

        -- Advance forward if we don't hit a solid object
        collided = false
        for col_id in *M.object_query(obj, vx, vy, obj.radius)
            o = M.col_id_to_object[col_id]
            if o == obj.ai_target or (getmetatable(o) == NPC and o.ai_target == obj.ai_target and o.__moved)
                collided = true
                break

        if not collided
            obj.x += vx
            obj.y += vy
            obj\sync_col(M)
        obj.__moved = true

return {:npc_step_all}
