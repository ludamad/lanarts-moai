-------------------------------------------------------------------------------
-- Objects are formed as an entity-component system
-- they are loose collections of identifiers to the rest of the system.
-------------------------------------------------------------------------------

BoolGrid = require 'BoolGrid'
user_io = require 'user_io'
import modules, view from require 'game'
import FieldOfView from require "core"

MAX_SPEED = 32

-- Object lifecycle:
--  Object creation:
--   .init(args) -> Create the game object with parameters.
--   .register(C) -> Setup the game object with the various
--     game subsystems.
--  During gameplay:
--   .step(C)
--   .update(C)
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
        @is_focus = args.is_focus
        -- The instance table ID
        @id = false
        -- The (main) instance prop
        @prop = false
        -- The collision detection component
        @id_col = false
        -- The collision evasion component
        @id_rvo = false
    -- By default, do nothing on step event
    .step = (C) => 
    	nil
   	-- Update the various subsystems based on the current state
    .update = (C) =>
    	@update_prop(C)
        -- For debugging purposes:
        check = C.solid_check(@)
        @prop\setColor(1,1, (if check then 0 else 1),1) 

    -- World registration functions
    .register = (C) =>
    	@register_col(C)
    	@register_rvo(C)
    	@register_prop(C)
    .unregister = (C) =>
		if @id_col
			C.collision_world.remove_instance(@id_col)
			@id_col = false
		if @id_rvo
			C.rvo_world.remove_instance(@id_col)
			@id_rvo = false

	---------------------------------------------------------------------------
	-- Implementation methods
	---------------------------------------------------------------------------

    -- Prop control functions
    .register_prop = (C) =>
    	assert(not @prop, "Prop was already registered!")
    	@prop = @_create_prop()
    	C.add_object_prop(@prop)

    ._create_prop = (C) =>
    	error("_create_prop: Not yet implemented!")
    .update_prop = (prop) =>
        if @prop 
            @prop\setLoc @x, @y
    .unregister_prop = (C) =>
    	if @prop 
    		C.remove_object_prop(@prop)
    		@prop = false

    -- Subsystem registration
	.register_col = (C) =>
		@id_col = C.collision_world\add_instance(@x, @y, @radius, @target_radius, @solid)
	.register_rvo = (C) =>
		@id_rvo = C.rvo_world\add_instance(@x, @y, @radius, MAX_SPEED)

    -- Subsystem updating
	.update_col = (C) =>
		C.collision_world\update_instance(@id_col, @x, @y, @radius, @target_radius, @solid)
	.update_rvo = (C) =>
		C.rvo_world\update_instance(@id_rvo, @x, @y, @radius, MAX_SPEED, @vx, @vy)

Vision = with newtype()
    .init = (C, line_of_sight) =>
        @line_of_sight = line_of_sight
        @seen_tile_map = BoolGrid.create(C.tilemap_width, C.tilemap_height, false)
        @fieldofview = FieldOfView.create(C.tilemap, @line_of_sight)
        @prev_seen_bounds = {0,0,0,0}
        @current_seen_bounds = {0,0,0,0}

Player = with newtype {parent: ObjectBase}
	.init = (args) =>
		@base_init(args)
    .register = (C) =>
        ObjectBase.register(@, C)
        -- Seen tile map, defaulted to false
        @vision = Vision.create(C, 7)

    .step = (C) =>
        ObjectBase.step(@, C)

	-- Missing piece for 'register'
	._create_prop = (C) => 
		quad = modules.get_sprite("player")\create_quad()
		return with MOAIProp2D.new()
            \setDeck(quad)
            \setLoc(@x, @y)
    .update = (C) => 
        ObjectBase.update(@, C)
        @fieldofview\calculate(@x/C.tile_width, @y/C.tile_height)
        @fieldofview\update_seen_map(@seen_tile_map)
        if @is_focus
            view.center_on(C, @x, @y)
        if (user_io.key_down "K_UP") or (user_io.key_down "K_W") 
            if not C.solid_check @, 0, -4 then @y -= 4
        if (user_io.key_down "K_RIGHT") or (user_io.key_down "K_D") 
            if not C.solid_check @, 4, 0 then @x += 4
        if (user_io.key_down "K_DOWN") or (user_io.key_down "K_S") 
            if not C.solid_check @, 0, 4 then @y += 4
        if (user_io.key_down "K_LEFT") or (user_io.key_down "K_A") 
            if not C.solid_check @, -4, 0 then @x -= 4

    -- Missing piece for 'update'
    .update_prop = (C) =>
        ObjectBase.update_prop(@, C)


return {:ObjectBase, :Player}