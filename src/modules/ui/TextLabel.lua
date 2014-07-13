local Display = require '@Display'

--- A static, drawable text instance. Implements everything 
-- needed to be added to an InstanceGroup, InstanceBox or InstanceLine.
local TextLabel = newtype( )

local DEFAULT_PADDING = 4

--- Takes either (font, text, --[[Optional]] options) and creates a
-- TextLabel. 
-- In addition to the usual font:draw options, one can specify
-- 'max_width' in the options table. If this is specified, the 
-- font object is drawn using draw_wrapped.
function TextLabel:init(options)
    assert(type(options) == "table", "Expecting a table for TextLabel.create!")
    self.font = assert(options.font)
    self.text = assert(options.text)
    self.font_scale = options.font_scale or 1
    self.font_size = options.font_size or font:getDefaultSize()
    self.origin = options.origin or Display.LEFT_TOP
    self.color = options.color or Display.COL_WHITE
    self.mouse_area_padding = options.mouse_area_padding or DEFAULT_PADDING
    -- 0 represents no maximum width
    self.max_width = options.max_width or 0
    -- Set the 'size' member, required for layouts
    self:recalculate()
end

TextLabel.step = do_nothing

-- Calculates the size member needed for InstanceGroup & InstanceBox.
function TextLabel:recalculate()
    local w, h = MOAIDraw.textSize(self.font, self.font_size, self.text, self.font_scale, self.max_width)
    self.size = {w,h}
end

--- Convenience function for checking if the mouse is within
-- the rectangular area around the TextLabel
function TextLabel:mouse_over(x, y)
    local padded_xy = {x - DEFAULT_PADDING, y - DEFAULT_PADDING}
    local padded_size = {self.size[1] + DEFAULT_PADDING * 2, self.size[2] + DEFAULT_PADDING * 2}
    return mouse_over(padded_xy, padded_size, self.origin)
end

function TextLabel:draw(x, y)
    DEBUG_BOX_DRAW(self, x, y)
    local oX, oY = unpack(self.origin)
    MOAIGfxDevice.setPenColor(unpack(self.color))
    MOAIDraw.drawText(self.font, self.font_size, self.text, x, y, self.font_scale, 0,0, oX, oY, self.max_width)
    -- self.font:draw( self.options, xy, self.text )
end

return TextLabel
