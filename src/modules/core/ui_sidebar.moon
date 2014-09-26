--
-- Sidebar.moon:
--  Handles drawing & state of side bar
--

res = require 'resources'
statsystem = require "statsystem"
import setup_script_prop from require '@util_draw'
import Display from require "ui"
import put_text, put_text_center, put_prop from Display
import ui_minimap, ui_inventory from require "core"
import level_experience_needed from require "statsystem"

SIDEBAR_WIDTH = 150
STATBAR_OFFSET_X = 25
STATBAR_OFFSET_Y = 32
SIDEBAR_PROP_PRIORITY = 0

SIDEBAR_FONT = res.get_bmfont 'Liberation-Mono-12.fnt'

-- From Lanarts colors:
MANA_BACK_COL = {200/255,200/255,200/255}
XP_BACK_COL = {169/255, 143/255, 100/255}
XP_FRONT_COL = {255/255, 215/255, 11/255}

CAN_REST_COL = Display.COL_BLACK
CANT_REST_COL = {0.3,0.0,0.0}

Sidebar = newtype {
    init: (V) =>
        @gamestate, @map = V.gamestate, V.map
        disp_w, disp_h = Display.display_size()
        @x, @y = disp_w - SIDEBAR_WIDTH,  0
        @minimap = ui_minimap.MiniMap.create(@map, @x + SIDEBAR_WIDTH / 2, @y + 200)
        Display.display_add_draw_func (() -> @draw())
    predraw: () =>

    _drawText: (...) => Display.drawText(SIDEBAR_FONT, ...)
    _drawTextXCenter: (...) => Display.drawTextXCenter(SIDEBAR_FONT, ...)
    _drawTextCenter: (...) => Display.drawTextCenter(SIDEBAR_FONT, ...)
    _draw_stats: (stats, x, y) =>
        @_drawTextXCenter "'#{stats.name}'", x + SIDEBAR_WIDTH / 2 - 5, y + 15, Display.COL_PALE_BLUE
        x1 = x + 5
        x2 = x1 + SIDEBAR_WIDTH / 2
        y1 = y + 95

        @_drawTextXCenter "Unknown Dungeon", x + SIDEBAR_WIDTH / 2, y1, Display.COL_WHITE
        y1 += 15
        @_drawText stats.class_name, x1, y1, Display.COL_GOLD 
        @_drawText "Level #{stats.level}", x2, y1, Display.COL_MUTED_GREEN 
        y1 += 15
        @_drawText "Deaths #{stats.level}", x1, y1, Display.COL_PALE_RED 
        @_drawText "Kills #{stats.level}", x2, y1, Display.COL_WHITE 


    _draw_statbar: (x,y, w,h, backcol, frontcol, statmin, statmax) =>
        ratio = statmin / statmax
        MOAIGfxDevice.setPenColor(unpack(backcol))
        MOAIDraw.fillRect(x,y,x+w,y+h)
        MOAIGfxDevice.setPenColor(unpack(frontcol))
        MOAIDraw.fillRect(x,y,x+w*ratio,y+h)

        textx,texty = x+w/2, y+h/2
        @_drawTextCenter ("%d/%d")\format(statmin, statmax), textx, texty, Display.COL_BLACK

    _draw_statbars: (stats, x, y) =>
        w,h = 100, 12
        @_draw_statbar x,y, w,h, Display.COL_RED, Display.COL_GREEN,
            stats.attributes.hp, stats.attributes.max_hp
        y += 15
        @_draw_statbar x,y, w,h, MANA_BACK_COL, Display.COL_BLUE,
            stats.attributes.mp, stats.attributes.max_mp

        y += 15
        xp, xp_needed = stats.xp, level_experience_needed(stats.level)
        @_draw_statbar x,y, w,h, XP_BACK_COL, XP_FRONT_COL,
            xp, xp_needed

        y += 15
        cooldown, cooldown_max = (stats.cooldowns.rest_cooldown), statsystem.REST_COOLDOWN
        -- Draw the rest indicator box
        ratio = cooldown / cooldown_max
        MOAIGfxDevice.setPenColor(ratio, 1.0 - ratio, 0.0)
        MOAIDraw.fillRect(x,y,x+w,y+h)
        -- Draw "can rest"/"cannot rest"
        textx,texty = x+w/2, y+h/2
        @_drawTextCenter (if cooldown == 0 then "can rest" else "cannot rest"), textx, texty, (if cooldown == 0 then CAN_REST_COL else CANT_REST_COL)

    draw: () =>
        focus = @gamestate.local_player()
        if not focus then return
        @_draw_stats(focus.stats, @x, @y)
        @_draw_statbars(focus.stats, @x + STATBAR_OFFSET_X, @y + STATBAR_OFFSET_Y)
        @minimap\draw()

    remove: () =>
        Display.ui_layer\removeProp @prop
}


-- sidebar_style = with MOAITextStyle.new()
--     \setColor 0,0,0 -- Black
--     \setFont (res.get_bmfont 'Liberation-Mono-12.fnt')

