-------------------------------------------------------------------------------
-- Make 'require' aware of the MOAI filesystem.
-------------------------------------------------------------------------------

local BUFF_SIZE = 4096

local function require_moai_hook(vpath)
    local rpath = vpath:gsub('%.', '/') .. '.lua'
    local stream = MOAIFileStream.new()

    if not stream:open(rpath) and not stream:open('lua-deps/' .. rpath) then
        return nil
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

table.insert(package.loaders, require_moai_hook)

-------------------------------------------------------------------------------
-- Disable logging.
-------------------------------------------------------------------------------

MOAILogMgr.setLogLevel(MOAILogMgr.LOG_NONE)

-------------------------------------------------------------------------------
-- Ensure files from src/ are loaded.
-------------------------------------------------------------------------------

package.path = package.path .. ';src/?.lua'

-------------------------------------------------------------------------------
-- Mount lua-deps.zip, provided by our engine.
-------------------------------------------------------------------------------

local success = MOAIFileSystem.mountVirtualDirectory("lua-deps", "engine/dependencies/lua-deps.zip")
assert(success, "Could not mount lua-deps.zip!")

-------------------------------------------------------------------------------
-- Ensure proper loading of moonscript files (requires lua-deps.zip to be 
-- mounted).
-------------------------------------------------------------------------------

require("moonscript.base").insert_loader()

-------------------------------------------------------------------------------
-- Finally, run the game.
-------------------------------------------------------------------------------


require "game"
