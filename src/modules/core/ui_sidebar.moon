--
-- Sidebar.moon:
--  Handles drawing & state of side bar
--

res = require 'resources'
import setup_script_prop from require '@util_draw'
import put_text, put_text_center, put_prop from require "ui.Display"
import COL_GREEN, COL_RED, COL_BLUE, COL_PALE_RED, COL_GOLD, COL_PALE_BLUE, COL_MUTED_GREEN from require "@ui_colors"
import default_cooldown_table from require "stats.stats.CooldownTypes"
import ui_minimap, ui_inventory, util_draw_stats from require "core"

import StatContext from require "stats"

SIDEBAR_WIDTH = 150
STATBAR_OFFSET_X = 25
STATBAR_OFFSET_Y = 32

SIDEBAR_FONT = res.get_bmfont 'Liberation-Mono-12.fnt'

sidebar_style = with MOAITextStyle.new()
    \setColor 0,0,0 -- Black
    \setFont (res.get_bmfont 'Liberation-Mono-12.fnt')

sidebar_style_white = with MOAITextStyle.new()
    \setColor 1,1,1 -- White
    \setFont (res.get_bmfont 'Liberation-Mono-12.fnt')

sidebar_style_pale_red = with MOAITextStyle.new()
    \setColor(unpack(COL_PALE_RED))
    \setFont (res.get_bmfont 'Liberation-Mono-12.fnt')

sidebar_style_muted_green = with MOAITextStyle.new()
    \setColor(unpack(COL_MUTED_GREEN))
    \setFont (res.get_bmfont 'Liberation-Mono-12.fnt')

sidebar_style_gold = with MOAITextStyle.new()
    \setColor(unpack(COL_GOLD))
    \setFont (res.get_bmfont 'Liberation-Mono-12.fnt')

sidebar_style_pale_blue = with MOAITextStyle.new()
    \setColor(unpack(COL_PALE_BLUE))
    \setFont (res.get_bmfont 'Liberation-Mono-12.fnt')

sidebar_style_red = with MOAITextStyle.new()
    \setColor(0.3,0.0,0.0) -- greyish red
    \setFont (res.get_bmfont 'Liberation-Mono-12.fnt')

draw_statbar = (layer, x,y, is_predraw, w,h, backcol, frontcol, statmin, statmax) ->
    ratio = statmin / statmax
    if not is_predraw
        MOAIGfxDevice.setPenColor(unpack(backcol))
        MOAIDraw.fillRect(x,y,x+w,y+h)
        MOAIGfxDevice.setPenColor(unpack(frontcol))
        MOAIDraw.fillRect(x,y,x+w*ratio,y+h)

        textx,texty = x+w/2, y+h/2
        MOAIGfxDevice.setPenColor(0,0,0)
        MOAIDraw.drawText SIDEBAR_FONT, 12, ("%d/%d")\format(statmin, statmax), textx, texty, 1, 0,0, 0.5, 0.5

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

    y += 15
    cooldown, cooldown_max = (StatContext.get_cooldown stat_context, "REST_ACTION"), default_cooldown_table.REST_ACTION
    if not is_predraw
        ratio = cooldown / cooldown_max
        MOAIGfxDevice.setPenColor(ratio, 1.0 - ratio, 0.0)
        MOAIDraw.fillRect(x,y,x+w,y+h)
    else
        textx,texty = x+w/2, y+h/2
        put_text_center layer, (if cooldown == 0 then sidebar_style else sidebar_style_red),
            (if cooldown == 0 then "can rest" else "cannot rest"), textx, texty

sidebar_put_text = (text, x, y, style = sidebar_style) =>
    put_text @layer, style, text, x, y

sidebar_put_text_center = (text, x, y, style = sidebar_style) =>
    put_text_center @layer, style, text, x, y

styles = {sidebar_style_white, sidebar_style_pale_red, sidebar_style_muted_green}

sidebar_draw_player_base_stats = (name, _class, stat_context, x, y) =>
    stats = stat_context.derived
    sidebar_put_text_center(@, ("'%s'")\format(name), x + SIDEBAR_WIDTH / 2 - 5, y + 15, sidebar_style_pale_blue)
    x1 = x + 5
    x2 = x1 + SIDEBAR_WIDTH / 2
    y1 = y + 95

    sidebar_put_text_center(@, ("Unknown Dungeon")\format(stats.level), x + SIDEBAR_WIDTH / 2, y1 + 5, sidebar_style_white)
    y1 += 15
    sidebar_put_text(@, _class.name, x1, y1, sidebar_style_gold)
    sidebar_put_text(@, ("Level %d")\format(stats.level), x2, y1, sidebar_style_muted_green)
    y1 += 15
    sidebar_put_text(@, ("Deaths 0")\format(stats.level), x1, y1, sidebar_style_pale_red)
    sidebar_put_text(@, ("Kills 0")\format(stats.level), x2, y1, sidebar_style_white)

-- Sidebar pseudo-methods:
sidebar_draw = (is_predraw) =>
    focus = @gamestate.local_player()
    if not focus then return
    draw_statbars(@layer, @x + STATBAR_OFFSET_X, @y + STATBAR_OFFSET_Y, is_predraw, focus.stat_context)
    @minimap\draw()
    -- Content position:
    cx, cy = @x + 12, @y + 260
    if is_predraw
        sidebar_draw_player_base_stats(@, focus.name, focus.class, focus.stat_context, @x, @y)
        --util_draw_stats.put_stats(focus.stat_context.derived, @layer, styles, cx, cy, 0, 15)
    else
        ui_inventory.draw(@view, focus.stat_context, cx, cy)
-- Sidebar constructor:
sidebar_create = (V) -> 
    sidebar = {gamestate: V.gamestate, view: V, map: V.map, layer: V.ui_layer, x: V.cameraw - SIDEBAR_WIDTH, y: 0}
    sidebar.minimap = ui_minimap.MiniMap.create(V, sidebar.x + SIDEBAR_WIDTH / 2, sidebar.y + 200)

    PROP_PRIORITY = 0
    sidebar.draw = () =>
        sidebar_draw(@)
        MOAIGfxDevice.setPenColor(1,1,1,1)

    sidebar.prop = setup_script_prop(sidebar.layer, (() -> sidebar\draw()), V.cameraw, V.camerah, PROP_PRIORITY)

    sidebar.predraw = () => 
        sidebar_draw(@, true)
        @minimap\pre_draw()

    sidebar.remove = () =>
        @layer\removeProp(@prop)
        @minimap\remove()

    return sidebar

return {:SIDEBAR_WIDTH, :sidebar_create}
