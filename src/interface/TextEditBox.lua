--------------------------------------------------------------------------------
-- Interface component for entering text.
-- This includes stuff like entering name before play, etc.
-- 
-- Parameters (passed by table):
--   initial_repeat_ms: How long to hold before entering repeating mode.
--   next_repeat_ms: Determines spacing between repeats once entering repeating mode.
--   next_backspace_ms: Determines spacing between deletes when holding backspace.
--   no_repeat: Determines spacing between deletes when holding backspace.
--
-- Available getter/setter:
--   .contents: The string contents.
--   .cursor_pos: Position of cursor on editable text.
--   .representation: Read-only. How text is represented in text field.
--------------------------------------------------------------------------------

local CURSOR = "|"

local K_BACKSPACE = 8
local K_ENTER = 13

local TextEditBox = newtype()

function TextEditBox:init(textbox, contents)
    self._padding = "  "
    self._passwordChar = false
    self._cursor_pos = 1
    self._maxLength = 20
    self._allowedChars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890.:,;(:*!?' "
    self._text = textbox
    self.contents = contents
end

function TextEditBox.get:contents()
    return self._contents
end

function TextEditBox.set:contents(string)
    self._contents = string
    self._text:setString(self.representation)
end

function TextEditBox.get:representation()
    local str = self.contents
    if self._passwordChar then
        str = string.rep(self._passwordChar, #str)
    end
    return str:sub(0, self._cursor_pos) .. CURSOR .. str:sub(self._cursor_pos + 1)
end

function TextEditBox:_to_char(key)
    if key < 0 or key > 255 then 
        return nil
    end

    local chr = string.char(key)
    for i=1,#self._allowedChars do
        if chr == self._allowedChars:sub(i,i) then
            return chr
        end
    end

    return nil
end

function TextEditBox:_onHandleKeyDown(event)
    local key = event.key
    if K_BACKSPACE == key then
        self.contents = self.contents:sub(1, #self.contents - 1)
        self.cursor_pos = self.cursor_pos - 1
        return true
    end

    if #self.contents >= self._maxLength then
        return false
    end

    local chr = self:_to_char(key)
    if not chr then
        return false
    end

    self.cursor_pos = self.cursor_pos + 1
    self.contents = self.contents .. chr

    return true
end

function TextEditBox.set:cursor_pos(pos)
    self._cursor_pos = pos
end

function TextEditBox.get:cursor_pos()
    local pos = self._cursor_pos
    if pos < 1 then pos = 1 
    elseif pos > self._maxLength then pos = self._maxLength end
    return pos
end

return TextEditBox
