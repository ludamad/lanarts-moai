--
-- Sidebar.moon:
--  Handles drawing & state of side bar
--

res = require 'resources'
data = require 'core.data'
statsystem = require "statsystem"
import setup_script_prop from require '@util_draw'
import Display from require "ui"
import put_text, put_text_center, put_prop from Display
import ui_minimap, ui_inventory, ui_skills from require "core"
import level_experience_needed from require "statsystem"

import point_in_bbox from require "@util_geometry"
import key_down, mouse_xy, mouse_left_pressed from require "user_io"

SIDEBAR_WIDTH = 150
STATBAR_OFFSET_X = 25
STATBAR_OFFSET_Y = 16
SIDEBAR_PROP_PRIORITY = 0

SIDEBAR_FONT = res.get_bmfont 'Liberation-Mono-12.fnt'

-- From Lanarts colors:
MANA_BACK_COL = {200/255,200/255,200/255}
XP_BACK_COL = {169/255, 143/255, 100/255}
XP_FRONT_COL = {255/255, 215/255, 11/255}
ENERGY_BACK_COL = {169/255, 143/255, 100/255}
ENERGY_FRONT_COL = Display.COL_MEDIUM_PURPLE

CAN_REST_COL = Display.COL_BLACK
CANT_REST_COL = {0.3,0.0,0.0}

