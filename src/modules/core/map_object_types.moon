
BoolGrid = require 'BoolGrid'
user_io = require 'user_io'
res = require "resources"
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

DAMAGE_TEXT_PRIORITY = 98 -- Lower means more 'on top'
ATTACK_ANIMATION_PRIORITY = 98 -- Lower means more 'on top'
PROJECTILE_PRIORITY = 99
-- The base priority for combat objects, will never fall below 100 after adjustments.
BASE_PRIORITY = 101
FEATURE_PRIORITY = 102
-- Add Y values * Y_PRIORITY_INCR to adjust the object priority.
Y_PRIORITY_INCR = -(2^-16)

local Animation, Player -- Forward declare, used throughout

ObjectBase = newtype {
	---------------------------------------------------------------------------
	-- Core protocol
	---------------------------------------------------------------------------
    alpha: 1.0
    sprite: false
    priority: 0
	init: (M, args) =>
		@x, @y, @radius = args.x, args.y, args.radius or 15
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
    init: (M, stats, args) =>
        args.solid = true
        ObjectBase.init(@, M, args)
        @stats = stats
        -- The collision detection component
        -- Subsystem registration
        @id_col = M.collision_world\add_instance(@x, @y, @radius, @target_radius, @solid)
        M.col_id_to_object[@id_col] = @
        -- The collision evasion component
        @id_rvo = M.rvo_world\add_instance(@x, @y, @radius, @stats.move_speed)
        append M.combat_object_list, @
        @set_priority()
        @_reset_delayed_action()

    _reset_delayed_action: () =>
        -- Delayed action information:
        @delayed_action = false
        @delayed_action_target_id = false
        @delayed_action_target_x = false
        @delayed_action_target_y = false
        @delayed_action_initial_delay = false

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
    set_rvo: (M, dx, dy, max_speed = @stats.move_speed, radius = @radius) =>
        M.rvo_world\update_instance(@id_rvo, @x, @y, radius, max_speed, dx, dy)
    get_rvo_velocity: (M) =>
        return M.rvo_world\get_velocity(@id_rvo)
    get_rvo_heading: (M) =>
        return M.rvo_world\get_preferred_velocity(@id_rvo)

    check_delayed_action: (M) =>
        if @stats.cooldowns.action_wait <= 0 and @delayed_action
            switch @delayed_action
                when 'weapon_attack'
                    obj = M.objects\get(@delayed_action_target_id)
                    if obj 
                        dmg = @stats.attack\apply(M.rng, obj.stats)
                        tx, ty = obj.x, obj.y
                        -- Calculate direction towards the object being attacked
                        dx, dy = obj.x - @x, obj.y - @y
                        mag = math.sqrt(dx*dx+dy*dy)
                        dx, dy = dx/mag, dy/mag
                        hit_spr = @stats.attack.on_hit_sprite
                        if hit_spr
                            Animation.create M, {
                                sprite: data.get_sprite(hit_spr), x: obj.x, y: obj.y, vx: 0, vy: 0, priority: ATTACK_ANIMATION_PRIORITY, fade_rate: 0.1
                            }
                        -- Create floating damage text
                        is_player = (getmetatable(@) == Player)
                        text_color = (if is_player then Display.COL_LIGHT_GRAY else Display.COL_PALE_RED)
                        Animation.create M, {
                            drawn_text: tostring(dmg), x: tx, y: ty, vx: dx, vy: dy, color: text_color, priority: DAMAGE_TEXT_PRIORITY, fade_rate: 0.04
                        }
                    @_reset_delayed_action()
                else
                    error("Unexpected branch!")

    queue_weapon_attack: (id) =>
        assert @stats.cooldowns.action_cooldown <= 0
        @stats.cooldowns.action_cooldown = @stats.attack.cooldown
        @stats.cooldowns.action_wait =  math.min(@stats.attack.delay, statsystem.MAX_MELEE_QUEUE)
        @stats.cooldowns.move_cooldown = math.max(@stats.attack.delay, @stats.cooldowns.move_cooldown)
        @delayed_action = 'weapon_attack'
        @delayed_action_target_id = id
        @delayed_action_initial_delay = @stats.attack.delay

    -- Stat system hook:
    on_death: (M, attacker) =>
        @queue_remove(M)

    _spike_color_mod: (v, max) => 
        -- Derived from experimental tinkering:
        if v == 0 then return 1
        elseif v < max/2 then return v/max*0.35 + 0.3
        else return (max - v)*0.07 + 0.3

    _get_rgb: () =>
        if @delayed_action
            -- Use action wait to modify r,g,b values:
            v1 = @_spike_color_mod(@stats.cooldowns.action_wait, @delayed_action_initial_delay)
            v2 = v1 * 0.25 + 0.75
            return v2,v2,v1
        elseif @stats.cooldowns.move_cooldown > 0
            return 0.5, 0.5, 0.5
        else
            -- Use hurt cooldown (if any) to modify r,g,b values:
            cmod = @_spike_color_mod(@stats.cooldowns.hurt_cooldown, statsystem.HURT_COOLDOWN)
            return 1, cmod, cmod

    WAIT_SPRITE: data.get_sprite("stat-wait")
    draw: (V) =>
        ObjectBase.draw(@, V, @_get_rgb())
        if @stats.cooldowns.move_cooldown > 0
            @WAIT_SPRITE\draw(@x, @y, @frame, 1, 0.5, 0.5)
        healthbar_offsety = 20
        if @target_radius > 16
            healthbar_offsety = @target_radius + 8
        if @stats.hp < @stats.max_hp
            x,y = @x - 10, @y - healthbar_offsety
            w, h = 20, 5
            draw_statbar(x,y,w,h, @stats.hp / @stats.max_hp)
}

