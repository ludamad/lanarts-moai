local M = nilprotect {}

--------------------------------------------------------------------------------
-- Mouse utilities.
--------------------------------------------------------------------------------

local mouse = MOAIInputMgr.device.pointer
local mleft = MOAIInputMgr.device.mouseLeft
local mright = MOAIInputMgr.device.mouseRight
local mmiddle = MOAIInputMgr.device.mouseMiddle

function M.mouse_xy()
    return mouse:getLoc() 
end 

-- Has a mouse button been pressed since last iteration?

function M.mouse_left_pressed()
    return mleft:down()
end
function M.mouse_middle_pressed()
    return mmiddle:down()
end
function M.mouse_right_pressed()
    return mright:down()
end

-- Temporarily global! For backwards compatibility

function mouse_over(xy, size)
    local bbox = bbox_create(xy, size)
    local mx, my = M.mouse_xy()
    if bbox[1] > mx or bbox[3] < mx then
        return false
    end
    if bbox[2] > my or bbox[4] < my then
        return false
    end
    return true
end

-- Has a mouse button been released since last iteration?

function M.mouse_left_released()
    return mleft:up()
end
function M.mouse_middle_released()
    return mmiddle:up()
end
function M.mouse_right_released()
    return mright:up()
end

-- Is a mouse button currently down?

function M.mouse_left_down()
    return mleft:isDown()
end
function M.mouse_middle_down()
    return mmiddle:isDown()
end
function M.mouse_right_down()
    return mright:isDown()
end

--------------------------------------------------------------------------------
-- Keyboard utilities.
--------------------------------------------------------------------------------

local keyboard = MOAIInputMgr.device.keyboard -- Canonical instance of MOAIKeyboardSensor

local function wrap(method)
    return function(key)
        return keyboard[method](
            keyboard, 
            -- Lookup if it was a string, otherwise pass through:
            (type(key) == "string") and M[key] or key
        )
    end
end

_UP_EVENTS, _DOWN_EVENTS = {}, {}

-- Collect the events
MOAIInputMgr.device.keyboard:setCallback( 
    function (key, down)
        if down then 
            append(_DOWN_EVENTS, key)
        else 
            append(_UP_EVENTS, key) 
        end
    end
)

function M.clear_keys_for_step()
    table.clear(_UP_EVENTS)
    table.clear(_DOWN_EVENTS)
end

function M.get_released_keys_for_step() return _UP_EVENTS end
function M.get_pressed_keys_for_step() return _DOWN_EVENTS end

M.key_down = wrap("keyIsDown")
M.key_up = wrap("keyIsUp")
M.key_pressed = wrap("keyDown")
M.key_released = wrap("keyUp")

local byte = string.byte

M.K_A = byte("a")
M.K_B = byte("b")
M.K_C = byte("c")
M.K_D = byte("d")
M.K_E = byte("e")
M.K_F = byte("f")
M.K_G = byte("g")
M.K_H = byte("h")
M.K_I = byte("i")
M.K_J = byte("j")
M.K_K = byte("k")
M.K_L = byte("l")
M.KM = byte("m")
M.K_N = byte("n")
M.K_O = byte("o")
M.K_P = byte("p")
M.K_Q = byte("q")
M.K_R = byte("r")
M.K_S = byte("s")
M.K_T = byte("t")
M.K_U = byte("u")
M.K_V = byte("v")
M.K_W = byte("w")
M.K_X = byte("x")
M.K_Y = byte("y")
M.K_Z = byte("z")

M.K_1 = byte("1")
M.K_2 = byte("2")
M.K_3 = byte("3")
M.K_4 = byte("4")
M.K_5 = byte("5")
M.K_6 = byte("6")
M.K_7 = byte("7")
M.K_8 = byte("8")
M.K_9 = byte("9")
M.K_0 = byte("0")

M.K_ENTER = 13
M.K_RETURN = M.K_ENTER
M.K_ESCAPE = 27

M.K_SPACE = byte(" ")
M.K_TAB = 43
M.K_LEFT_PAREN = byte("(")
M.K_RIGHT_PAREN = byte(")")
M.K_ASTERISK = byte("*")
M.K_AMPERSAND = byte("&")
M.K_CARET = byte("^")
M.K_PERCENT = byte("%")
M.K_DOLLAR = byte("$")
M.K_HASH = byte("#")
M.K_POUND = M.K_HASH
M.K_AT = byte("@")
M.K_EXCLAIM = byte("!")

--------------------------------------------------------------------------------
-- Arrow-key codes.
--------------------------------------------------------------------------------

M.K_RIGHT, M.K_LEFT, M.K_DOWN, M.K_UP = 335, 336, 337, 338

M.K_LEFT_BRACKET = byte("[")
M.K_RIGHT_BRACKET = byte("]")
M.K_LEFT_BRACE = byte("{")
M.K_RIGHT_BRACE = byte("}")
M.K_PIPE = byte("|")
M.K_BACKSLASH = byte("\\")
M.K_SEMI_COLON = byte(";")
M.K_COLON = byte(":")
M.K_QUOTE = byte("\'")
M.K_DOUBLE_QUOTE = byte("\"")
M.K_COMMA = byte(",")
M.K_PERIOD = byte(".")
M.K_SLASH = byte("/")
M.K_LESS_THAN = byte("<")
M.K_RIGHT_THAN = byte(">")
M.K_QUESTION = byte("?")
M.KMINUS = byte("-")
M.K_UNDERSCORE = byte("_")
M.K_EQUAL = byte("=")
M.K_PLUS = byte("+")

for i=1,9 do
    M["K_F"..i] = (313 + i)
end

return M
