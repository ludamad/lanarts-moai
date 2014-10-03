import put_text, put_prop from require "@util_draw"
import max, min from math
res = require 'resources'
import data from require "core"

import COL_YELLOW, COL_DARK_GREEN from require "ui.Display"

ROW_SLOTS = 4
DRAWN_SLOTS = 24
INVENTORY_WIDTH = ROW_SLOTS * 32

INV_FONT = res.get_bmfont 'Liberation-Mono-12.fnt'

InventoryUI = newtype {
    -- Note: NOT called during create(), but rather during a draw step
    init: (G, x, y) =>
        @x, @y = x - INVENTORY_WIDTH, y
        @gamestate = G

    grid_xy: (gridx, gridy) => return @x + gridx * 32, @y + gridy * 32

    draw_text: (textString, gridx, gridy) =>
        MOAIGfxDevice.setPenColor(1,1,1)
        x, y = @grid_xy(gridx, gridy)
        MOAIDraw.drawText INV_FONT, 12, textString, x, y, 1, 0, 0, 0, 0

    draw_sprite: (key, gridx, gridy) => 
        x, y = @grid_xy(gridx, gridy)
        return data.get_sprite(key)\draw(x, y)

    -- Draw primitives
    draw_slot: (slot, gridx, gridy) =>
        x, y = @grid_xy(gridx, gridy)
        if slot and slot.is_equipment and slot.is_equipped
            MOAIGfxDevice.setPenColor(unpack(COL_DARK_GREEN))
            MOAIDraw.fillRect(x,y,x+32,y+32)
        if slot -- Occuiped slot?
            MOAIGfxDevice.setPenColor(0.4,0.4,0.4)
        else
            MOAIGfxDevice.setPenColor(0.2,0.2,0.2)
        MOAIDraw.drawRect(x,y,x+32,y+32)

        if slot
            -- Draw name 
            if slot.item_type == "Potion"
                @draw_sprite "PotionBase", gridx, gridy
            else 
                @draw_sprite slot.id_sprite, gridx, gridy
            if slot.is_stackable
                @draw_text tostring(slot.amount), gridx, gridy

    -- Performs either a predraw (object setup) or a draw (primitives only)
    draw: () =>
        focus = @gamestate.local_player()
        gridx, gridy = 1, 1
        for i=1,DRAWN_SLOTS
            gridx += 1
            @draw_slot(focus.stats.inventory.slots[i], gridx, gridy)
            -- Should we go to the next row?
            if gridx > ROW_SLOTS then gridx, gridy = 1, (gridy + 1)
}

return {:InventoryUI}
