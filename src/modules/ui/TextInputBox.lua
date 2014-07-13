local user_io = require "user_io"
local Display = require "@Display"
local TextField = require "core.TextField"

local BLINK_TIME_MS = 600
local BLINK_HELD_MS = 600

--- An interactive text field, a convenient drawable object wrapper 
-- over the native (aka C++-implemented) TextInput object. 
local TextInputBox = newtype()

--- Create an interactive text field
-- font: the font to draw with
-- size: the size of the box to draw around the texth
-- fieldargs: {max characters, default_text} 
-- callbacks: {optional 'update' callback, 
--              optional 'select' callback, 
--              optional 'deselect' callback}
function TextInputBox:init(font, size, fieldargs, callbacks)
    self.text_input = TextField.create( unpack(fieldargs))

    self.size = size

    self.frame = 0
    self.selected = false

    self.font = font

    self.blink_timer = timer_create()

    self.draw = callbacks.draw
    self.valid_string = callbacks.valid_string or function() return true end
    self.update = callbacks.update or do_nothing
    self.select = callbacks.select or do_nothing
    self.deselect = callbacks.deselect or do_nothing
end

function TextInputBox.get:text()
    return self.text_input.text
end

function TextInputBox:mouse_over(x, y)
    return mouse_over({x, y}, self.size)
end

function TextInputBox:step(xy)
    if self.selected then
        for event in values( input.events ) do
            self.text_input:event_handle(event)
        end
    end

    self.text_input:step()

    if self.valid_string(self.text) then
        self:update()
    end

    local clicked = user_io.mouse_left_pressed() and self:mouse_over(xy)

    if (user_io.key_pressed("K_ENTER") or user_io.mouse_left_pressed()) and self.selected then
        self.selected = false
        self:deselect()
    elseif clicked and not self.selected then
        self.selected = true
        self.blink_timer:start()
        self:select()
    end

    self.frame = self.frame + 1
end

function TextInputBox.is_blinking(self)
    local ms = self.blink_timer:get_milliseconds() 

    if self.selected and ms > BLINK_TIME_MS then
        if ms > BLINK_TIME_MS + BLINK_HELD_MS then
            self.blink_timer:start()
        end
        return true
    end

    return false
end

function TextInputBox:draw(xy)
    local bbox = bbox_create(xy, self.size)

    Display.fillRect(bbox, COL_DARKER_GRAY)

    local textcolor = self.valid_string(self.text) and COL_MUTED_GREEN or COL_LIGHT_RED

    local x, y = unpack(xy)
    local w, h = unpack(self.size)

    local text = self.text
    if self:is_blinking() then 
        text = text .. '|' 
    end

    self.font:draw(
        {color = textcolor, origin = Display.LEFT_CENTER}, 
        {x + 5, y + h / 2}, 
        text
    )

    local boxcolor = COL_DARK_GRAY

    if (self.selected) then
        boxcolor = COL_WHITE
    elseif self:mouse_over(x, y) then
        boxcolor = COL_MID_GRAY
    end

    Display.drawRect(bbox_create(xy, self.size), boxcolor)
    DEBUG_BOX_DRAW(self, x, y)
end

function TextInputBox:__tostring()
    return "[TextInputBox " .. toaddress(self) .. "]" 
end

return TextInputBox
