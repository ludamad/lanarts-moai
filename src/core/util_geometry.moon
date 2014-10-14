-------------------------------------------------------------------------------
-- Geometry utility functions
-------------------------------------------------------------------------------

import sqrt, atan2 from math

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

object_angle_towards = (obj1, obj2) -> atan2 (obj2.y - obj1.y), (obj2.x - obj1.x)

-- Pseudo-method:
object_bbox = () =>
	return @x - @radius, @y - @radius, @x + @radius, @y + @radius

point_in_bbox = (px, py, x1,y1,x2,y2) ->
	if x1 > px or x2 <= px then return false
	if y1 > py or y2 <= py then return false
	return true

return {:object_distance, :object_towards, :object_bbox, :towards, :point_in_bbox, :object_angle_towards}