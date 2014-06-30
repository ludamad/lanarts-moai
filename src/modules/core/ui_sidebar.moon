-- /*
--  * Sidebar.moon:
--  *  Handles drawing & state of side bar
--  */

res = require 'resources'
import setup_script_prop, put_text, put_text_center, put_prop from require "@util_draw"
import COL_GREEN, COL_RED, COL_BLUE from require "@ui_colors"

SIDEBAR_WIDTH = 150
STATBAR_OFFSET_X = 32
STATBAR_OFFSET_Y = 32

sidebar_style = with MOAITextStyle.new()
    \setColor 0,0,0 -- Black
    \setFont (res.get_bmfont 'Liberation-Mono-12.fnt')

draw_statbar = (layer, x,y, is_predraw, w,h, backcol, frontcol, statmin, statmax) ->
	ratio = statmin / statmax
	if not is_predraw
	    MOAIGfxDevice.setPenColor(unpack(backcol))
	    MOAIDraw.fillRect(x,y,x+w,y+h)
	    MOAIGfxDevice.setPenColor(unpack(frontcol))
	    MOAIDraw.fillRect(x,y,x+w*ratio,y+h)

	if is_predraw
		textx,texty = x+w/2, y+h/2
		put_text_center layer, sidebar_style, ("%d/%d")\format(statmin, statmax), textx, texty

-- From Lanarts colors:
MANA_BACK_COL = {200/255,200/255,200/255}
XP_BACK_COL = {169/255, 143/255, 100/255}
XP_FRONT_COL = {255/255, 215/255, 11/255}

import level_experience_needed from require "stats.stats.ExperienceCalculation"

draw_statbars = (layer, x, y, is_predraw, stat_context) ->
	stats = stat_context.derived
	w,h = 100, 12
	draw_statbar layer, x,y, is_predraw,
		w,h, COL_RED, COL_GREEN,
		stats.hp, stats.max_hp
	y += 15
	draw_statbar layer, x,y, is_predraw,
		w,h, MANA_BACK_COL, COL_BLUE,
		stats.mp, stats.max_mp

	y += 15
	xp, xp_needed = stats.xp, level_experience_needed(stats.level)
	draw_statbar layer, x,y, is_predraw,
		w,h, XP_BACK_COL, XP_FRONT_COL,
		xp, xp_needed

-- Sidebar pseudo-methods:
sidebar_draw = (is_predraw) =>
	focus = @gamestate.local_player()
	draw_statbars(@layer, @x + STATBAR_OFFSET_X, @y + STATBAR_OFFSET_Y, is_predraw, focus.stat_context)

-- Sidebar constructor:
sidebar_create = (V) -> 
	sidebar = {gamestate: V.gamestate, view: V, map: V.map, layer: V.ui_layer, x: V.cameraw - SIDEBAR_WIDTH, y: 0}
	PROP_PRIORITY = 0
	sidebar.prop = setup_script_prop(sidebar.layer, (() -> sidebar_draw(sidebar)), V.cameraw, V.camerah, PROP_PRIORITY)

	sidebar.predraw = () => sidebar_draw(@, true)
	sidebar.remove = () =>
		@layer\removeProp(@prop)

	return sidebar

return {:SIDEBAR_WIDTH, :sidebar_create}