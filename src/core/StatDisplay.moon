import data from require 'core'
draw_item = (item, x, y, origin) ->
	data.get_sprite(item.lookup_key)\draw()