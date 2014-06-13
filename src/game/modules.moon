res = require "resources"
mbase = require "moonscript.base"

data = {
	-- Sprite data
	sprites: {}, 
	id_to_sprite: {}, 
	next_sprite_id: 1, 

	-- Tile data
	tiles: {}, 
	id_to_tile: {}, 
	next_tile_id: 1,

	-- Tile variation data
	id_to_tilelist: {},
	next_tilelist_id: 1, 

	-- Level data
	levels: {}, 
	id_to_level: {}
	next_level_id: 1, 
}

-------------------------------------------------------------------------------
-- Graphic and tileset data
-------------------------------------------------------------------------------

TileGrid = with newtype()
	.init = (w, h) => 
		@w, @h = w,h
		@grid = [0 for i=1,w*h]
	.set = (x, y, val) => 
		@grid[y * (@h-1) + x] = val
	.get = (x, y) => 
		@grid[y * (@h-1) + x]

-- Represents a single image sublocation
TexPart = with newtype()
	.init = (texture, x, y, w, h) =>
		@texture, @x, @y, @w, @h = texture, x, y, w, h
	.as_quad = (quad) =>
		with quad 
			\setTexture @texture
            \setUVQuad @x, @y,
                @x+@w, @y, 
                @x+@w, @y+@h,
                @x, @y+@h
            -- Center tile on origin:
            \setRect -@w/2, @h/2, 
                @w/2, -@h/2

-- Represents a single tile
Tile = with newtype()
	.init = (id, grid_id, solid) => 
		@id, @grid_id, @solid= id, grid_id, solid 

-- Represents a list of variant tiles (from same tile-set)
TileList = with newtype()
	.init = (id, name, tiles, texfile) => 
		@id, @name, @tiles, @texfile = id, name, tiles, texfile

Sprite = with newtype()
	.init = (tex_parts, kind, w, h) => 
		@tex_parts, @kind, @w, @h = tex_parts, kind, w, h

-------------------------------------------------------------------------------
-- Level data
-------------------------------------------------------------------------------

LevelData = with newtype()
	.init = (name, generator) => 
		@name, @generator = name, generator

-------------------------------------------------------------------------------
-- Part iteration
-------------------------------------------------------------------------------

-- Iterates numbered tiles
part_xy_iterator = (_from, to, id = 1) ->
	{minx,miny} = _from
	{maxx, maxy} = to
	-- Correct for first x += 1:
	x, y = minx - 1, miny
	-- Correct for first id += 1:
	id -= 1
	return () ->
		x, id = x + 1, id + 1
		if x > maxx then x, y = minx, y+1
		-- Finished
		if y > miny then return nil
		-- Valid
		return x, y, id

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
					return func(copy)
		}

TILE_WIDTH, TILE_HEIGHT = 32, 32

setup_define_functions = (module_name) ->
	-- Tile definition
	_G.tiledef = define_wrapper (values) ->
		{:file, :solid, :name, :to} = values
		file = res.get_resource_path(file)
		_from = values["from"] -- skirt around Moonscript keyword

		-- Default to 1 tile
		to = to or _from

		first_id = data.next_tile_id
		list_id = data.next_tilelist_id

		texture = res.get_texture(file)
		-- Width and height in pixels
		pix_w, pix_h = texture\getSize()
		-- With and height in tiles
		tex_w, tex_h = (pix_w / TILE_WIDTH), (pix_h / TILE_HEIGHT)

		-- Gather the tile list
		tiles = for x, y, id in part_xy_iterator(_from, to, first_id) 
			Tile.create id, 
				(y-1) * tex_w + x,
				solid

		tilelist = TileList.create(list_id, name, tiles, file)

		-- Assign to the tile name
		data.tiles[name] = tilelist
		data.id_to_tilelist[list_id] = tilelist

		-- Assign by tile id
		for tile in *tiles 
			data.id_to_tile[tile.id] = tile

		-- Skip the amount of tiles added
		data.next_tile_id += #tiles
		data.next_tilelist_id += 1

	-- Sprite definition
	_G.spritedef = define_wrapper (values) ->
		{:file, :size, :tiled, :kind, :name, :to} = values
		{:w, :h} = size
		kind = kind or variant

		_from = values["from"] -- skirt around Moonscript keyword

		-- Default to 1 sprite
		to = to or _from

		-- Gather the sprite frames
		frames = for x, y in part_xy_iterator(_from, to) 
			TexPart.create(res.get_texture(file), x, y, w, h)

		sprite = Sprite.create(frames, kind, w, h)
		data.sprites[name] = sprite
		data.id_to_sprite[data.next_sprite_id] = sprite

		-- Increment sprite number
		data.next_sprite_id += 1

	-- Level generation data definition
	_G.leveldef = define_wrapper (values) ->
		{:name, :generator} = values
		level = LevelData.create(name, generator)
		data.levels[name] = level
		data.id_to_level[data.next_sprite_id] = level

		-- Increment sprite number
		data.next_level_id += 1

-------------------------------------------------------------------------------
-- Load a module found in the folder modules/<module_name>/ by running the 
-- 'main.{moon or lua}' file in that folder.
-------------------------------------------------------------------------------

load = (module_name) ->
	-- Remember previous paths
	prev_res_paths = res.get_base_paths()
	prev_package_paths = package.path
	prev_package_mpaths = package.moonpath

	-- Setup loading context for module, including paths
	-- Lua path lookup:
	package.path = 'src/modules/' .. module_name .. '/?.lua' .. ';' .. package.path
	-- Moonscript path lookup:
	package.moonpath = 'src/modules/' .. module_name .. '/?.moon' .. ';' .. package.moonpath

	setup_define_functions(module_name)

	-- Load the file
	require 'src.modules.' .. module_name .. '.main'

	-- Restore previous paths
	res.set_base_paths(prev_res_paths)
	package.path = prev_package_paths
	package.moonpath = prev_package_mpaths

-------------------------------------------------------------------------------

return { 
	:load,
	get_tilelist: (key) -> 
		if type(key) == 'string' 
			data.tiles[key] 
		else 
			data.id_to_tilelist[key]

	get_tilelist_id: (name) -> data.tiles[name].id,
	get_sprite: (name) -> data.sprites[name] 
	get_level: (name) -> data.levels[name] 
}