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
        @minimap = ui_minimap.MiniMap.create(@map, @x + SIDEBAR_WIDTH / 2, @y + 220)
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

return {:SIDEBAR_WIDTH, :Sidebar}
