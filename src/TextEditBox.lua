--------------------------------------------------------------------------------
-- Interface component for entering text.
-- This includes stuff like entering name before play, etc.
-- 
-- Parameters (passed by table):
--   initial_repeat_ms: How long to hold before entering repeating mode.
--   next_repeat_ms: Determines spacing between repeats once entering repeating mode.
--   next_backspace_ms: Determines spacing between deletes when holding backspace.
--   no_repeat: Determines spacing between deletes when holding backspace.
--------------------------------------------------------------------------------

local CURSOR = "|"

local K_BACKSPACE = 8
local K_ENTER = 13

local TextEditBox = newtype()

function TextEditBox:init(gui)
    self:_TextEditBoxEvents()

    self._BACKGROUND_INDEX = self._WIDGET_SPECIFIC_OBJECTS_INDEX
    self.BACKGROUND_IMAGES = self._WIDGET_SPECIFIC_IMAGES

    self._padding = "  "
    self._passwordChar = false
    self._cursorPos = 1
    self._internalText = ""
    self._maxLength = 20
    self._allowedChars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890.:,;(:*!?' "

    self:setTextAlignment(self.TEXT_ALIGN_LEFT, self.TEXT_ALIGN_CENTER)
end


function TextEditBox:_createTextEditBoxTextAcceptedEvent()
    local t = awidgetevent.AWidgetEvent(self.EVENT_EDIT_BOX_TEXT_ACCEPTED, self)
    t.text = self._internalText

    return t
end

function TextEditBox:_addCursor()
    local text = self._text:getString()
    text = text:sub(0, self._cursorPos - 1) .. CURSOR .. text:sub(self._cursorPos)
    self._text:setString(text)
end

function TextEditBox:_onHandleGainFocus(event)
    self._cursorPos = #self._internalText + 1
    self:_addCursor()

    return self:_baseHandleGainFocus(event)
end

function TextEditBox:_onHandleLoseFocus(event)
    local text = self._text:getString()
    text = text:sub(0, self._cursorPos - 1) .. text:sub(self._cursorPos + 1)
    self._text:setString(text)

    return self:_baseHandleLoseFocus(event)
end

function TextEditBox:_onHandleKeyDown(event)
    local key = event.key
    if K_BACKSPACE == key then
        local text = self._internalText:sub(0, self._cursorPos - 2) .. self._internalText:sub(self._cursorPos)
        self:setText(text)
        self._cursorPos = self._cursorPos - 1
        self:_addCursor()

        return true
    end

    if K_ENTER == key then
        local e = self:_createTextEditBoxTextAcceptedEvent()
        return self:_handleEvent(self.EVENT_EDIT_BOX_TEXT_ACCEPTED, e)
    end

    if #self._internalText >= self._maxLength then
        return false
    end

    -- Can't use string.find, as when certain characters are used (eg. %, $), the function
    -- thinks we're trying to send in a pattern, and crashes the program.
    key = string.char(key)
    local allowed = false
    for i = 1, #self._allowedChars do
        if key == self._allowedChars:sub(i, i) then
            allowed = true
            break
        end
    end

    if false == allowed then return false end

    local text = self._internalText:sub(0, self._cursorPos) .. key .. self._internalText:sub(self._cursorPos + 1)
    self:setText(text)
    self._cursorPos = self._cursorPos + 1
    self:_addCursor()

    return true
end

function TextEditBox:_onHandleKeyUp(event)
    
end

function TextEditBox:setText(text)
    self._internalText = text

    if self._passwordChar)then
            text = string.rep(self._passwordChar, #text)
    end

    self._text:setString(text)

    self:_setTextRect()
    self:_setTextAlignment()
end

function TextEditBox:getText()
    return self._internalText
end

function TextEditBox:setPasswordChar(char)
    self._passwordChar = char

    self:setText(self._internalText)
end

function TextEditBox:getPasswordChar()
    return self._passwordChar
end

function TextEditBox:setCursorPos(pos)
    if pos < 1 then
        pos = 1
    end

    if pos > self._maxLength then
        pos = self._maxLength
    end

    self._cursorPos = pos
end

function TextEditBox:getCursorPos()
    return self._cursorPos
end

function TextEditBox:setMaxLength(length)
    self._maxLength = length

    local text = self._text:getString()
    text = text:sub(1, length)

    self._internalText = text

    self:setText(text)
end

function TextEditBox:getMaxLength()
    return self._maxLength
end

function TextEditBox:setAllowedChars(s)
    self._allowedChars = s
end

function TextEditBox:getAllowedChars()
    return self._allowedChars
end

return TextTextEditBox
