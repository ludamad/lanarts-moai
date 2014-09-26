
BoolGrid = require 'BoolGrid'
user_io = require 'user_io'
data = require "core.data"
statsystem = require "statsystem"
import util_draw, TileMap from require "core"
import Display from require "ui"
import FieldOfView, FloodFillPaths, util_geometry from require "core"

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

ATTACK_ANIMATION_PRIORITY = 98 -- Lower means more 'on top'
PROJECTILE_PRIORITY = 99
-- The base priority for combat objects, will never fall below 100 after adjustments.
BASE_PRIORITY = 101
FEATURE_PRIORITY = 102
-- Add Y values * Y_PRIORITY_INCR to adjust the object priority.
Y_PRIORITY_INCR = -(2^-16)

local Animation -- Forward declare, used throughout

ObjectBase = newtype {
	---------------------------------------------------------------------------
	-- Core protocol
	---------------------------------------------------------------------------
    alpha: 1.0
    sprite: false
    priority: 0
	init: (M, args) =>
		@x, @y, @radius = args.x, args.y, args.radius or 16
        @target_radius, @solid = (args.target_radius or args.radius or 16), args.solid or false
        if args.priority then @priority = args.priority
        @map = M
        -- Register into world , and store the instance table ID
        @id = M.objects\add(@)
        @id_col = 0 -- Not all objects need to be part of the collision set
        @frame = 0
        @remove_queued = false

    queue_remove: (M) =>
        if not @remove_queued
            append M.removal_list, @
            @remove_queued = false

    remove: (M) =>
        M.objects\remove(@)

    pre_draw: (V) => 
        -- -- Last number is priority
        -- @sprite\put_prop(Display.game_obj_layer, @x, @y, @frame, @priority + @y * PRIORITY_INCR, @alpha)

    draw: (V, r=1, g=1, b=1) => 
        if @sprite then @sprite\draw(@x, @y, @frame, @alpha, 0.5, 0.5, r, g, b)
    -- Note: Does not sync props
    sync: (M) => nil
}

Feature = newtype {
    parent: ObjectBase
    priority: FEATURE_PRIORITY
    init: (M, args) =>
        if args.solid
            tx, ty = math.floor(args.x/32), math.floor(args.y/32)
            M.tilemap\square_apply({tx, ty}, {add: TileMap.FLAG_SOLID})
            args.solid = false -- Avoid setting solidity on the object itself
        ObjectBase.init(@, M, args)
        @true_sprite = data.get_sprite(args.sprite)
        @sprite = false -- Last seen sprite
        @frame = M.rng\random(1, @true_sprite\n_frames()+1)
    was_seen: () => (@sprite ~= false)
    mark_seen: () => @sprite = @true_sprite
}

draw_statbar = (x,y,w,h, ratio) ->
    MOAIGfxDevice.setPenColor(1, 0, 0)
    MOAIDraw.fillRect(x,y,x+w,y+h)
    MOAIGfxDevice.setPenColor(0, 1, 0)
    MOAIDraw.fillRect(x,y,x+w*ratio,y+h)

CombatObjectBase = newtype {
    parent: ObjectBase
    init: (M, args) =>
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
        @set_priority()

    remove: (M) =>
        ObjectBase.remove(@, M)
        M.collision_world\remove_instance(@id_col)
        M.rvo_world\remove_instance(@id_rvo)
        M.col_id_to_object[@id_col] = nil
        table.remove_occurrences M.combat_object_list, @
    -- Subsystem synchronization
    sync_col: (M) =>
        M.collision_world\update_instance(@id_col, @x, @y, @radius, @target_radius, @solid)
    sync: (M) =>
        ObjectBase.sync(@, M)
        @sync_col(M)

    set_priority: () =>
        @priority = BASE_PRIORITY + Y_PRIORITY_INCR * @y

    -- Set RVO heading
    set_rvo: (M, dx, dy, max_speed = @speed, radius = @radius) =>
        M.rvo_world\update_instance(@id_rvo, @x, @y, radius, max_speed, dx, dy)
    get_rvo_velocity: (M) =>
        return M.rvo_world\get_velocity(@id_rvo)
    get_rvo_heading: (M) =>
        return M.rvo_world\get_preferred_velocity(@id_rvo)

    -- Stat system hook:
    on_death: (M, attacker) =>
        @queue_remove(M)

    _hurt_color_mod: () => 
        -- Derived from experimental tinkering:
        h,H = @stats.cooldowns.hurt_cooldown, statsystem.HURT_COOLDOWN
        if h == 0 then return 1
        elseif h < H/2 then return h/H*0.35 + 0.3
        else return (H - h)*0.07 + 0.3

    draw: (V) =>
        hmod = @_hurt_color_mod()
        -- Use hurt cooldown to modify r,g,b values:
        ObjectBase.draw(@, V, 1, hmod, hmod)
        healthbar_offsety = 20
        if @target_radius > 16
            healthbar_offsety = @target_radius + 8
        if @stats.hp < @stats.max_hp
            x,y = @x - 10, @y - healthbar_offsety
            w, h = 20, 5
            draw_statbar(x,y,w,h, @stats.hp / @stats.max_hp)
}

