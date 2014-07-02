import put_text, put_prop from require "@util_draw"
import max, min from math
import Identification from require "stats.stats"

import data from require "core"

import liber_black12, liber_white12, liber_pale_red12,
    liber_muted_green12, liber_gold12, liber_pale_blue,
    liber_red12 from require '@ui_styles'

import COL_YELLOW, COL_DARK_GREEN from require "@ui_colors"

ROW_SLOTS = 4
DRAWN_SLOTS = 24
INVENTORY_WIDTH = ROW_SLOTS * 32

InventoryDrawer = with newtype()
    -- Note: NOT called during create(), but rather during a draw step
    ._init = (V, stat_context, is_predraw, x, y) =>
        @x, @y = x - INVENTORY_WIDTH / 2, y
        @view = V
        @stat_context = stat_context
        @stats = @stat_context.derived
        @inv = @stats.inventory
        @layer = V.ui_layer
        @is_predraw = is_predraw

    .grid_xy = (gridx, gridy) => return @x + gridx * 32, @y + gridy * 32

    .put_text = (textString, gridx, gridy) =>
        put_text(@layer, liber_white12, textString, @grid_xy(gridx, gridy))

    .put_sprite = (key, gridx, gridy) => 
        x, y = @grid_xy(gridx, gridy)
        return data.get_sprite(key)\put_prop(@layer, x + 32/2, y + 32/2)

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

        -- put_prop

    -- Setup complex (text and sprite) objects
    .pre_draw_slot = (slot, gridx, gridy) =>
        if not slot then return
        name, desc = Identification.name_and_description(@stat_context, slot)
        if slot.stackable
            @put_text tostring(slot.amount), gridx, gridy
        @put_sprite slot.lookup_key, gridx, gridy
        if name\find "Potion"
            @put_sprite "PotionBase", gridx, gridy

        -- slot.equipped
        -- slot.type

    .pass_slot = (...) => if @is_predraw then @pre_draw_slot(...) else @draw_slot(...)

    -- Performs either a predraw (object setup) or a draw (primitives only)
    .pass = () =>
        gridx, gridy = 1, 1
        for i=1,DRAWN_SLOTS
            gridx += 1
            @pass_slot(@inv.items[i], gridx, gridy)
            -- Should we go to the next row?
            if gridx > ROW_SLOTS then gridx, gridy = 1, (gridy + 1)

_DRAWER = InventoryDrawer.create()

pre_draw = (V, stat_context, x, y) ->
    _DRAWER\_init(V, stat_context, true, x, y)
    _DRAWER\pass()

draw = (V, stat_context, x, y) ->
    _DRAWER\_init(V, stat_context, false, x, y)
    _DRAWER\pass()

return {:pre_draw, :draw}


-- static void draw_player_inventory_slot(GameState* gs, ItemSlot& itemslot, int x,
--         int y) {
--     if (itemslot.amount() > 0) {
--         ItemEntry& ientry = itemslot.item_entry();
--         ientry.item_image().draw(Pos(x,y));
--         if (ientry.stackable) {
--             gs->font().drawf(COL_WHITE, Pos(x+1, y+1), "%d", itemslot.amount());
--         }
--     }
-- }

