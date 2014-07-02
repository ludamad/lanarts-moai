import put_image from require "@util_draw"
res = require 'resources'

local layer, w, h, is_draw

logo = res.get_texture 'LANARTS.png'
logo_back = res.get_texture 'LANARTS-transparent.png'

BACK_P, FRONT_P = 0, 1

pass = () ->
	if not is_draw
		put_image layer, logo_back, 0,-h/4 + 10, BACK_P
		put_image layer, logo, -10,-h/4 + 20, FRONT_P

draw_setup = (_layer, _w, _h) ->
	layer, w, h = _layer, _w, _h
	is_draw = false
	pass()

draw_direct = (_layer, _w, _h) ->
	layer, w, h = _layer, _w, _h
	is_draw = true
	pass()

return {:draw_setup, :draw_direct}