-- NB: Controlling logic in map_logic

Vision = newtype {
    init: (M, line_of_sight) =>
        @line_of_sight = line_of_sight
        @seen_tile_map = BoolGrid.create(M.tilemap_width, M.tilemap_height, false)
        @fieldofview = FieldOfView.create(M.tilemap, @line_of_sight)
        @prev_seen_bounds = {0,0,0,0}
        @current_seen_bounds = {0,0,0,0}
    update: (x, y) =>
        @fieldofview\calculate(x, y)
        @fieldofview\update_seen_map(@seen_tile_map)
        @prev_seen_bounds = @current_seen_bounds
        @current_seen_bounds = @fieldofview\tiles_covered()
}

-- 'State machine'p for player actions
PlayerActionState = newtype {
    init: () =>
        @last_dir_x = 0
        @last_dir_y = 0
        @constraint_dir_x = 0
        @constraint_dir_y = 0
}

Player = newtype {
    parent: CombatObjectBase
    init: (M, args) =>
        logI("Player::init")
        CombatObjectBase.init(@, M, args)
        @name = args.name

        @action_state = PlayerActionState.create()

        -- Create the stats object for the player
        @stats = statsystem.PlayerStatContext.create(@, args.name, args.race)
        args.race.stat_race_adjustments(@stats)
        args.class.stat_class_adjustments(args.class_args, @stats)
        @stats.attributes.raw_move_speed = args.speed
        @stats\calculate()

        logI("Player::init stats created")

        @vision_tile_radius = 5
        @player_path_radius = 300
        @id_player = args.id_player
        @vision = Vision.create(M, @vision_tile_radius)
        @paths_to_player = FloodFillPaths.create(M.tilemap)
        append M.player_list, @
        logI("Player::init complete")

    remove: (M) =>
        CombatObjectBase.remove(@, M)
        table.remove_occurrences M.player_list, @

    SMALL_SPRITE_ORDER: {
        "__LEGS", -- Pseudo-slot
        statsystem.BODY_ARMOUR,
        statsystem.WEAPON,
        statsystem.RING,
        statsystem.GLOVES,
        statsystem.BOOTS,
        statsystem.BRACERS,
        statsystem.AMULET,
        statsystem.HEADGEAR,
        statsystem.AMMO,
    }

    REST_SPRITE: data.get_sprite("stat-rest")

    draw: (V) =>
        hmod = @_hurt_color_mod()
        -- Put base sprite
        sp = data.get_sprite(@stats.race.avatar_sprite)
        -- Last 3 numbers: r,g,b
        sp\draw(@x, @y, @frame, 1, 0.5, 0.5, 1, hmod, hmod)

        for equip_type in *@SMALL_SPRITE_ORDER
            local avatar_sprite
            -- For now, there is no way to get a legs sprite
            -- so we hardcode one in so avatars look less naked!
            if equip_type == "__LEGS"
                avatar_sprite = "sl-gray-pants"
            else
                equip = @stats\get_equipped(equip_type)
                avatar_sprite = equip and equip.avatar_sprite
            if avatar_sprite
                -- Put avatar sprite
                sp = data.get_sprite(avatar_sprite)
                sp\draw(@x, @y, @frame, 1, 0.5, 0.5, 1, hmod, hmod)
        if @stats.is_resting
            @REST_SPRITE\draw(@x, @y, @frame, 1, 0.5, 0.5)
        CombatObjectBase.draw(@, V)
    pre_draw: do_nothing

    nearest_enemy: (M) =>
        min_obj,min_dist = nil,math.huge
        for obj in *M.npc_list
            dist = util_geometry.object_distance(@, obj)
            if dist < min_dist
                min_obj = obj
                min_dist = dist
        return min_obj

    on_death: do_nothing
    attack: (M) =>
        o = @nearest_enemy(M)
        if o
            @stats.attack\apply(o.stats)        
            Animation.create M, {
                sprite: data.get_sprite("Unarmed"), x: o.x, y: o.y, vx: 0, vy: 0, priority: ATTACK_ANIMATION_PRIORITY,fade_rate: 0.1
            }

    can_see: (obj) =>
        return @vision.fieldofview\circle_visible(obj.x, obj.y, obj.radius)

    sync: (M) =>
        CombatObjectBase.sync(@, M)
        @vision\update(@x/M.tile_width, @y/M.tile_height)
        @paths_to_player\update(@x, @y, @player_path_radius)
}