-- NB: Controlling logic in map_logic

SHARED_LINE_OF_SIGHT = 3

PlayerVision = newtype {
    init: (M, id_player, line_of_sight) =>
        @line_of_sight = line_of_sight
        @id_player = id_player
        @fieldofview = FieldOfView.create(@line_of_sight)
        @shared_fieldofview = FieldOfView.create(SHARED_LINE_OF_SIGHT)
        @prev_seen_bounds = {0,0,0,0}
        @current_seen_bounds = {0,0,0,0}
        @shared_prev_seen_bounds = {0,0,0,0}
        @shared_current_seen_bounds = {0,0,0,0}
    get_fov_and_bounds: (M) =>
        if M.gamestate.local_player_id == @id_player
            return @fieldofview, @current_seen_bounds
        return @shared_fieldofview, @shared_current_seen_bounds
    update: (M, x, y) =>
        @fieldofview\calculate(M.tilemap, x, y)
        @shared_fieldofview\calculate(M.tilemap, x, y)
        @fieldofview\update_seen_map(M.player_seen_map(@id_player))
        for other_player in *M.gamestate.players
            if other_player.id_player ~= @id_player
                @shared_fieldofview\update_seen_map(M.player_seen_map(other_player.id_player))
        -- Local state update:
        @prev_seen_bounds = @current_seen_bounds
        @current_seen_bounds = @fieldofview\tiles_covered()
        -- Shared state update:
        @shared_prev_seen_bounds = @shared_current_seen_bounds
        @shared_current_seen_bounds = @shared_fieldofview\tiles_covered()
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

        -- Create the stats object for the player
        stats = statsystem.PlayerStatContext.create(@, args.name, args.race)
        args.race.stat_race_adjustments(stats)
        args.class.stat_class_adjustments(args.class_args, stats)
        stats\calculate(false)

        CombatObjectBase.init(@, M, stats, args)
        @name = args.name

        @action_state = PlayerActionState.create()

        logI("Player::init stats created")

        @player_path_radius = 300
        @id_player = args.id_player
        @vision = PlayerVision.create(M, @id_player, M.line_of_sight)
        @paths_to_player = FloodFillPaths.create()
        @paths_to_player\set_map(M.tilemap)
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
    SPRINT_SPRITE: data.get_sprite("stat-speed")

    draw: (V) =>
        r,g,b = @_get_rgb()
        -- Put base sprite
        sp = data.get_sprite(@stats.race.avatar_sprite)
        -- Last 3 numbers: r,g,b
        sp\draw(@x, @y, @frame, 1, 0.5, 0.5, r,g,b)

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
                sp\draw(@x, @y, @frame, 1, 0.5, 0.5, r,g,b)
        if @stats.is_resting
            @REST_SPRITE\draw(@x, @y, @frame, 1, 0.5, 0.5)
        if @stats.is_sprinting
            @SPRINT_SPRITE\draw(@x, @y, @frame, 1, 0.5, 0.5)

        CombatObjectBase.draw(@, V)
    pre_draw: do_nothing

    nearest_enemy: (M) =>
        min_obj,min_dist = nil,math.huge
        for obj in *M.npc_list
            dist = util_geometry.object_distance(@, obj)
            if dist < min_dist
                min_obj = obj
                min_dist = dist
        return min_obj, min_dist

    on_death: (M) =>
        logI "Player #{@id_player} has died."
        M.gamestate.local_death = true

    can_see: (obj) =>
        return @vision.fieldofview\circle_visible(obj.x, obj.y, obj.radius)

    sync: (M) =>
        CombatObjectBase.sync(@, M)
        @vision\update(M, @x/M.tile_width, @y/M.tile_height)
        @paths_to_player\update(@x, @y, @player_path_radius)
}

