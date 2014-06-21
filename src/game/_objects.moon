-------------------------------------------------------------------------------
-- Objects are formed as an entity-component system
-- they are loose collections of identifiers to the rest of the system.
-------------------------------------------------------------------------------

BoolGrid = require 'BoolGrid'
user_io = require 'user_io'
import modules, camera from require 'game'
import FieldOfView from require "core"

MAX_SPEED = 32

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

	.init = (args) =>
		@x, @y, @radius = args.x, args.y, args.radius
		@vx, @vy = args.vx or 0, args.vy or 0
        @target_radius, @solid = (args.target_radius or args.radius), args.solid
        @is_focus = args.is_focus or false
        -- The instance table ID
        @id = false
        -- The (main) instance prop
        @prop = false
        -- The collision detection component
        @id_col = false
        -- The collision evasion component
        @id_rvo = false
    -- By default, do nothing on step event
    .step = (L) => 
        @test = 2
        for i=1,1000 do
            @test = math.sqrt(@x*@x + @y*@y + i + @test)

    	nil
   	-- Update the various subsystems based on the current state
    .post_step = (L) => 
        nil
    .pre_draw = (V) =>
    	@update_prop(V)
        -- For debugging purposes:
        check = V.level.solid_check(@)
        @prop\setColor(1,1, (if check then 0 else 1),1) 
        @prop\setPriority(@y)

    -- World registration functions
    .register = (L) =>
    	@register_col(L)
    	@register_rvo(L)
    .unregister = (L) =>
		if @id_col
			L.collision_world.remove_instance(@id_col)
			@id_col = false
		if @id_rvo
			L.rvo_world.remove_instance(@id_col)
			@id_rvo = false

    .handle_io = (L) =>
        nil
	---------------------------------------------------------------------------
	-- Implementation methods
	---------------------------------------------------------------------------

    -- Prop control functions
    .register_prop = (V) =>
    	assert(not @prop, "Prop was already registered!")
    	@prop = @_create_prop()
    	V.add_object_prop(@prop)

    ._create_prop = (V) =>
    	error("_create_prop: Not yet implemented!")
    .unregister_prop = (L) =>
    	if @prop 
    		L.remove_object_prop(@prop)
    		@prop = false

    -- Subsystem registration
	.register_col = (L) =>
		@id_col = L.collision_world\add_instance(@x, @y, @radius, @target_radius, @solid)
	.register_rvo = (L) =>
		@id_rvo = L.rvo_world\add_instance(@x, @y, @radius, MAX_SPEED)

    -- Subsystem updating
    .update_prop = (prop) =>
        if @prop 
            @prop\setLoc @x, @y
	.update_col = (L) =>
		L.collision_world\update_instance(@id_col, @x, @y, @radius, @target_radius, @solid)
	.update_rvo = (L) =>
		L.rvo_world\update_instance(@id_rvo, @x, @y, @radius, MAX_SPEED, @vx, @vy)

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

Player = with newtype {parent: ObjectBase}
	.init = (args) =>
		@base_init(args)
    .register = (L) =>
        ObjectBase.register(@, L)
        -- Seen tile map, defaulted to false
        @vision = Vision.create(L, 7)

    .step = (L) =>
        ObjectBase.step(@, L)

	-- Missing piece for 'register'
	._create_prop = (L) => 
		quad = modules.get_sprite("player")\create_quad()
		return with MOAIProp2D.new()
            \setDeck(quad)
            \setLoc(@x, @y)
    .post_step = (L) => 
        ObjectBase.post_step(@, L)
        @vision\update(@x/L.tile_width, @y/L.tile_height)

    .handle_io = (L) =>
        if (user_io.key_down "K_UP") or (user_io.key_down "K_W") 
            if not L.solid_check @, 0, -4 then @y -= 4
        if (user_io.key_down "K_RIGHT") or (user_io.key_down "K_D") 
            if not L.solid_check @, 4, 0 then @x += 4
        if (user_io.key_down "K_DOWN") or (user_io.key_down "K_S") 
            if not L.solid_check @, 0, 4 then @y += 4
        if (user_io.key_down "K_LEFT") or (user_io.key_down "K_A") 
            if not L.solid_check @, -4, 0 then @x -= 4

    .pre_draw = (V) =>
        ObjectBase.pre_draw(@, V)
        if @is_focus
            if camera.camera_is_off_center(V, @x, @y)
                camera.sharp_center_on(V, @x, @y)
            else
                camera.center_on(V, @x, @y)

    .update_prop = (V) =>
        ObjectBase.update_prop(@, V)

Monster = with newtype {parent: ObjectBase}
    .init = (args) =>
        @base_init(args)
    .register = (L) =>
        ObjectBase.register(@, L)
    ._create_prop = (V) => 
        return with MOAIProp2D.new()
            \setDeck modules.get_sprite("monster")\create_quad()
            \setLoc @x, @y

return {:ObjectBase, :Player, :Monster}