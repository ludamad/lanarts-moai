actionbar_draw = (M, obj) ->
	stats = obj.stat_context
	weapon = stats\get_equipped_item("WEAPON")
	weapon


actionbar_step = (M, obj) ->

return {:actionbar_draw, :actionbar_step}