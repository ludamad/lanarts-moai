
import camera, util_movement, util_geometry, util_draw, game_actions from require "core"
import StatUtils from require "stats.stats"
import StatContext from require "stats"
import default_cooldown_table, reset_rest_cooldown from require "stats.stats.CooldownTypes"

import ObjectBase, CombatObjectBase, Player, NPC, Projectile from require '@map_object_types'

resources = require 'resources'
modules = require 'core.data'
user_io = require 'user_io'

-- Exported
-- Step a player for a single tick of the time
-- M: The current map
npc_step_all = (M) ->
    -- Set up directions of all NPCs
    for obj in M.npc_iter()
        p = M.closest_player(obj)
        if p
            x1,y1,x2,y2 = util_geometry.object_bbox(obj)
            dx, dy = p.paths_to_player\interpolated_direction(x1,y1,x2,y2, obj.speed)
            obj\set_rvo(M, dx, dy)

    -- Run the collision avoidance algorithm
    M.rvo_world\step()

    -- Move NPCs
    for obj in M.npc_iter()
        local vx, vy
        -- Are we close to a wall?
        if M.tile_check(obj, 0, 0, obj.radius + 8)
            -- Then ignore RVO, problematic near walls
            vx, vy = obj\get_rvo_heading(M)
        else
            -- Otherwise, proceed according to RVO
            vx, vy = obj\get_rvo_velocity(M)
        -- Advance forward if we don't hit a solid object
        if not M.tile_check(obj, vx, vy) and not M.object_check(obj, vx, vy, obj.radius / 2)
            obj.x += vx
            obj.y += vy

    -- Resolve actions
    for obj in M.npc_iter()
        obj\perform_action(M)

return {:npc_step_all}