import put_text, put_prop from require "@util_draw"
import max, min from math
res = require 'resources'
import data from require "core"

import liber_black12, liber_white12, liber_pale_red12,
    liber_muted_green12, liber_gold12, liber_pale_blue,
    liber_red12 from require '@ui_styles'

import COL_YELLOW, COL_DARK_GREEN from require "ui.Display"

ROW_SLOTS = 4
DRAWN_SLOTS = 24
INVENTORY_WIDTH = ROW_SLOTS * 32

INV_FONT = res.get_bmfont 'Liberation-Mono-12.fnt'

InventoryDrawer = with newtype()
    -- Note: NOT called during create(), but rather during a draw step
    ._init = (V, stat_context, x, y) =>
        @x, @y = x - INVENTORY_WIDTH / 2, y
        @view = V
        @stat_context = stat_context
        @stats = @stat_context.derived
        @inv = @stats.inventory
        @layer = Display.ui_layer

    .grid_xy = (gridx, gridy) => return @x + gridx * 32, @y + gridy * 32

    .draw_text = (textString, gridx, gridy) =>
        MOAIGfxDevice.setPenColor(1,1,1)
        x, y = @grid_xy(gridx, gridy)
        MOAIDraw.drawText INV_FONT, 12, textString, x, y, 1, 0, 0, 0, 0

    .draw_sprite = (key, gridx, gridy) => 
        x, y = @grid_xy(gridx, gridy)
        return data.get_sprite(key)\draw(x, y)

    -- Draw primitives
    .draw_slot = (slot, gridx, gridy) =>
        x, y = @grid_xy(gridx, gridy)
        if slot and slot.equipped
            MOAIGfxDevice.setPenColor(unpack(COL_DARK_GREEN))
            MOAIDraw.fillRect(x,y,x+32,y+32)
        if slot -- Occuiped slot?
            MOAIGfxDevice.setPenColor(0.4,0.4,0.4)
        else
            MOAIGfxDevice.setPenColor(0.2,0.2,0.2)
        MOAIDraw.drawRect(x,y,x+32,y+32)

        if slot
            -- Draw name 
            name, desc = Identification.name_and_description(@stat_context, slot)
            if name\find "Potion"
                @draw_sprite "PotionBase", gridx, gridy
            else 
                @draw_sprite slot.lookup_key, gridx, gridy
            if slot.stackable
                @draw_text tostring(slot.amount), gridx, gridy

    -- Performs either a predraw (object setup) or a draw (primitives only)
    .draw = () =>
        gridx, gridy = 1, 1
        for i=1,DRAWN_SLOTS
            gridx += 1
            @draw_slot(@inv.items[i], gridx, gridy)
            -- Should we go to the next row?
            if gridx > ROW_SLOTS then gridx, gridy = 1, (gridy + 1)

_DRAWER = InventoryDrawer.create()

draw = (V, stat_context, x, y) ->
    -- _DRAWER\_init(V, stat_context, x, y)
    -- _DRAWER\draw()

return {:draw}
