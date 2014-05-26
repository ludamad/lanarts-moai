local resources = require "resources"
local Map = require "levels.Map"

local function load_map(file)
    local json = resources.get_json(file)
    assert(json, "Trouble loading JSON from " .. file .. "!")
end

return {
    load_map = load_map
}