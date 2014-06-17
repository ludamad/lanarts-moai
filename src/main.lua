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

require "globals.misc"
require "globals.table"
require "globals.flextypes"
require "globals.string"

-------------------------------------------------------------------------------
-- Set modules folder as loading root. Must occur before insert_loader().
-------------------------------------------------------------------------------

package.path = package.path .. ";src/modules/?.lua"

-------------------------------------------------------------------------------
-- Ensure proper loading of moonscript files.
-------------------------------------------------------------------------------

require("moonscript.base").insert_loader()

-------------------------------------------------------------------------------
-- Loader magic, for our module system. Must occur after insert_loader().
-------------------------------------------------------------------------------

require "globals.modules"

-------------------------------------------------------------------------------
-- Finally, if we are not a debug server, run the game.
-------------------------------------------------------------------------------

local ErrorReporting = require "system.ErrorReporting"

if os.getenv("i") then
    inspect()
else
    local module = os.getenv("f") or "game.main"
    ErrorReporting.wrap(function()
        require(module)
    end)()
end