-- static void draw_player_inventory(GameState* gs, Inventory& inv,
--         const BBox& bbox, int min_slot, int max_slot, int slot_selected = -1) {
--     int mx = gs->mouse_x(), my = gs->mouse_y();
--     int slot = min_slot;
--     for (int y = bbox.y1; y < bbox.y2; y += TILE_SIZE) {
--         for (int x = bbox.x1; x < bbox.x2; x += TILE_SIZE) {
--             if (slot >= max_slot || slot >= inv.max_size())
--                 break;

--             ItemSlot& itemslot = inv.get(slot);

--             BBox slotbox(x, y, x + TILE_SIZE, y + TILE_SIZE);
--             Colour outline_col(COL_UNFILLED_OUTLINE);
--             if (itemslot.amount() > 0 && slot != slot_selected) {
--                 if (itemslot.is_equipped()) {
--                     ldraw::draw_rectangle(Colour(25, 50, 10), slotbox);
--                 }
--                 outline_col = COL_FILLED_OUTLINE;

--                 if (slotbox.contains(mx, my)) {
--                     outline_col = COL_PALE_YELLOW;
--                     draw_console_item_description(gs, itemslot.item,
--                             itemslot.item_entry());
--                 }
--             }

--             if (slot != slot_selected)
--                 draw_player_inventory_slot(gs, itemslot, x, y);
--             //draw rectangle over item edges
--             ldraw::draw_rectangle_outline(outline_col, slotbox);

--             slot++;
--         }
--     }

--     if (slot_selected != -1) {
--         draw_player_inventory_slot(gs, inv.get(slot_selected),
--                 gs->mouse_x() - TILE_SIZE / 2, gs->mouse_y() - TILE_SIZE / 2);
--     }
-- }

-- static int get_itemslotn(Inventory& inv, const BBox& bbox, int mx, int my) {
--     if (!bbox.contains(mx, my)) {
--         return -1;
--     }

--     int posx = (mx - bbox.x1) / TILE_SIZE;
--     int posy = (my - bbox.y1) / TILE_SIZE;
--     int slot = 5 * posy + posx;

--     if (slot < 0 || slot >= inv.max_size())
--         return -1;

--     return slot;
-- }

-- const int ITEMS_PER_PAGE = 40;

-- void InventoryContent::draw(GameState* gs) const {
--     PlayerInst* p = gs->local_player();

--     Inventory& inv = p->inventory();
--     int min_item = ITEMS_PER_PAGE * page_number, max_item = min_item
--             + ITEMS_PER_PAGE;
--     draw_player_inventory(gs, inv, bbox, min_item, max_item, slot_selected);
-- }

-- int InventoryContent::amount_of_pages(GameState* gs) {
--     PlayerInst* p = gs->local_player();

--     int items_n = p->inventory().last_filled_slot();
--     /* Add ITEMS_PER_PAGE - 1 so that 0 spells need 0 pages, 1 spell needs 1 page, etc*/
--     int item_pages = (items_n + ITEMS_PER_PAGE - 1) / ITEMS_PER_PAGE;

--     return item_pages;
-- }

-- bool InventoryContent::handle_io(GameState* gs, ActionQueue& queued_actions) {
--     PlayerInst* p = gs->local_player();
--     Inventory& inv = p->inventory();
--     int mx = gs->mouse_x(), my = gs->mouse_y();
--     bool within_inventory = bbox.contains(mx, my);

--     /* Use an item */
--     if (gs->mouse_left_click() && within_inventory) {

--         int slot = get_itemslotn(inv, bbox, mx, my);
--         if (slot >= 0 && slot < INVENTORY_SIZE && inv.get(slot).amount() > 0) {
--             queued_actions.push_back(
--                     game_action(gs, p, GameAction::USE_ITEM, slot, p->x, p->y));
--             return true;
--         }
--     }

--     /* Start dragging an item */
--     if (gs->mouse_right_click() && within_inventory) {
--         int slot = get_itemslotn(inv, bbox, mx, my);
--         if (slot != -1 && inv.slot_filled(slot)) {
--             slot_selected = slot;
--             return true;
--         }
--     }

--     /* Drop a dragged item */
--     if (slot_selected > -1 && gs->mouse_right_release()) {
--         int slot = get_itemslotn(inv, bbox, mx, my);

--         if (slot == -1 || slot == slot_selected) {
--             queued_actions.push_back(
--                     game_action(gs, p, GameAction::DROP_ITEM, slot_selected));
--         } else {
--             queued_actions.push_back(
--                     game_action(gs, p, GameAction::REPOSITION_ITEM,
--                             slot_selected, 0, 0, slot));
--         }
--         return true;
--     }

--     return false;
-- }

