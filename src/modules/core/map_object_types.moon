
BoolGrid = require 'BoolGrid'
user_io = require 'user_io'
data = require "core.data"
import camera, util_draw from require "core"
import FieldOfView, FloodFillPaths, util_stats, util_geometry from require "core"

import Relations, RaceType, MonsterType, StatContext, ActionContext from require "stats"
import StatUtils from require "stats.stats"
import add_hp, add_mp, add_cooldown, set_cooldown, temporary_add, permanent_add from require "stats.StatContext"

make_stats = (M, race, name, _class) ->
    stats = race.on_create(name)
    if _class
        context = StatContext.stat_context_create(stats)
        _class\on_map_init(context)
    return stats

-- Object lifecycle:
--  Object creation:
--   .init(args) -> Create the game object with parameters.
--   .register(M) -> Setup the game object with the various
--     game subsystems.
--  During gameplay:
--   .step(M)
--   .post_step(M)
--  Object on/off-screen (TODO For optimization only):
--   .register_prop/.unregister_prop
--  Object destruction:
--   .unregister()

-- Priority increment -- note, MUST be an integer
-- Enough to increment the different parts of a player
PRIORITY_INCR = 25

ObjectBase = with newtype()
	---------------------------------------------------------------------------
	-- Core protocol
	---------------------------------------------------------------------------
    .alpha = 1.0
    .priority = 0
	.init = (M, args) =>
		@x, @y, @radius = args.x, args.y, args.radius or 16
        @target_radius, @solid = (args.target_radius or args.radius or 16), args.solid or false
        @map = M
        -- Register into world , and store the instance table ID
        @id = M.objects\add(@)
        @id_col = 0 -- Not all objects need to be part of the collision set
        @frame = 0
        @remove_queued = false

    .queue_remove = (M) =>
        if not @remove_queued
            append M.removal_list, @
            @remove_queued = false

    .remove = (M) =>
        M.objects\remove(@)

    .pre_draw = (V) => 
        -- Last number is priority
        @sprite\put_prop(V.object_layer, @x, @y, @frame, @priority + @y * PRIORITY_INCR, @alpha)

    .draw = (V) => nil

    -- Note: Does not sync props
    .sync = (M) => nil


draw_statbar = (x,y,w,h, ratio) ->
    MOAIGfxDevice.setPenColor(1, 0, 0)
    MOAIDraw.fillRect(x,y,x+w,y+h)
    MOAIGfxDevice.setPenColor(0, 1, 0)
    MOAIDraw.fillRect(x,y,x+w*ratio,y+h)

CombatObjectBase = with newtype {parent: ObjectBase}
    .init = (M, args) =>
        args.solid = true
        ObjectBase.init(@, M, args)
        @speed = args.speed
        -- The collision detection component
        -- Subsystem registration
        @id_col = M.collision_world\add_instance(@x, @y, @radius, @target_radius, @solid)
        M.col_id_to_object[@id_col] = @
        -- The collision evasion component
        @id_rvo = M.rvo_world\add_instance(@x, @y, @radius, @speed)
        append M.combat_object_list, @

    .get.stats = () => @stat_context.derived

    -- Call by child class, separated from init() for cleanliness
    .init_stats = (base_stats, unarmed_action, race = false) =>
        -- Set up stats
        @stat_context = util_stats.stat_context_create(base_stats, @, unarmed_action, race)
    .remove = (M) =>
        ObjectBase.remove(@, M)
        M.collision_world\remove_instance(@id_col)
        M.rvo_world\remove_instance(@id_rvo)
        M.col_id_to_object[@id_col] = nil
        table.remove_occurrences M.combat_object_list, @

    .stat_context_copy = () => @stat_context\copy()
    -- Subsystem synchronization
    .sync_col = (M) =>
        M.collision_world\update_instance(@id_col, @x, @y, @radius, @target_radius, @solid)
    .sync = (M) =>
        ObjectBase.sync(@, M)
        @sync_col(M)

    -- Set RVO heading
    .set_rvo = (M, dx, dy) =>
        maxspeed = if (dx == 0 and dy == 0) then 0 else @speed
        M.rvo_world\update_instance(@id_rvo, @x, @y, @radius, maxspeed, dx, dy)
    .get_rvo_velocity = (M) =>
        return M.rvo_world\get_velocity(@id_rvo)
    .get_rvo_heading = (M) =>
        return M.rvo_world\get_preferred_velocity(@id_rvo)

    -- Stat system hook:
    .on_death = (M, attacker) =>
        @queue_remove(M)

    .draw = (V) =>

        healthbar_offsety = 20
        if @target_radius > 16
            healthbar_offsety = @target_radius + 8
        if @stats.hp < @stats.max_hp
            x,y = @x - 10, @y - healthbar_offsety
            w, h = 20, 5
            draw_statbar(x,y,w,h, @stats.hp / @stats.max_hp)

-- NB: Controlling logic in map_logic

