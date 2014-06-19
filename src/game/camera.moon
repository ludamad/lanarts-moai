import abs, min, max, floor, ceil from math

CAMERA_SUBW,CAMERA_SUBH = 100, 100
CAMERA_SPEED = 8

_get_components = (V) ->
	x, y = V.camera\getLoc()
	w, h = V.cameraw, V.camerah
	ww, wh = V.level.pix_width, V.level.pix_height
	return x-w/2, y-h/2, w, h, ww, wh

-- Are we outside of the centre of the camera enough to warrant snapping the camera ?
camera_is_off_center = (V, px, py) ->
	x,y,width,height,world_width,world_height = _get_components(V)
	dx.dy = px - x, py - y
	return (abs(dx) > width / 2 or abs(dy) > height / 2)

move_towards = (V, px, py) ->
	x,y,width,height,world_width,world_height = _get_components(V)

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

	V.camera\setLoc(x+width/2, y+height/2)
	
center_on = (V, px, py) ->
	x,y,width,height,world_width,world_height = _get_components(V)

	move_towards(V, px - width / 2, py - height / 2)

sharp_center_on = (V, px, py) ->
	x,y,width,height,world_width,world_height = _get_components(V)

	if px < width / 2
		px = width / 2
	elseif px > world_width - width / 2
		px = world_width - width / 2

	if py < height / 2
		py = height / 2
	elseif py > world_height - height / 2
		py = world_height - height / 2

	V.camera\setLoc(px, py)

move_delta = (V, dx, dy) ->
	move_towards(V, x + dx, y + dy)

region_covered = (V) ->
	x,y,width,height,world_width,world_height = _get_components(V)

	return x,y, x+width, x+height

tile_region_covered = (V) ->
	x,y,width,height,world_width,world_height = _get_components(V)

	min_x = max(1, x / V.level.tile_width)
	min_y = max(1, y / V.level.tile_height)
	max_x = (min(world_width, x + width)) / V.level.tile_width
	max_y = (min(world_height, y + height)) / V.level.tile_height

	return (floor min_x), (floor min_y), (ceil max_x), (ceil max_y)

camera_rel_xy = (V, px, py) ->
	x, y = V.camera\getLoc()
	return px - x, py - y

return {:camera_is_off_center, :move_towards, :center_on, :sharp_center_on, :move_delta, :region_covered, :tile_region_covered, :camera_rel_xy}