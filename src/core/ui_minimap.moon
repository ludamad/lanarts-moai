-- TODO: Make tool to cleanup imports
res = require 'resources'
import setup_script_prop from require '@util_draw'
import put_text, put_text_center, put_prop, camera_tile_region_covered, ui_layer, packColor32 from require "ui.Display"
import COL_GREEN, COL_RED, COL_BLUE, COL_YELLOW, PRIORITY_INTERFACE from require "ui.Display"
import TileMap, data from require "core"
import get_tilelist from require "core.data"

import key_down, mouse_xy from require "user_io"

-- From luajit, for checking flags:
bit_and = bit.band

-- Set by _create_minimap_color_texture
IDX_NOT_SEEN_OFFSET = nil

IDX_YELLOW = data.get_minimap_color_id COL_YELLOW

_create_minimap_color_texture = () ->
	-- Get all 32-bit packaged RGBA values for the minimap
	colors = data.get_minimap_colors()
	image = with MOAIImage.new()
		\init #colors, 2
	IDX_NOT_SEEN_OFFSET = #colors
	for i=1,#colors
		image\setColor32 i-1, 0, packColor32(colors[i])
		{r,g,b} = colors[i]
		SCALE = 0.5
		image\setColor32 i-1, 1, packColor32({r*SCALE,g*SCALE,b*SCALE})
	return with MOAITexture.new()
		\load(image)

MiniMap = newtype {
	init: (map, x, y) =>
		-- Initialize the texture, grid, tile-deck and location
		@minimap_colors = _create_minimap_color_texture()
		@grid = MOAIGrid.new()

        @tiledeck = with MOAITileDeck2D.new()
            \setTexture(@minimap_colors)

        -- Initialize the minimap grid and tiledeck size
		@set_size(120,120, 2, 2)
		@scale = 1
		@x,@y = x - @w/2, y - @h/2

		-- Initialize other data
		@flag_buffer, @content_buffer, @seen_buffer = {}, {}, {}
		@prop = with MOAIProp2D.new()
        	\setDeck(@tiledeck)
        	\setGrid(@grid)
        	\setLoc(@x,@y)
        	\setPriority PRIORITY_INTERFACE

       	-- Set up the view
		@map = map
		@layer = ui_layer
		@layer\insertProp(@prop)

	mouse_over: () =>
		mx,my = mouse_xy()
		if @x > mx or @x+@w <= mx then return false
		if @y > my or @y+@h <= my then return false
		return true

	remove: () =>
		@layer\removeProp(@prop)

	set_size: (w, h, tw, th) =>
		-- Amount of tiles
		@w, @h = w, h
		@tile_w, @tile_h = w/tw, h/th
		@sqr_w, @sqr_h = tw, th
		-- Tile width and tile height
		@grid\setSize(@tile_w, @tile_h, tw, th)

		-- -- Adjust tile deck scaling:
		mw, mh = @minimap_colors\getSize()
        @tiledeck\setSize(mw, mh)

    _start_xy: () =>
		x1,y1,x2,y2 = camera_tile_region_covered()
		return math.floor((x1+x2 - @tile_w)/2), math.floor((y1+y2 - @tile_h)/2)

	_update: () =>
		sx, sy = @_start_xy()

		FLAG_SOLID = TileMap.FLAG_SOLID
		FLAG_PERIMETER = TileMap.FLAG_PERIMETER
		FLAG_SEETHROUGH = TileMap.FLAG_SEETHROUGH
		FLAG_RESERVED1 = TileMap.FLAG_RESERVED1
		FLAG_ALTERNATE = TileMap.FLAG_CUSTOM1
		-- flag_buff is also used to set the grid values
		flag_buff, content_buff, seen_buff = @flag_buffer, @content_buffer, @seen_buffer

		player = @map.gamestate.local_player()

		z_is_down = key_down("K_Z")

		seen_map = @map.player_seen_map(player.id_player)
		for row=1,@tile_h
			-- Last number is default fill
			TileMap.get_row_flags(@map.tilemap, flag_buff, sx, sx + @tile_w, sy + row, FLAG_SOLID)
			TileMap.get_row_content(@map.tilemap, content_buff, sx, sx + @tile_w, sy + row, FLAG_SOLID)
			seen_map\get_row(seen_buff, sx, sx + @tile_h, sy + row, false)
			for i=1,@tile_w
				flags = flag_buff[i]
				tile = get_tilelist(content_buff[i])
				is_showable = bit_and(flags, FLAG_SOLID) == 0
				if not is_showable
					is_showable = bit_and(flags, FLAG_PERIMETER) ~= 0 or bit_and(flags, FLAG_SEETHROUGH) ~= 0
				if seen_buff[i] or (z_is_down and is_showable)
					flag_buff[i] = tile.minicolor + IDX_NOT_SEEN_OFFSET
				else
					flag_buff[i] = 0
				if bit_and(flags, FLAG_RESERVED1) ~= 0 
					flag_buff[i] = 1
			@grid\setRow(row, unpack(flag_buff))

		G = @map.gamestate
		-- Adjust for player vision:
	    for inst in *@map.player_list
	       fov, bounds = inst.vision\get_fov_and_bounds(@map)
	       {x1,y1,x2,y2} = bounds
	       x1, x2 = math.max(sx, x1), math.min(x2, sx + @tile_w)
	       y1, y2 = math.max(sy, y1), math.min(y2, sy + @tile_h)
	       for y=y1,y2-1 do for x=x1,x2-1
	            if fov\within_fov(x,y)
	            	tile = @grid\getTile(x - sx, y - sy)
	            	if tile > IDX_NOT_SEEN_OFFSET
	                	@grid\setTile(x - sx, y - sy, tile - IDX_NOT_SEEN_OFFSET) -- Currently seen

		for p in *@map.player_list
			x,y = math.ceil(p.x / 32) - sx + 1, math.ceil(p.y / 32) - sy
			@grid\setTile(x, y, IDX_YELLOW)

	draw: () =>
		@_update()
		sx, sy = @_start_xy()

		x1,y1,x2,y2 = camera_tile_region_covered()
		x1 = (x1 - sx) * @sqr_w + @x
		x2 = (x2 - sx) * @sqr_w + @x
		y1 = (y1 - sy) * @sqr_h + @y
		y2 = (y2 - sy) * @sqr_h + @y

		-- Draw a border around the view
		MOAIGfxDevice.setPenColor(unpack(COL_YELLOW))
	    MOAIDraw.drawRect(x1, y1, x2, y2)

		-- Draw a border around the minimap
		MOAIGfxDevice.setPenColor(0.1,0.1,0.1)
	    MOAIDraw.drawRect(@x, @y, @x + @w, @y + @h)
}

return {
	:MiniMap
}
