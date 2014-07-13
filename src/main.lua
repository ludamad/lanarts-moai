-------------------------------------------------------------------------------
-- Ensure undefined global access is an error.
-------------------------------------------------------------------------------

local global_meta = {}
setmetatable(_G, global_meta)

function global_meta:__index(k)
    error("Undefined global variable '" .. k .. "'!")
end

-------------------------------------------------------------------------------
-- Set modules folder as loading root. Must occur before insert_loader().
-------------------------------------------------------------------------------

package.path = package.path .. ";src/modules/?.lua"

-------------------------------------------------------------------------------
-- Define global utilities.
-------------------------------------------------------------------------------

require "globals.misc"
require "globals.math"
require "globals.table"
require "globals.flextypes"
require "globals.string"

-------------------------------------------------------------------------------
-- Ensure proper loading of moonscript files.
-------------------------------------------------------------------------------

require("moonscript.base").insert_loader()

-------------------------------------------------------------------------------
-- Loader magic, for our module system. Must occur after insert_loader().
-------------------------------------------------------------------------------

require "globals.modules"

-- Must load settings early because it can be referenced in files
_G._SETTINGS = require "settings"

-------------------------------------------------------------------------------
-- Additional global utilities.
-- TODO: Evaluate
-------------------------------------------------------------------------------

require "globals.lanarts_backcompat_globals"
require "globals.lanarts_backcompat_draw"
require "globals.lanarts_backcompat_textcomponent"

-------------------------------------------------------------------------------
-- Finally, if we are not testing, run the game.
-------------------------------------------------------------------------------

local ErrorReporting = require "system.ErrorReporting"

if os.getenv("i") then
    inspect()
elseif os.getenv "TEST" then
	print "RUNNING TEST SUITE"
    _TEST = false -- Strict-global compatibility
    local busted = (require 'busted') 
    -- Better error reporting for 'it'
    local previous_it = it
    function _G.it(str, f)
      previous_it(str, ErrorReporting.wrap(f))
    end
    local status, failures = busted { 
	    path = '',
	    root_file = 'tests',
	    pattern = ".*",
	    output = busted.defaultoutput,
	    excluded_tags = {}, tags = {".*"}
  	}
  	print(status)
  	if failures > 0 then
  		print("Finished with " .. failures .. " failures!")
  	else
  		print("Everything passed!")
  	end
else
    ErrorReporting.wrap(function()
		    require("core.main")
    end)()
end
