import abs, min, max, floor, ceil from math
import game_camera, display_size from require '@Display_components'

local map_size, map_tile_size, map_tile_pixels -- Lazy imported

do 
	local map_state -- Last imported
	map_size = () -> 
		map_state = map_state or require "core.map_state"
		return map_state.map_size()
	map_tile_size = () -> 
		map_state = map_state or require "core.map_state"
		return map_state.map_tile_size()
	map_tile_pixels = () -> 
		map_state = map_state or require "core.map_state"
		return map_state.map_tile_pixels()

CAMERA_SUBW,CAMERA_SUBH = 100, 100
CAMERA_SPEED = 8

_get_components = () ->
	x, y = game_camera\getLoc()
	w, h = display_size()
	ww, wh = map_size()
	return x-w/2, y-h/2, w, h, ww, wh

-- Are we outside of the centre of the camera enough to warrant snapping the camera ?
camera_is_off_center = (px, py) ->
	x,y,width,height,world_width,world_height = _get_components()
	dx, dy = px - width /2 - x, py - height/2 - y

	return (abs(dx) > width / 2 or abs(dy) > height / 2)

camera_move_towards = (px, py) ->
	x,y,width,height,world_width,world_height = _get_components()

	dx, dy = px - x, py - y
	if (abs dx) > CAMERA_SUBW / 2 
		if px > x 
			x = min px - CAMERA_SUBW / 2, x + CAMERA_SPEED
		 else
			x = max px + CAMERA_SUBW / 2, x - CAMERA_SPEED
		x = max 0, (min world_width - width, x)

	if (abs dy) > CAMERA_SUBH / 2 
		if py > y 
			y = min py - CAMERA_SUBH / 2, y + CAMERA_SPEED
		 else 
			y = max py + CAMERA_SUBH / 2, y - CAMERA_SPEED
		y = max 0, (min world_height - height, y)

	-- Note, it is very bad to have the camera not on an integral boundary
	game_camera\setLoc(math.floor(x+width/2), math.floor(y+height/2))
	
camera_center_on = (px, py) ->
	x,y,width,height,world_width,world_height = _get_components()

	move_towards(px - width / 2, py - height / 2)

camera_sharp_center_on = (px, py) ->
	print "sharp_center_on"
	x,y,width,height,world_width,world_height = _get_components()

	dx,dy = px - x, py - y
	if dx < width / 2
		dx = width / 2
	elseif dx > world_width - width / 2
		dx = world_width - width / 2

	if dy < height / 2
		dy = height / 2
	elseif dy > world_height - height / 2
		dy = world_height - height / 2

	-- Note, it is very bad to have the camera not on an integral boundary
	game_camera\setLoc(math.floor(px+dx  - width / 2), math.floor(py+dy - height / 2))

camera_move_delta = (dx, dy) ->
	move_towards(x + dx, y + dy)

camera_region_covered = () ->
	x,y,width,height,world_width,world_height = _get_components()

	return x,y, x+width, x+height

camera_tile_region_covered = () ->
	x,y,width,height,world_width,world_height = _get_components()
	tw, th = map_tile_pixels()
	min_x = max(1, x / tw)
	min_y = max(1, y / th)
	max_x = (min(world_width, x + width)) / tw
	max_y = (min(world_height, y + height)) / th

	return (floor min_x), (floor min_y), (ceil max_x), (ceil max_y)

camera_rel_xy = (px, py) ->
	x, y = game_camera\getLoc()
	return px - x, py - y

camera_xy = () ->
	x, y = game_camera\getLoc()
	w, h = display_size()
	return x - w/2, y - h/2

return {
	:camera_is_off_center, :camera_move_towards, :camera_center_on, :camera_sharp_center_on
	:camera_move_delta, :camera_region_covered, :camera_tile_region_covered, :camera_rel_xy, :camera_xy
}