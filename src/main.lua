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
require "globals.lanarts_backcompat_globals"
require "globals.lanarts_backcompat_draw"
require "globals.lanarts_backcompat_textcomponent"

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
elseif os.getenv "TEST" or true then
    local busted = require 'busted.core'

    _TEST = false -- Strict-global compatibility
    busted.run { 
	    path = '',
	    root_file = 'tests',
	    output = busted.defaultoutput,
	    excluded_tags = {}, tags = {}
  	}
else
	local modules = require 'modules'
    ErrorReporting.wrap(function()
		modules.load("core")
    end)()
end
