import abs, min, max, floor from math

VIEW_SUBW,VIEW_SUBH = 100, 100
VIEW_SPEED = 8

_get_components = (C) ->
	x, y = C.camera\getLoc()
	w, h = C.vieww, C.viewh
	ww, wh = C.pix_width, C.pix_height
	return x-w/2, y-h/2, w, h, ww, wh

-- Are we outside of the centre of the view enough to warrant snapping the view ?
view_is_off_center = (C, px, py) ->
	x,y,width,height,world_width,world_height = _get_components(C)
	dx.dy = px - x, py - y
	return (abs(dx) > width / 2 or abs(dy) > height / 2)

move_towards = (C, px, py) ->
	x,y,width,height,world_width,world_height = _get_components(C)

	dx, dy = px - x, py - y
	if (abs dx) > VIEW_SUBW / 2 
		if px > x 
			x = min px - VIEW_SUBW / 2, x + VIEW_SPEED
		 else
			x = max px + VIEW_SUBW / 2, x - VIEW_SPEED
		x = max 0, (min world_width - width, x)

	if (abs dy) > VIEW_SUBH / 2 
		if py > y 
			y = min py - VIEW_SUBH / 2, y + VIEW_SPEED
		 else 
			y = max py + VIEW_SUBH / 2, y - VIEW_SPEED
		y = max 0, (min world_height - height, y)

	C.camera\setLoc(x+width/2, y+height/2)
	
center_on = (C, px, py) ->
	x,y,width,height,world_width,world_height = _get_components(C)

	move_towards(C, px - width / 2, py - height / 2)

sharp_center_on = (C, px, py) ->
	x,y,width,height,world_width,world_height = _get_components(C)

	if px < width / 2
		px = width / 2
	elseif px > world_width - width / 2
		px = world_width - width / 2

	if py < height / 2
		py = height / 2
	elseif py > world_height - height / 2
		py = world_height - height / 2

	C.camera\setLoc(px, py)

move_delta = (C, dx, dy) ->
	move_towards(C, x + dx, y + dy)

region_covered = (C) ->
	x,y,width,height,world_width,world_height = _get_components(C)

	return x,y, x+width, x+height

tile_region_covered = (C) ->
	x,y,width,height,world_width,world_height = _get_components(C)

	min_x = max(0, x / TILE_SIZE)
	min_y = max(0, y / TILE_SIZE)
	max_x = (min(world_width, x + width)) / TILE_SIZE
	max_y = (min(world_height, y + height)) / TILE_SIZE

	return floor min_x, floor min_y, floor max_x, floor max_y

view_rel_xy = (C, px, py) ->
	x, y = C.camera\getLoc()
	return px - x, py - y

return {:view_is_off_center, :move_towards, :center_on, :sharp_center_on, :move_delta, :region_covered, :tile_region_covered, :view_rel_xy}