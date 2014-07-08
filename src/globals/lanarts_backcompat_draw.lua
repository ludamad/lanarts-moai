local Display = require "lanarts.draw"
local user_io = require 'user_io'

-- More ad hoc utilities without a home, yet

function to_tilexy(xy)
    return {math.floor(xy[1]/32), math.floor(xy[2]/32)}
end
function to_worldxy(xy)
    return {xy[1]*32+16, xy[2]*32+16}
end

--- Return whether the mouse has been right clicked within a bounding box.
function bbox_right_clicked(bbox, origin)
    return user_io.mouse_right_pressed() and bbox_mouse_over(bbox, origin)
end

--- Return whether the mouse has been left clicked within a bounding box.
function bbox_left_clicked(bbox, origin)
    return user_io.mouse_left_pressed() and bbox_mouse_over(bbox, origin)
end

--- Return whether the mouse is within a bounding box.
function bbox_mouse_over(bbox, origin)
     pretty(Display.shift_origin(bbox, origin or Display.LEFT_TOP), {user_io.mouse_xy()} )

    return bbox_contains(Display.shift_origin(bbox, origin or Display.LEFT_TOP), {user_io.mouse_xy()} )
end

--- Return whether the mouse is within a bounding box defined by xy and size.
function mouse_over(xy, size, origin)
    return bbox_mouse_over(bbox_create(xy, size), origin)
end

function origin_valid(origin)
    return origin[1] >= 0 and origin[1] <= 1 and origin[2] >= 0 and origin[2] <= 1
end

--- Draw parts of text colored differently
-- @usage draw_colored_parts(font, Display.LEFT_TOP, {0,0}. {COL_RED, "hi "}, {COL_BLUE, "there"} )
function draw_colored_parts(font, origin, xy, ...)
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
-- Used for debug information overlay
function DEBUG_BOX_DRAW(self, xy)
    local debug_font = font_cached_load(_SETTINGS.menu_font, 10)
    if DEBUG_LAYOUTS then
        local mouse_is_over = mouse_over(xy, self.size)
        local color = mouse_is_over and COL_PALE_BLUE or COL_YELLOW
        local line_width = mouse_is_over and 5 or 2
        local alpha = mouse_is_over and 0.5 or 0.25

        if mouse_is_over then
            debug_font:draw( { color = COL_WHITE, origin = Display.LEFT_BOTTOM }, xy, tostring(self) )
        end

        Display.draw_rectangle_outline(with_alpha(color, alpha), bbox_create(xy, self.size), line_width )
    end
end

--- Takes a color, and returns a color with a transparency of 'alpha'
-- Colors that already have an alpha will be made more transparent.
-- @usage with_alpha(COL_WHITE, 0.5)
function with_alpha(col, alpha) -- Don't mutate, we might be passed a color constant!
    local copy = { unpack(col) }
    -- Assume we have at least 3 components, but may have 4
    copy[4] = (copy[4] and copy[4] or 255 ) * alpha
    return copy    
end
