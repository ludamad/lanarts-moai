-------------------------------------------------------------------------------
-- Make 'require' aware of the MOAI filesystem.
-------------------------------------------------------------------------------

local BUFF_SIZE = 4096

-- Path containing bundled Lua-file dependencies.
local LUA_DEPS = 'lua-deps/'

-- Returns object that represents a required directory, ie a package.
local function required_directory(vpath, path)
    if not MOAIFileSystem.checkPathExists(path) then
        return nil
    end
    local object,meta = {},{}
    -- Try to require. Note, only occurs if object[k] == nil.
    function meta:__index(k)
        local req = require(vpath .. '.' .. k)
        object[k] = req -- Cache
        return req
    end
    return setmetatable(object, meta)
end

local function require_moai_directory(vpath)
    -- We determine whether we are loading a path as a Lua object.
    -- Note this can name-clash with Lua files, which are resolved first.
    -- To explicitly specify a directory, include a leading '.' or '/'

    local dpath = vpath:gsub('%.', '/') 

    -- Return an object representing a path, or nil if not existent:
    for _, root in ipairs(package.path:split ';') do
        local obj = required_directory(vpath, root:gsub('%?%.lua', dpath))
        if obj then 
            return obj 
        end
    end

    return nil -- Path not existent
end

local function require_moai_file(vpath)
    local fpath = vpath:gsub('%.', '/') .. '.lua'

    -- First, we ask whether we can load a Lua file
    local stream = MOAIFileStream.new()
    if not stream:open(fpath) and not stream:open(LUA_DEPS .. fpath) then
        -- Next, we ask whether we can load a directory as a collection
        local obj = require_moai_directory(vpath)
        if obj then -- We must return a loader function:
            return function() 
                return obj 
            end
        else
            return nil
        end
    end

    local func,err = load(
        --[[Chunks]] function() 
            -- Will terminate on empty string:
            return stream:read(BUFF_SIZE)
        end, 
        --[[Name]] vpath
    )

    if err then error(err) end

    return func
end

table.insert(package.loaders, require_moai_file)

-------------------------------------------------------------------------------
-- Disable logging.
-------------------------------------------------------------------------------

MOAILogMgr.setLogLevel(MOAILogMgr.LOG_NONE)

-------------------------------------------------------------------------------
-- Ensure files from src/ are loaded, and that we do not load any system files.
-------------------------------------------------------------------------------

package.cpath = ''
package.path = '?.lua;src/?.lua;.lua-deps/?.lua'

if os.getenv("p") then
    package.path = package.path .. ';' .. os.getenv("p") .. "/?.lua"
end

-------------------------------------------------------------------------------
-- Mount lua-deps.zip, provided by our engine.
-------------------------------------------------------------------------------

-- For now use folder instead.
--local success = MOAIFileSystem.mountVirtualDirectory("lua-deps", "engine/dependencies/lua-deps.zip")
--assert(success, "Could not mount lua-deps.zip!")

-------------------------------------------------------------------------------
-- Ensure proper loading of moonscript files (requires lua-deps.zip to be 
-- mounted).
-------------------------------------------------------------------------------

require("moonscript.base").insert_loader()

-------------------------------------------------------------------------------
-- Ensure undefined global access is an error.
-------------------------------------------------------------------------------

local global_meta = {}
setmetatable(_G, global_meta)

function global_meta:__index(k)
    error("Undefined global variable '" .. k .. "'!")
end

-------------------------------------------------------------------------------
-- Define global utilities.
-------------------------------------------------------------------------------

require "global_utils"

-------------------------------------------------------------------------------
-- Are we a debug server? 
-------------------------------------------------------------------------------

if os.getenv('DEBUG_SERVER') then 
    -- Run a debug server:
    require("mobdebug").listen()
    return
end

-------------------------------------------------------------------------------
-- Finally, if we are not a debug server, run the game.
-------------------------------------------------------------------------------

local ErrorReporting = require "system.ErrorReporting"

local module = os.getenv("f") or "game"
ErrorReporting.report(function() 
    require(module)
end)