Vision = with newtype()
    .init = (M, line_of_sight) =>
        @line_of_sight = line_of_sight
        @seen_tile_map = BoolGrid.create(M.tilemap_width, M.tilemap_height, false)
        @fieldofview = FieldOfView.create(M.tilemap, @line_of_sight)
        @prev_seen_bounds = {0,0,0,0}
        @current_seen_bounds = {0,0,0,0}
    .update = (x, y) =>
        @fieldofview\calculate(x, y)
        @fieldofview\update_seen_map(@seen_tile_map)
        @prev_seen_bounds = @current_seen_bounds
        @current_seen_bounds = @fieldofview\tiles_covered()

Player = with newtype {parent: CombatObjectBase}
    .init = (M, args) =>
        logI("Player::init")
        CombatObjectBase.init(@, M, args)
        @race = args.race
        @class = args.class
        @name = args.name

        -- Create the stats object for the player
        @init_stats(make_stats(M, args.race, args.name, args.class), args.race.unarmed_action, args.race)
        logI("Player::init stats created")

        add_hp @stat_context, -50
        @vision_tile_radius = 6
        @player_path_radius = 200
        @id_player = args.id_player
        @is_resting = false
        @vision = Vision.create(M, @vision_tile_radius)
        @paths_to_player = FloodFillPaths.create(M.tilemap)
        append M.player_list, @
        logI("Player::init complete")

    .remove = (M) =>
        CombatObjectBase.remove(@, M)
        table.remove_occurrences M.player_list, @

    .pre_draw = (V) => 
        -- Last number is priority
        index = (@id_player-1) %2 +1
        @stat_context\put_avatar_sprite(V.object_layer, @x, @y, @frame, @priority + @y * PRIORITY_INCR)
        -- CombatObjectBase.pre_draw(@, V)

    .nearest_enemy = (M) =>
        min_obj,min_dist = nil,math.huge
        for obj in *M.npc_list
            dist = util_geometry.object_distance(@, obj)
            if dist < min_dist
                min_obj = obj
                min_dist = dist
        return min_obj

    .attack = (M) =>
        o = @nearest_enemy(M)
        if o
            @stat_context\use_weapon o.stat_context

    .can_see = (obj) =>
        return @vision.fieldofview\circle_visible(obj.x, obj.y, obj.radius)

    .sync = (M) =>
        CombatObjectBase.sync(@, M)
        @vision\update(@x/M.tile_width, @y/M.tile_height)
        @paths_to_player\update(@x, @y, @player_path_radius)

NPC = with newtype {parent: CombatObjectBase}
    .init = (M, args) =>
        CombatObjectBase.init(@, M, args)
        append M.npc_list, @
        @npc_type = MonsterType.lookup(args.type)
        @sprite = data.get_sprite(args.type)
        @init_stats(StatUtils.stat_clone(@npc_type.base_stats), @npc_type.unarmed_action)

    .nearest_enemy = (M) =>
        min_obj,min_dist = nil,math.huge
        for obj in *M.player_list do
            dist = util_geometry.object_distance(@, obj)
            if dist < min_dist
                min_obj = obj
                min_dist = dist
        return min_obj, min_dist
    .perform_action = (M) =>
        min_obj, min_dist = @nearest_enemy(M)
        if min_obj and @stat_context\can_use_weapon(min_obj.stat_context)
            @stat_context\use_weapon(min_obj.stat_context)

    .remove = (M) =>
        CombatObjectBase.remove(@, M)
        table.remove_occurrences M.npc_list, @
-- Spell and attack objects

-- 'Step' is called in animation phase, in map_logic.moon
Animation = with newtype {parent: ObjectBase}
    .priority = 1
    .init = (M, args) =>
        ObjectBase.init(@, M, args)
        @vx = args.vx or 0
        @vy = args.vy or 0
        @alpha = args.alpha or 1.0
        @sprite = args.sprite
        append M.animation_list, @

    .remove = (M) =>
        ObjectBase.remove(@, M)
        table.remove_occurrences M.animation_list, @

    .step = (M) =>
        @x += @vx
        @y += @vy
        @alpha = math.max(@alpha - 0.05, 0)
        if @alpha == 0
            @queue_remove(M)

-- 'Step' is called in projectile phase, in map_logic.moon
Projectile = with newtype {parent: ObjectBase}
    .priority = 1
    .init = (M, args) =>
        ObjectBase.init(@, M, args)
        @sprite = args.sprite
        @vx = args.vx
        @vy = args.vy
        @action = args.action
        append M.projectile_list, @

    .step = (M) =>
        @x += @vx
        @y += @vy

        for col_id in *M.object_query(@)
            obj = M.col_id_to_object[col_id]
            if getmetatable(obj) == NPC
                Animation.create M, {
                    sprite: @sprite
                    x: @x
                    y: @y
                    vx: @vx
                    vy: @vy
                }
                @queue_remove(M)
                return
        if M.tile_check(@)
            @queue_remove(M)

    .remove = (M) =>
        ObjectBase.remove(@, M)
        table.remove_occurrences M.projectile_list, @

return {:ObjectBase, :CombatObjectBase, :Player, :NPC, :Projectile}
