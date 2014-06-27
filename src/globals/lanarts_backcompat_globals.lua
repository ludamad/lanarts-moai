--- General convenience global functions.
-- IE, utility code that was decided makes Lua programming in general easier.
-- 
-- Additional (potentially more domain-specific) global functins are define in the 
-- 'globals' module in this package, as well as the 'globals' folder within a module, 
-- or its Globals.lua submodule.

--- Does nothing. 
--@usage dummy_object = { step = do_nothing, draw = do_nothing }
function do_nothing() end
_EMPTY_TABLE = {}

-- Global data is a special submodule, its members are always serialized
--local GlobalData = import "core.GlobalData"

local print,error,assert=print,error,assert -- Performance

local tinsert = table.insert
function appendf(t, s, ...)
    return tinsert(t, s:format(...))
end

-- Data is defined on a per-submodule basis
function data_load(key, default, --[[Optional]] vpath)
    do return default end -- TODO Implement
    -- Make a safe & (almost) guaranteed unique key 
    local global_key = (vpath or virtual_path(2)) .. ':' .. key
    local val = GlobalData[global_key]
    if not val then 
        GlobalData[global_key] = default
        return default
    end
    return val
end

--- Wraps a function around a memoizing weak table.
-- Function results will be stored until they are no longer referenced.
-- 
-- Note: This is intended for functions returning heavy-weight objects,
-- such as images. Functions that return primitives will not interact
-- correctly with the garbage collection.
--
-- @param func the function to memoize, arguments must be strings or numbers
-- @param separator <i>optional, default ';'</i>, the separator used when joining arguments to form a string key
-- @usage new_load = memoized(load)
function memoized(func, --[[Optional]] separator) 
    local cache = {}
    setmetatable( cache, {__mode = "kv"} ) -- Make table weak

    separator = separator or ";"

    return function(...)
        local key = table.concat({...}, separator)

        if not cache[key] then 
            cache[key] = func(...)
        end

        return cache[key]
    end
end

-- Resolves a number, or a random range
function random_resolve(v)
    return type(v) == "table" and random(unpack(v)) or v
end

--- Get a  human-readable string from a lua value. The resulting value is generally valid lua.
-- Note that the paramaters should typically not used directly, except for perhaps 'packed'.
-- @param val the value to pretty-print
-- @param tabs <i>optional, default 0</i>, the level of indentation
-- @param packed <i>optional, default false</i>, if true, minimal spacing is used
function pretty_print(val, --[[Optional]] tabs, --[[Optional]] packed)
    print(pretty_tostring(val, tabs, packed))
end

-- Convenience print-like function:
function pretty(...)
    local args = {}
    for i=1,select("#", ...) do
    	args[i] = pretty_tostring_compact(select(i, ...)) 
	end
    print(unpack(args))
end

--- Iterate all iterators one after another
function iter_combine(...)
    local args = {...}
    local arg_n = #args
    local arg_i = 1
    local iter = args[arg_i]
    return function()
        while true do
            if not iter then return nil end
            local val = iter()
            if val ~= nil then return val end
            arg_i = arg_i + 1
            iter = args[arg_i]
        end
    end
end

--- Like a functional map of a function onto a list
function map_call(f, list)
    local ret = {}
    for i=1,#list do 
        ret[i] = f(list[i])
    end
    return ret
end

-- Functional composition
function func_apply_and(f1,f2, --[[Optional]] s2)
    return function(s1,...) 
        local v = {f1(s1,...)}
        if not v[1] then return unpack(v)
        else 
            if s2 then return f2(s2, ...)
            else return f2(s1,...) end
        end
    end
end

function func_apply_not(f)
    return function(...) return not f(...) end
end

--- Return whether a file with the specified name exists.
-- More precisely, returns whether the given file can be opened for reading.
function file_exists(name)
    local f = io.open(name,"r")
    if f ~= nil then io.close(f) end 
    return f ~= nil 
end


function func_apply_or(f1,f2, --[[Optional]] s2)
    return function(s1,...) 
        local v = {f1(s1,...)}
        if v[1] then return unpack(v)
        else 
            if s2 then return f2(s2, ...)
            else return f2(s1,...) end
        end
    end
end

function func_apply_sequence(f1,f2,--[[Optional]] s2)
    return function(s1,...)
        local v = f1(s1,...)
        if s2 then v = f2(s2, ...) or v 
        else v = f2(s1,...) or v end
        return v 
    end
end

local _cached_dup_table = {}
function dup(val, times)
    table.clear(_cached_dup_table)
    for i=1,times do
        _cached_dup_table[i] = val
    end
    return unpack(_cached_dup_table)
end

--- Return a random element from a list
function random_choice(choices)
    local idx = random(1, #choices)
    return choices[idx]
end

local function iterator_helper(f,...)
    return f(...)
end
function iterator_step(state)
    local oldf = state[1] -- Used in hack to determine termination
    table.assign(state, iterator_helper(unpack(state)))
    if state[1] ~= oldf then table.clear(state) end
end
