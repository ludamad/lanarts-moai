res = require 'resources'

-- Wraps default values, to be used by chained .define statements
-- See modules/ folder for examples.
-- Eg, with tiledef <defaults>
--         .define <values1>
--         .define <values2>
define_wrapper = (func) ->
	return setmetatable {define: func}, { 
			-- Metatable, makes object callable
			-- when called, incorporate as 'defaults'
			__call: (defaults) =>
				return define: (values) ->
					copy = table.clone(defaults)
					table.merge(copy, values)
					return func(values)
		}

data = {tiles: {}, id_to_tile: {}, levels: {}, id_to_level: {}}

-- Represents a single tile, or multiple variant tiles
Tile = with newtype()
	.init = (ids, texture, x, y) -> 


setup_define_functions = (module_name) ->
	_G.tile_def = (values) ->
		{:file, :solid, :name, :to} = values
		_from = values["from"] -- skirt around Moonscript keyword

		quad = with MOAIGfxQuad2D.new()
            \setTexture res.get_texture(file)
            -- Center tile on origin:
            \setUVQuad x1, y1,
                x2, y1, 
                x2, y2,
                x1, y2
            \setRect -tilew/2, tileh/2, 
                tilew/2, -tileh/2

load = (module_name) ->
	-- Remember previous paths
	prev_res_paths = res.get_base_paths()
	prev_package_paths = package.path

	-- Setup loading context for module
	setup_define_functions(module_name)

	-- Load the file
	require 'src.modules.' .. module_name .. '.main'

	-- Restore previous paths
	res.set_base_paths(prev_res_paths)
	package.path = prev_package_paths

get_tile = (name) -> data.tiles[name]

return { :load, :get_level, 
	get_tile: (name) -> data.tiles[name], 
	get_sprite: (name) -> data.tiles[name] }