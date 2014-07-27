res = require "resources"
import Display from require "ui"

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

	-- Map data
	maps: {}, 
	id_to_map: {}
	next_map_id: 1, 
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
	.draw = (x, y, alpha=1, originx=0, originy=0) =>
		texw, texh = @texture\getSize()
		nx, ny = 1 - originx, 1 - originy
		-- TODO: Make drawTexture not such a long function?
		MOAIDraw.drawTexture @texture, x-@w*originx, y-@h*originy, x+@w*nx, y + @h*ny, @x/texw, @y/texh, (@x+@w)/texw, (@y+@h)/texh, alpha
	.update_quad = (quad) =>
		texw, texh = @texture\getSize()
		with quad 
			\setTexture @texture
            \setUVRect @x/texw, @y/texh,
             	(@x+@w)/texw, (@y+@h)/texh
            -- Center tile on origin:
            \setRect -@w/2, -@h/2, 
                @w/2, @h/2

-- Represents a single tile
Tile = with newtype()
	__constant = true -- For serialization
	.init = (id, grid_id, solid) => 
		@id, @grid_id, @solid= id, grid_id, solid 

-- Represents a list of variant tiles (from same tile-set)
TileList = with newtype()
	__constant = true -- For serialization
	.init = (id, name, tiles, texfile) => 
		@id, @name, @tiles, @texfile = id, name, tiles, texfile

Sprite = with newtype()
	__constant = true -- For serialization
	.init = (tex_parts, kind, w, h) => 
		@tex_parts, @kind, @w, @h = tex_parts, kind, w, h
	.update_quad = (quad, frame = 1) =>
		@tex_parts[frame]\update_quad(quad)
	.n_frames = () =>
		return #@tex_parts
	.get_quad = (frame = 1) =>
		quad = Display.get_quad()
		@update_quad(quad, (math.floor(frame)-1) % @n_frames() + 1)
		return quad
	.draw = (x, y, frame = 1, alpha = 1, originx=0, originy=0) =>
		frame = (math.floor(frame)-1) % @n_frames() + 1
		@tex_parts[frame]\draw(x, y, alpha, originx, originy)
	.put_prop = (layer, x, y, frame = 1, priority = 0, alpha = 1) =>
		return with Display.put_prop(layer)
            \setDeck(@get_quad(frame))
            \setLoc(x, y)
            \setPriority(priority)
            \setColor(1,1,1,alpha)

-------------------------------------------------------------------------------
-- Map data
-------------------------------------------------------------------------------

MapData = with newtype()
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

setup_define_functions = (fenv, module_name) ->
	-- Tile definition
	fenv.tiledef = define_wrapper (values) ->
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
	fenv.spritedef = define_wrapper (values) ->
		{:file, :size, :tiled, :kind, :name, :to} = values
		{w, h} = size
		kind = kind or 'variant'

		_from = values["from"] -- skirt around Moonscript keyword

		-- Default to 1 sprite
		to = to or _from

		-- Gather the sprite frames
		frames = for x, y in part_xy_iterator(_from, to) 
			TexPart.create(res.get_texture(file), (x-1)*w, (y-1)*h, w, h)

		sprite = Sprite.create(frames, kind, w, h)
		data.sprites[name] = sprite
		data.id_to_sprite[data.next_sprite_id] = sprite

		-- Increment sprite number
		data.next_sprite_id += 1

	-- Map generation data definition
	fenv.mapdef = define_wrapper (values) ->
		{:name, :generator} = values
		map = MapData.create(name, generator)
		data.maps[name] = map
		data.id_to_map[data.next_sprite_id] = map

		-- Increment sprite number
		data.next_map_id += 1

-- TODO: Actually setup by-module searching
setup_define_functions(_G, "NotUsedYet")

-------------------------------------------------------------------------------

return { 
	:load,
	get_tilelist: (key) -> 
		if type(key) == 'string' 
			assert(data.tiles[key])
		else 
			assert(data.id_to_tilelist[key])

	get_tilelist_id: (name) -> assert(data.tiles[name].id, name)
	get_sprite: (name) -> assert(data.sprites[name], name)
	get_map: (name) -> assert(data.maps[name], name)
}