-- sidebar_style_white = with MOAITextStyle.new()
--     \setColor 1,1,1 -- White
--     \setFont (res.get_bmfont 'Liberation-Mono-12.fnt')

-- sidebar_style_pale_red = with MOAITextStyle.new()
--     \setColor(unpack(COL_PALE_RED))
--     \setFont (res.get_bmfont 'Liberation-Mono-12.fnt')

-- sidebar_style_muted_green = with MOAITextStyle.new()
--     \setColor(unpack(COL_MUTED_GREEN))
--     \setFont (res.get_bmfont 'Liberation-Mono-12.fnt')

-- sidebar_style_gold = with MOAITextStyle.new()
--     \setColor(unpack(COL_GOLD))
--     \setFont (res.get_bmfont 'Liberation-Mono-12.fnt')

-- sidebar_style_pale_blue = with MOAITextStyle.new()
--     \setColor(unpack(COL_PALE_BLUE))
--     \setFont (res.get_bmfont 'Liberation-Mono-12.fnt')

-- sidebar_style_red = with MOAITextStyle.new()
--     \setColor(0.3,0.0,0.0) -- greyish red
--     \setFont (res.get_bmfont 'Liberation-Mono-12.fnt')

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

-- -- From Lanarts colors:
-- MANA_BACK_COL = {200/255,200/255,200/255}
-- XP_BACK_COL = {169/255, 143/255, 100/255}
-- XP_FRONT_COL = {255/255, 215/255, 11/255}


draw_statbars = (layer, x, y, is_predraw, stats) ->
    w,h = 100, 12
    draw_statbar layer, x,y, is_predraw,
        w,h, Display.COL_RED, COL_GREEN,
        stats.attributes.hp, stats.attributes.max_hp
    y += 15
    draw_statbar layer, x,y, is_predraw,
        w,h, MANA_BACK_COL, COL_BLUE,
        stats.attributes.mp, stats.attributes.max_mp

    y += 15
    xp, xp_needed = stats.xp, level_experience_needed(stats.level)
    draw_statbar layer, x,y, is_predraw,
        w,h, XP_BACK_COL, XP_FRONT_COL,
        xp, xp_needed

    y += 15
    cooldown, cooldown_max = (stats.cooldowns.rest_cooldown), statsystem.REST_COOLDOWN
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

-- styles = {sidebar_style_white, sidebar_style_pale_red, sidebar_style_muted_green}

sidebar_draw_player_base_stats = (stats, x, y) =>
    sidebar_put_text_center(@, ("'%s'")\format(stats.name), x + SIDEBAR_WIDTH / 2 - 5, y + 15, sidebar_style_pale_blue)
    x1 = x + 5
    x2 = x1 + SIDEBAR_WIDTH / 2
    y1 = y + 95

    sidebar_put_text_center(@, "Unknown Dungeon", x + SIDEBAR_WIDTH / 2, y1 + 5, sidebar_style_white)
    y1 += 15
    sidebar_put_text(@, stats.class_name, x1, y1, sidebar_style_gold)
    sidebar_put_text(@, ("Level %d")\format(stats.level), x2, y1, sidebar_style_muted_green)
    y1 += 15
    sidebar_put_text(@, ("Deaths 0")\format(stats.level), x1, y1, sidebar_style_pale_red)
    sidebar_put_text(@, ("Kills 0")\format(stats.level), x2, y1, sidebar_style_white)

-- Sidebar pseudo-methods:
sidebar_draw = (is_predraw) =>
    focus = @gamestate.local_player()
    if not focus then return
    draw_statbars(@layer, @x + STATBAR_OFFSET_X, @y + STATBAR_OFFSET_Y, is_predraw, focus.stats)
    @minimap\draw()
    -- Content position:
    cx, cy = @x + 12, @y + 260
    if is_predraw
        print "HI"
        --util_draw_stats.put_stats(focus.stat_context.derived, @layer, styles, cx, cy, 0, 15)
    else
        sidebar_draw_player_base_stats(@, focus.stats, @x, @y)
        ui_inventory.draw(@view, focus.stats, cx, cy)
-- Sidebar constructor:
sidebar_create = (V) -> 
    sidebar = {gamestate: V.gamestate, view: V, map: V.map, layer: Display.ui_layer, x: V.cameraw - SIDEBAR_WIDTH, y: 0}
    sidebar.minimap = ui_minimap.MiniMap.create(V, sidebar.x + SIDEBAR_WIDTH / 2, sidebar.y + 200)

    PROP_PRIORITY = 0
    sidebar.draw = () =>
        sidebar_draw(@)
        MOAIGfxDevice.setPenColor(1,1,1,1)

    sidebar.prop = setup_script_prop(sidebar.layer, (() -> sidebar\draw()), V.cameraw, V.camerah, PROP_PRIORITY)

    sidebar.predraw = () => 
        sidebar_draw(@, true)

    sidebar.remove = () =>
        @layer\removeProp(@prop)
        @minimap\remove()

    return sidebar

return {:SIDEBAR_WIDTH, :sidebar_create, :Sidebar}
