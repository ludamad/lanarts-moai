-------------------------------------------------------------------------------
-- Ensure undefined global access is an error.
-------------------------------------------------------------------------------

local global_meta = {}
setmetatable(_G, global_meta)

function global_meta:__index(k)
    error("Undefined global variable '" .. k .. "'!")
end

-------------------------------------------------------------------------------
-- Ensure proper loading of moonscript files (requires lua-deps.zip to be 
-- mounted).
-------------------------------------------------------------------------------

require("moonscript.base").insert_loader()

-------------------------------------------------------------------------------
-- Define global utilities.
-------------------------------------------------------------------------------

require "globals.misc"
require "globals.table"

-------------------------------------------------------------------------------
-- Add citymode/ folder to require path.
-------------------------------------------------------------------------------

package.path = package.path .. ';citymode/?.lua;src/citymode/?.lua'

-------------------------------------------------------------------------------
-- Finally, if we are not a debug server, run the game.
-------------------------------------------------------------------------------

local ErrorReporting = require "system.ErrorReporting"

local module = os.getenv("f") or "game"
ErrorReporting.report(function() 
    require(module)
end)

