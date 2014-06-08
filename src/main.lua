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
-- Add citymode/ folder to require path.
-------------------------------------------------------------------------------

-- Hackish way to develop multiple games in the same repo, for now.
local GAME = "lanarts" -- "citymode"

package.path = package.path .. ';'..GAME..'/?.lua;src/'..GAME..'/?.lua'

-------------------------------------------------------------------------------
-- Ensure proper loading of moonscript files.
-------------------------------------------------------------------------------

require("moonscript.base").insert_loader()

-------------------------------------------------------------------------------
-- Finally, if we are not a debug server, run the game.
-------------------------------------------------------------------------------

local ErrorReporting = require "system.ErrorReporting"

if os.getenv("i") then
    inspect()
else
    local module = os.getenv("f") or "game"
    ErrorReporting.wrap(function() 
        require(module)
    end)()
end
