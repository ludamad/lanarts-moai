local user_io = require "user_io"
local Display = require "@Display"
local TextField = require "core.TextField"
local sdl = require 'sdl'

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
    self.last_valid_text = fieldargs[2]

    self.size = size

    self.frame = 0
    self.selected = false

    self.font = font

    self.blink_timer = timer_create()

    self.valid_string = callbacks.valid_string or function() return true end
    self.update = callbacks.update or do_nothing
    self.select = callbacks.select or do_nothing
    self.deselect = callbacks.deselect or do_nothing
end

function TextInputBox.get:text()
    return self.text_input.text
end

function TextInputBox.get:max_length()
    return self.text_input.max_length
end

function TextInputBox.set:text(text)
    self.text_input.text = text
end

function TextInputBox:mouse_over(x, y)
    assert(type(x) == 'number')
    return mouse_over({x, y}, self.size)
end

local VALID_CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 .,/;!?()&/-%'

local key_count = 1
function TextInputBox:step(x, y)
    assert(type(x) == 'number')
    if self.selected then
        local ctrl_down = sdl.IsLCTRLDown() or sdl.IsRCTRLDown()
        -- Are we pasting?
        if ctrl_down and (user_io.key_pressed "K_V") then
            -- Append clipboard to current text contexts
            local text = self.text 
            local clip_text = sdl.GetClipboardText()
            -- Filter clipboard text, guarding against unprintable characters
            for i=1,#clip_text do
                local char = clip_text:sub(i,i)
                if char == '%' or VALID_CHARS:find(char) then
                    text = text .. char
                end
            end
            -- Clip by max length, and set text contexts
            self.text = text:sub(1, self.max_length)
        else
            -- Normal input
            local mod_state = sdl.GetModState()
            for _, up_key in ipairs(user_io.get_released_keys_for_step()) do
                key_count = key_count + 1
                print(key_count, up_key)
                self.text_input:handle_key_up(up_key, mod_state)
            end
            for _, down_key in ipairs(user_io.get_pressed_keys_for_step()) do
                key_count = key_count + 1
                print(key_count, down_key)
                self.text_input:handle_key_down(down_key, mod_state)
            end
        end
    end

    self.text_input:step()

    if self.valid_string(self.text) then
        self.last_valid_text = self.text
        self:update()
    end

    local clicked = user_io.mouse_left_pressed() and self:mouse_over(x, y)

    if (user_io.key_pressed("K_ENTER") or user_io.mouse_left_pressed()) and self.selected then
        self.selected = false
        self.text = self.last_valid_text
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

function TextInputBox:draw(x, y)
    local bbox = bbox_create({x, y}, self.size)

    Display.fillRect(bbox, Display.COL_DARKER_GRAY)

    local textcolor = self.valid_string(self.text) and Display.COL_MUTED_GREEN or Display.COL_LIGHT_RED

    local w, h = unpack(self.size)

    local text = self.text
    if self:is_blinking() then 
        text = text .. '|' 
    end

    Display.drawText {
        font = self.font,
        color = textcolor, origin = Display.LEFT_CENTER, 
        x = x + 5, y = y + h / 2,
        text = text
    }

    local boxcolor = Display.COL_DARK_GRAY

    if (self.selected) then
        boxcolor = Display.COL_WHITE
    elseif self:mouse_over(x, y) then
        boxcolor = Display.COL_MID_GRAY
    end

    Display.drawRect(bbox_create({x, y}, self.size), boxcolor)
    DEBUG_BOX_DRAW(self, x, y)
end

function TextInputBox:__tostring()
    return "[TextInputBox " .. toaddress(self) .. "]" 
end

return TextInputBox