NPC_RANDOM_WALK, NPC_CHASING = 0,1

NPC = newtype {
    parent: CombatObjectBase
    init: (M, args) =>
        @npc_type = statsystem.MONSTER_DB[args.type]
        args.radius = @npc_type.radius
        -- Clone the MonsterType stat object, with '@' as the new owner
        CombatObjectBase.init(@, M, @npc_type.stats\clone(@), args)
        append M.npc_list, @
        @sprite = data.get_sprite(args.type)
        @ai_action = NPC_RANDOM_WALK
        @ai_target = false
        @ai_vx = 0
        @ai_vy = 0

    nearest_enemy: (M) =>
        min_obj,min_dist = nil,math.huge
        for obj in *M.player_list do
            dist = util_geometry.object_distance(@, obj)
            if dist < min_dist 
                min_obj = obj
                min_dist = dist
        return min_obj, min_dist

    on_death: (M) =>
        CombatObjectBase.on_death(@, M)
        -- Players gain experience points, as long as they are on the same map:
        n_players = #M.player_list
        for obj in *M.player_list do
            xp_gain = statsystem.challenge_rating_to_xp_gain obj.stats.level, @npc_type.level
            -- Divide XP up by players:
            xp_gain = math.round(xp_gain / n_players)
            statsystem.gain_xp(obj.stats, xp_gain)

        Animation.create M, {
            sprite: @sprite, x: @x, y: @y, vx: 0, vy: 0, priority: @priority
        }

    RANDOM_WALK_SPRITE: data.get_sprite("stat-random")
    draw: (V) =>
        CombatObjectBase.draw(@, V)
        if @ai_action == NPC_RANDOM_WALK
            @RANDOM_WALK_SPRITE\draw(@x, @y, @frame, 1, 0.5, 0.5)

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
        @sprite = args.sprite or false
        @drawn_text = args.drawn_text or false
        @color = table.clone(args.color or Display.COL_WHITE)
        append M.animation_list, @

    font: res.get_bmfont 'Liberation-Mono-20.fnt'
    draw: (V) =>
        ObjectBase.draw(@, V)
        if @drawn_text
            @color[4] = @alpha/2 + .5
            Display.drawTextCenter @font, @drawn_text, @x, @y, @color

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

return {:ObjectBase, :Feature, :CombatObjectBase, :Player, :NPC, :Projectile, :NPC_RANDOM_WALK, :NPC_CHASING}
