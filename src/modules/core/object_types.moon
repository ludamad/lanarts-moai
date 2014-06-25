
BoolGrid = require 'BoolGrid'
user_io = require 'user_io'
modules = require "modules"
import camera from require "core"
import FieldOfView, FloodFillPaths from require "core"

-- Object lifecycle:
--  Object creation:
--   .init(args) -> Create the game object with parameters.
--   .register(L) -> Setup the game object with the various
--     game subsystems.
--  During gameplay:
--   .step(L)
--   .post_step(L)
--  Object on/off-screen (TODO For optimization only):
--   .register_prop/.unregister_prop
--  Object destruction:
--   .unregister()

ObjectBase = with newtype()
	---------------------------------------------------------------------------
	-- Core protocol
	---------------------------------------------------------------------------

	.init = (L, args) =>
		@x, @y, @radius = args.x, args.y, args.radius
        @speed = args.speed
        @target_radius, @solid = (args.target_radius or args.radius), args.solid
        @is_focus = args.is_focus or false
        -- Register into world , and store the instance table ID
        @id = L.objects\add(@)

    .remove = (L) =>
        L.objects\remove(@)

    .pre_draw = (V) => @update_prop V.get_prop(@id)
        -- -- For debugging purposes:
        -- checkCol = (if V.level.solid_check(@) then 0 else 1)
        -- @prop\setColor(1, checkCol, checkCol, 1) 
        -- @prop\setPriority(@y)

    -- Note: Does not sync props
    .sync = (L) => nil


CombatObjectBase = with newtype {parent: ObjectBase}
    .init = (L, args) =>
        ObjectBase.init(@, L, args)
        -- The collision detection component
        -- Subsystem registration
        @id_col = L.collision_world\add_instance(@x, @y, @radius, @target_radius, @solid)
        -- The collision evasion component
        @id_rvo = L.rvo_world\add_instance(@x, @y, @radius, @speed)

    .remove = (L) =>
        ObjectBase.remove(@, L)
        L.collision_world.remove_instance(@id_col)
        L.rvo_world.remove_instance(@id_col)

    -- Subsystem synchronization
    .sync_col = (L) =>
        L.collision_world\update_instance(@id_col, @x, @y, @radius, @target_radius, @solid)
    .sync = (L) =>
        ObjectBase.sync(@, L)
        @sync_col(L)

    -- Set RVO heading
    .set_rvo = (L, dx, dy) =>
        maxspeed = if (dx == 0 and dy == 0) then 0 else @speed
        L.rvo_world\update_instance(@id_rvo, @x, @y, @radius, maxspeed, dx, dy)
    .get_rvo_velocity = (L) =>
        return L.rvo_world\get_velocity(@id_rvo)

-- NB: Controlling logic in level_logic

Vision = with newtype()
    .init = (L, line_of_sight) =>
        @line_of_sight = line_of_sight
        @seen_tile_map = BoolGrid.create(L.tilemap_width, L.tilemap_height, false)
        @fieldofview = FieldOfView.create(L.tilemap, @line_of_sight)
        @prev_seen_bounds = {0,0,0,0}
        @current_seen_bounds = {0,0,0,0}
    .update = (x, y) =>
        @fieldofview\calculate(x, y)
        @fieldofview\update_seen_map(@seen_tile_map)
        @prev_seen_bounds = @current_seen_bounds
        @current_seen_bounds = @fieldofview\tiles_covered()


Player = with newtype {parent: CombatObjectBase}
    .init = (L, args) =>
        CombatObjectBase.init(@, L, args)
        @vision_tile_radius = 7
        @player_path_radius = 300
        @id_player = args.id_player
        @vision = Vision.create(L, @vision_tile_radius)
        @paths_to_player = FloodFillPaths.create(L.tilemap)
    .sync = (L) =>
        CombatObjectBase.sync(@, L)
        @vision\update(@x/L.tile_width, @y/L.tile_height)
        @paths_to_player\update(@x, @y, @player_path_radius)

    .quad = modules.get_sprite("player")\create_quad()
    .update_prop = (prop) =>
        return with prop
            \setDeck @quad
            \setLoc(@x, @y)
            \setPriority @y

NPC = with newtype {parent: CombatObjectBase}
    .quad = modules.get_sprite("monster")\create_quad()
    .update_prop = (prop) =>
        return with prop
            \setDeck @quad
            \setLoc @x, @y
            \setPriority @y

return {:ObjectBase, :CombatObjectBase, :Player, :NPC}