NPC = newtype {
    parent: CombatObjectBase
    init: (M, args) =>
        CombatObjectBase.init(@, M, args)
        append M.npc_list, @
        @npc_type = statsystem.MONSTER_DB[args.type]
        @sprite = data.get_sprite(args.type)
        -- Clone the MonsterType stat object, with '@' as the new owner
        @stats = @npc_type.stats\clone(@)

    nearest_enemy: (M) =>
        min_obj,min_dist = nil,math.huge
        for obj in *M.player_list do
            dist = util_geometry.object_distance(@, obj)
            if dist < min_dist
                min_obj = obj
                min_dist = dist
        return min_obj, min_dist
    perform_action: (M) =>
        min_obj, min_dist = @nearest_enemy(M)
        if min_obj and @stats.cooldowns.action_cooldown == 0 and min_dist <= @stats.attack.range
            @stats.attack\apply(min_obj.stats)

    on_death: (M) =>
        CombatObjectBase.on_death(@, M)   
        Animation.create M, {
            sprite: @sprite, x: @x, y: @y, vx: 0, vy: 0, priority: @priority
        }

    remove: (M) =>
        CombatObjectBase.remove(@, M)
        table.remove_occurrences M.npc_list, @
}
-- Spell and attack objects

-- 'Step' is called in animation phase, in map_logic.moon
Animation = newtype {
    parent: ObjectBase
    init: (M, args) =>
        ObjectBase.init(@, M, args)
        assert args.priority, "Animation requires specifying priority! Alternative is chaos."
        @vx = args.vx or 0
        @vy = args.vy or 0
        @alpha = args.alpha or 1.0
        @fade_rate = args.fade_rate or 0.05
        @sprite = args.sprite
        append M.animation_list, @

    remove: (M) =>
        ObjectBase.remove(@, M)
        table.remove_occurrences M.animation_list, @

    step: (M) =>
        @x += @vx
        @y += @vy
        @alpha = math.max(@alpha - @fade_rate, 0)
        if @alpha == 0
            @queue_remove(M)
}

-- 'Step' is called in projectile phase, in map_logic.moon
Projectile = newtype {
    parent: ObjectBase
    priority: PROJECTILE_PRIORITY
    init: (M, args) =>
        ObjectBase.init(@, M, args)
        @sprite = args.sprite
        @vx = args.vx
        @vy = args.vy
        @action = args.action
        append M.projectile_list, @

    step: (M) =>
        @x += @vx
        @y += @vy

        for col_id in *M.object_query(@)
            obj = M.col_id_to_object[col_id]
            if getmetatable(obj) == NPC
                Animation.create M, {
                    sprite: @sprite, x: @x, y: @y
                    vx: @vx, vy: @vy, priority: @priority
                }
                @queue_remove(M)
                return
        if M.tile_check(@)
            @queue_remove(M)

    remove: (M) =>
        ObjectBase.remove(@, M)
        table.remove_occurrences M.projectile_list, @
}

return {:ObjectBase, :Feature, :CombatObjectBase, :Player, :NPC, :Projectile}
