-------------------------------------------------------------------------------
-- Geometry utility functions
-------------------------------------------------------------------------------

import sqrt from math

object_distance = (obj1, obj2) ->
	dx, dy = obj1.x-obj2.x,obj1.y-obj2.y
	return sqrt(dx*dx + dy*dy) - obj1.radius - obj2.radius

towards = (x1, y1, x2, y2, mag) ->
	dx, dy = (x2 - x1), (y2 - y1)
	dist = sqrt(dx*dx + dy*dy)
	return dx/dist*mag, dy/dist*mag

object_towards = (obj1, obj2, mag = 1) ->
	dx, dy = (obj2.x - obj1.x), (obj2.y - obj1.y)
	dist = sqrt(dx*dx + dy*dy)
	return dx/dist*mag, dy/dist*mag

-- Pseudo-method:
object_bbox = () =>
	return @x - @radius, @y - @radius, @x + @radius, @y + @radius

return {:object_distance, :object_towards, :object_bbox, :towards}