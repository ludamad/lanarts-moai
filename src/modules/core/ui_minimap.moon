-- TODO: Make tool to cleanup imports
res = require 'resources'
import setup_script_prop from require '@util_draw'
import put_text, put_text_center, put_prop, camera_tile_region_covered from require "ui.Display"
import COL_GREEN, COL_RED, COL_BLUE, COL_YELLOW from require "ui.Display"
import TileMap from require "core"

import key_down, mouse_xy from require "user_io"

-- From luajit, for checking flags:
bit_and = bit.band

-- Color positions in minimap_colors.png
IDX_CLEAR = 0
IDX_WHITE = 1
IDX_BLACK = 2
IDX_RED = 3
IDX_BLUE = 4
IDX_GREEN = 5

MiniMap = newtype {
	init: (V, x, y) =>
		-- Initialize the texture, grid, tile-deck and location
		@minimap_colors = res.get_texture "minimap_colors.png"
		@grid = MOAIGrid.new()

        @tiledeck = with MOAITileDeck2D.new()
            \setTexture(@minimap_colors)

        -- Initialize the minimap grid and tiledeck size
		@set_size(100,100, 2, 2)
		@scale = 1
		@x,@y = x - @w/2, y - @h/2

		-- Initialize other data
		@row_buffer = {}
		@seen_buffer = {}
		@prop = with MOAIProp2D.new()
        	\setDeck(@tiledeck)
        	\setGrid(@grid)
        	\setLoc(@x,@y)

       	-- Set up the view
		@map = V.map
		@layer = V.ui_layer
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

	pre_draw: () =>
		sx, sy = @_start_xy()

		FLAG_SOLID = TileMap.FLAG_SOLID
		FLAG_PERIMETER = TileMap.FLAG_PERIMETER
		buff = @row_buffer
		seen_buff = @seen_buffer

		player = @map.gamestate.local_player()

		z_is_down = key_down("K_Z")

		for row=1,@tile_h
			-- Last number is default fill
			TileMap.get_row_flags(@map.tilemap, buff, sx, sx + @tile_w, sy + row, FLAG_SOLID)
			player.vision.seen_tile_map\get_row(seen_buff, sx, sx + @tile_h, sy + row, false)
			for i=1,@tile_w
				flags = buff[i]
				buff[i] = bit_and(flags, FLAG_PERIMETER) ~= 0 and IDX_GREEN or IDX_CLEAR
				buff[i] = bit_and(flags, FLAG_SOLID) ~= 0 and buff[i] or IDX_WHITE
				buff[i] = (seen_buff[i] or z_is_down) and buff[i] or IDX_CLEAR

			@grid\setRow(row, unpack(buff))

		for p in *@map.player_list
			x,y = math.ceil(p.x / 32) - sx + 1, math.ceil(p.y / 32) - sy
			@grid\setTile(x, y, IDX_BLUE)

	draw: () =>
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

return {:MiniMap}
