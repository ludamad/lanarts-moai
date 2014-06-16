-------------------------------------------------------------------------------
-- Objects are formed as an entity-component system
-- they are loose collections of identifiers to the rest of the system.
-------------------------------------------------------------------------------

modules = require 'game.modules'
BoolGrid = require 'BoolGrid'
import FieldOfView from require "lanarts"

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
    	error("update_prop: Not yet implemented!")
    .unregister_prop = (C) =>
    	if @prop 
    		C.remove_object_prop(@prop)
    		@prop = false

    -- Subsystem registration
	.register_col = (C) =>
		@id_col = C.collision_world\add_instance(@x, @y, @radius, @target_radius, @solid)
	.register_rvo = (C) =>
		@id_col = C.rvo_world\add_instance(@x, @y, @radius, MAX_SPEED)

    -- Subsystem updating
	.update_col = (C) =>
		C.collision_world\update_instance(@id_col, @x, @y, @radius, @target_radius, @solid)
	.update_rvo = (C) =>
		C.rvo_world\update_instance(@id_rvo, @x, @y, @radius, MAX_SPEED, @vx, @vy)

Player = with newtype {parent: ObjectBase}
	.init = (args) =>
		@base_init(args)
    .register = (C) =>
        ObjectBase.register(@, C)
        -- Seen tile map, defaulted to false
        @seen_tile_map = BoolGrid.create(C.model_width, C.model_height, false)
        @fieldofview = FieldOfView.create(C.model, @seen_tile_map, @target_radius)

	-- Missing piece for 'register'
	._create_prop = (C) => 
		quad = modules.get_sprite("player")\create_quad()
		return with MOAIProp2D.new()
            \setDeck(quad)
            \setLoc(@x, @y)
    -- Missing piece for 'update'
    .update_prop = (C) =>
        check = C.tile_check(@)
        @prop\setColor(1,1,if check then 0 else 1,1) 


return {:ObjectBase, :Player}