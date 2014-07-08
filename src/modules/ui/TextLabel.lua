local Display = require '@Display'

--- A static, drawable text instance. Implements everything 
-- needed to be added to an InstanceGroup, InstanceBox or InstanceLine.
local TextLabel = newtype( )

--- Takes either (font, text, --[[Optional]] options) and creates a
-- TextLabel. 
--
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
    -- 0 represents no maximum width
    self.max_width = options.max_width or 0
    pretty(self)
end

TextLabel.step = do_nothing

-- function TextLabel:__tostring()
--     return "[TextLabel]" 
-- end

--- Getter for dynamically created size.
-- A size member is needed for InstanceGroup & InstanceBox.
function TextLabel.get:size()
    local w, h = MOAIDraw.textSize(self.font, self.font_size, self.text, self.font_scale, self.max_width)
    return {w,h}
end

--- Convenience function for checking if the mouse is within
-- the rectangular area around the TextLabel
function TextLabel:mouse_over(x, y)
    return mouse_over({x, y}, self.size, self.origin)
end

function TextLabel:draw(x, y)
    -- DEBUG_BOX_DRAW(self, x, y)
    local oX, oY = unpack(self.origin)
    MOAIGfxDevice.setPenColor(unpack(self.color))
    MOAIDraw.drawText(self.font, self.font_size, self.text, x, y, self.font_scale, 0,0, oX, oY, self.max_width)
    -- self.font:draw( self.options, xy, self.text )
end

return TextLabel
