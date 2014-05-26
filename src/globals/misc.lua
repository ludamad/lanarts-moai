local nilprotect_meta = {__index = function(self, k)
    error( ("Key '%s' does not exist in table!"):format(k) )
end}

-- Set to a metatable that does not allow nil accesses
function nilprotect(t)
    return setmetatable(t, nilprotect_meta)
end

function values(table)
    local idx = 1
    return function()
        local val = table[idx]
        idx = idx + 1
        return val
    end
end

-- Like C printf, but always prints new line
function printf(fmt, ...) print(fmt:format(...)) end
function errorf(fmt, ...) error(fmt:format(...)) end
function assertf(cond, fmt, ...) return assert(cond, fmt:format(...)) end
-- Convenient handle for very useful function:
fmt = string.format

-- Lua table API extensions:
append = table.insert

-- String split provided in main.lua

function string:interpolate(table)
    return (self:gsub('($%b{})', function(w) return table[w:sub(3, -2)] or w end))
end
function string:join(parts_table)
    return table.concat(parts_table, self)
end
function string:trim()
  return self:gsub("^%s*(.-)%s*$", "%1")
end
function string:trimsplit(s)
    local parts = self:split(s)
    for i,p in ipairs(parts) do parts[i] = p:trim() end
    return parts
end

--- Get a  human-readable string from a lua value. The resulting value is generally valid lua.
-- Note that the paramaters should typically not used directly, except for perhaps 'packed'.
-- @param val the value to pretty-print
-- @param tabs <i>optional, default 0</i>, the level of indentation
-- @param packed <i>optional, default false</i>, if true, minimal spacing is used
-- @param quote_strings <i>optional, default true</i>, whether to print strings with spaces
function pretty_tostring(val, --[[Optional]] tabs, --[[Optional]] packed, --[[Optional]] quote_strings)
    tabs = tabs or 0
    quote_strings = (quote_strings == nil) or quote_strings

    local tabstr = ""

    if not packed then
        for i = 1, tabs do
            tabstr = tabstr .. "  "
        end
    end
    if type(val) == "string" then val = val:gsub('\n','\\n') end
    if type(val) == "string" and quote_strings then
        return tabstr .. "\"" .. val .. "\""
    end

    local meta = getmetatable(val) 
    if (meta and meta.__tostring) or type(val) ~= "table" then
        return tabstr .. tostring(val)
    end

    local parts = {"{", --[[sentinel for remove below]] ""}

    for k,v in pairs(val) do
        table.insert(parts, packed and "" or "\n") 

        if type(k) == "number" then
            table.insert(parts, pretty_tostring(v, tabs+1, packed))
        else 
            table.insert(parts, pretty_tostring(k, tabs+1, packed, false))
            table.insert(parts, " = ")
            table.insert(parts, pretty_tostring(v, type(v) == "table" and tabs+1 or 0, packed))
        end

        table.insert(parts, ", ")
    end

    parts[#parts] = nil -- remove comma or sentinel

    table.insert(parts, (packed and "" or "\n") .. tabstr .. "}");

    return table.concat(parts)
end

function pretty_tostring_compact(v)
    return pretty_tostring(v, nil, true)
end

function newtype(args)
    local get, set = {}, {}
    local parent = args and args.parent
    local type = {get = get, set = set}

    function type.create(...)
        local val = setmetatable({}, type)
        type.init(val, ...)
        return val
    end

    function type:__index(k)
        local getter = get[k]
        if getter then return getter(self, k) end
        local type_val = type[k]
        if type_val then return type_val end
        if parent then
            local idx_fun = parent.__index
            if idx_fun then return idx_fun(self, k) end
        end
        error(("Cannot read '%s', member does not exist!\n"):format(tostring(k)))
    end

    function type:__newindex(k, v)
        local setter = set[k]
        if setter then
            setter(self, v)
            return
        end
        if parent then
            local newidx_fun = parent.__newindex
            if newidx_fun then
                newidx_fun(self, k, v)
                return
            end
        end
        rawset(self, k, v)
    end

    return type
end

--- Get a  human-readable string from a lua value. The resulting value is generally valid lua.
-- Note that the paramaters should typically not used directly, except for perhaps 'packed'.
-- @param val the value to pretty-print
-- @param tabs <i>optional, default 0</i>, the level of indentation
-- @param packed <i>optional, default false</i>, if true, minimal spacing is used
function pretty_print(val, --[[Optional]] tabs, --[[Optional]] packed)
    print(pretty_tostring(val, tabs, packed))
end

local function pretty_s(val)
    if type(val) == "string" then
        return val
    end
    if type(val) ~= "function" then
        return pretty_tostring_compact(val)
    end
    local info = debug.getinfo(val)
    local ups = "{" ; for i=1,info.nups do 
        local k, v = debug.getupvalue(val,i) ; ups = ups .. k .."="..tostring(v)..","
    end
    return "function " .. info.source .. ":" .. info.linedefined .. "-" .. info.lastlinedefined .. ups .. '}'
end

-- Convenience print-like function:
function pretty(...)
    local args = {}
    for i=1,select("#", ...) do
        args[i] = pretty_s(select(i, ...))
    end
    print(unpack(args))
end

function file_as_string(name)
    local f = io.open(name,"r")
    if f == nil then return nil end
    local contents = f:read("*all")
    f:close()
    return contents
end