Sidebar = newtype {
    init: (V) =>
        @gamestate, @map = V.gamestate, V.map
        disp_w, disp_h = Display.display_size()
        @x, @y = disp_w - SIDEBAR_WIDTH,  0
        @minimap = ui_minimap.MiniMap.create(@map, @x + SIDEBAR_WIDTH / 2, @y + 240)
        @_set_contents "items"
        @current_contents = "items"
        Display.display_add_draw_func (() -> @draw())
    predraw: () =>

    _drawText: (...) => Display.drawText(SIDEBAR_FONT, ...)
    _drawTextXCenter: (...) => Display.drawTextXCenter(SIDEBAR_FONT, ...)
    _drawTextYCenter: (...) => Display.drawTextYCenter(SIDEBAR_FONT, ...)
    _drawTextCenter: (...) => Display.drawTextCenter(SIDEBAR_FONT, ...)
    _draw_stats: (stats, x, y) =>


    _draw_statbar: (x,y, w,h, backcol, frontcol, statmin, statmax, draw_num=true) =>
        ratio = statmin / statmax
        MOAIGfxDevice.setPenColor(unpack(backcol))
        MOAIDraw.fillRect(x,y,x+w,y+h)
        MOAIGfxDevice.setPenColor(unpack(frontcol))
        MOAIDraw.fillRect(x,y,x+w*ratio,y+h)

        if draw_num 
            textx,texty = x+w/2, y+h/2
            @_drawTextCenter ("%d/%d")\format(statmin, statmax), textx, texty, Display.COL_BLACK

    -- _xp_text: Display.colorEscapeCode(Display.COL_YELLOW) .. "XP" .. Display.colorEscapeCode(Display.COL_WHITE)
    _draw_stats: (stats, x, y) =>
        x1,x2 = x - 15, x - 20 + (SIDEBAR_WIDTH) / 2
        w,h = 100, 12

        ---- Long term stats

        -- Draw name 
        @_drawTextXCenter "#{stats.name}", x2-5, y, Display.COL_PALE_BLUE
        y += 15
        -- Draw location name
        @_drawTextXCenter @map.map_label, x2-5, y, Display.COL_BROWN
        y += 15
        -- Draw level and class title
        @_drawText "Level #{stats.level}", x1, y, Display.COL_MUTED_GREEN 
        @_drawText stats.class_name, x2, y, Display.COL_BABY_BLUE
        y += 15

        -- Draw experience bar
        xp, xp_needed = stats.xp, level_experience_needed(stats.level)

        @_drawTextYCenter ("XP %d%%")\format(xp*100/xp_needed), x1, y+h/2, Display.COL_GOLD
        @_draw_statbar x2,y+h/4, w/2,h/2, XP_BACK_COL, XP_FRONT_COL,
            xp, xp_needed, false

        -- Draw deaths & kills
        y += 15
        @_drawText "Deaths #{stats.level}", x1, y, Display.COL_PALE_RED 
        @_drawText "Kills #{stats.level}", x2, y, Display.COL_WHITE 
 
        y += 20

        cooldown, cooldown_max = (stats.cooldowns.rest_cooldown), statsystem.REST_COOLDOWN
        ratio = cooldown / cooldown_max
        alert_color = {ratio, (1.0-ratio)/2, (1.0 - ratio)}
        alert_text = (if cooldown == 0 then "Can Rest" else "Alert")
        if stats.is_resting
            alert_text = "Resting"
            alert_color = Display.COL_GREEN
        @_drawTextCenter alert_text, x2-5, y+h/2, alert_color
        y += 15
        ---- Short term stats
        @_drawTextYCenter "HP", x1, y+h/2, Display.COL_GREEN
        @_draw_statbar x+5,y, w,h, Display.COL_RED, Display.COL_GREEN,
            stats.attributes.hp, stats.attributes.max_hp
        y += 15
        @_drawTextYCenter "MP", x1, y+h/2, Display.COL_CYAN
        @_draw_statbar x+5,y, w,h, MANA_BACK_COL, Display.COL_CYAN,
            stats.attributes.mp, stats.attributes.max_mp
        y += 15
        @_drawTextYCenter "EP", x1, y+h/2, Display.COL_MEDIUM_PURPLE
        @_draw_statbar x+5,y, w,h, ENERGY_BACK_COL, ENERGY_FRONT_COL,
            stats.attributes.ep, stats.attributes.max_ep

    -- Side bar switching logic: ---
    _set_contents: (content_string) =>
        x, y = @x + SIDEBAR_WIDTH / 2, @y + 300
        @content_string = content_string
        @switchable_content = switch @content_string
            when "items"
                ui_inventory.InventoryUI.create(@gamestate, x, y)
            when "skills"
                ui_skills.SkillsUI.create(@gamestate\local_player().stats, x, y)

    ICON_MAGIC1: data.get_sprite 'icon-magic1'
    ICON_MAGIC2: data.get_sprite 'icon-magic2'
    ICON_ITEMS: data.get_sprite 'icon-items'
    ICON_ITEMS: data.get_sprite 'icon-items'
    ICON_SKILLS: data.get_sprite 'icon-skills'
    ICON_ENEMIES: data.get_sprite 'icon-enemies'
    ICON_CONFIG: data.get_sprite 'icon-config'

    _draw_sidebar_switcher: (spr, x, y, content_string) =>
        mx, my = mouse_xy()
        color = Display.COL_WHITE
        if @content_string == content_string
            color = Display.COL_YELLOW
        elseif point_in_bbox(mx, my, x-16, y-16, x+16,y+16)
            color = Display.COL_PALE_YELLOW
            if mouse_left_pressed()
                @_set_contents content_string
        spr\draw(x, y, 1, 1, 0.5, 0.5, unpack(color))

    _draw_sidebar_switchers: () =>
        -- Draw sidebar-switching icons:
        disp_w,disp_h = Display.display_size()
        -- Three on top row
        xx, yy = @x + SIDEBAR_WIDTH/2 - 34, disp_h - 52
        @_draw_sidebar_switcher(@ICON_MAGIC1, xx, yy, "spells")
        xx += 34
        @_draw_sidebar_switcher(@ICON_ITEMS, xx, yy, "items")
        xx += 34
        @_draw_sidebar_switcher(@ICON_SKILLS, xx, yy, "skills")
        -- Two on bottom row
        xx, yy = @x + SIDEBAR_WIDTH/2 - 34/2, yy + 34
        @_draw_sidebar_switcher(@ICON_CONFIG, xx, yy, "config")
        xx += 34
        @_draw_sidebar_switcher(@ICON_ENEMIES, xx, yy, "enemies")

    -- Main draw function ---
    draw: () =>
        focus = @gamestate\local_player()
        if not focus then return
        @_draw_stats(focus.stats, @x + STATBAR_OFFSET_X, @y + STATBAR_OFFSET_Y)
        @minimap\draw()
        @switchable_content\draw()
        @_draw_sidebar_switchers()
    clear: () =>
        @remove()
    remove: () =>
        Display.ui_layer\removeProp @prop
}

return {:SIDEBAR_WIDTH, :Sidebar}
