local Display = require "ui.Display"
local resources = require 'resources'
local user_io = require 'user_io'
local ErrorReporting = require 'system.ErrorReporting'

-- More ad hoc utilities without a home, yet

function _G.to_tilexy(xy)
    return {math.floor(xy[1]/32), math.floor(xy[2]/32)}
end
function _G.to_worldxy(xy)
    return {xy[1]*32+16, xy[2]*32+16}
end

--- Return whether the mouse has been right clicked within a bounding box.
function _G.bbox_right_clicked(bbox, origin)
    return user_io.mouse_right_pressed() and bbox_mouse_over(bbox, origin)
end

--- Return whether the mouse has been left clicked within a bounding box.
function _G.bbox_left_clicked(bbox, origin)
    return user_io.mouse_left_pressed() and bbox_mouse_over(bbox, origin)
end

--- Return whether the mouse is within a bounding box.
function _G.bbox_mouse_over(bbox, origin)
    return bbox_contains(Display.shift_origin(bbox, origin or Display.LEFT_TOP), {user_io.mouse_xy()} )
end

--- Return whether the mouse is within a bounding box defined by xy and size.
function _G.mouse_over(xy, size, origin)
    -- if type(xy) == 'number' then
    -- print(ErrorReporting.traceback(), xy, size, origin) end
    return bbox_mouse_over(bbox_create(xy, size), origin)
end

function _G.origin_valid(origin)
    return origin[1] >= 0 and origin[1] <= 1 and origin[2] >= 0 and origin[2] <= 1
end

--- Draw parts of text colored differently
-- @usage draw_colored_parts(font, Display.LEFT_TOP, {0,0}. {COL_RED, "hi "}, {COL_BLUE, "there"} )
function _G.draw_colored_parts(font, origin, xy, ...)
    local rx, ry = 0, 0

    local parts = {...}
    local x_coords = {}

    -- First calculate relative positions
    for idx, part in ipairs(parts) do
        local color, text = unpack(part)
        local w, h = unpack( font:draw_size(text) )
        x_coords[idx] = rx
        rx = rx + w
    end

    local adjusted_origin = {0, origin[2]}
    local adjusted_x = xy[1] - rx * origin[1]

    -- Next draw according to origin
    for idx, part in ipairs(parts) do
        local color, text = unpack(part)
        local position = {adjusted_x + x_coords[idx],  xy[2]} 
        font:draw( { color = color, origin = adjusted_origin }, position, text)
    end

    return rx -- return final width for further chaining
end

--- Load a font, first checking if it exists in a cache
font_cached_load = memoized(Display.font_load)
--- Load an image, first checking if it exists in a cache
image_cached_load = memoized(Display.image_load)
DEBUG_LAYOUTS = false

function _G.DEBUG_BOX_DRAW(self, x, y)
    local debug_font = resources.get_font(_SETTINGS.menu_font)
    if DEBUG_LAYOUTS then
        local mouse_is_over = mouse_over({x,y}, self.size)
        local color = mouse_is_over and Display.COL_PALE_BLUE or Display.COL_YELLOW
        -- local line_width = mouse_is_over and 5 or 2
        local alpha = mouse_is_over and 1.0 or 0.9

        if mouse_is_over then
            Display.drawText { font=debug_font, color = COL_WHITE, origin_y = 1, x=x, y=y}
        end

        local x1,y1,x2,y2 = unpack(bbox_create({x,y}, self.size))
        local col = table.clone(color)
        col[4] = alpha
        Display.drawRect(x1,y1,x2,y2, col)
    end
end

--- Takes a color, and returns a color with a transparency of 'alpha'
-- Colors that already have an alpha will be made more transparent.
-- @usage with_alpha(COL_WHITE, 0.5)
function _G.with_alpha(col, alpha) -- Don't mutate, we might be passed a color constant!
    local copy = { unpack(col) }
    -- Assume we have at least 3 components, but may have 4
    copy[4] = (copy[4] and copy[4] or 255 ) * alpha
    return copy    
end
