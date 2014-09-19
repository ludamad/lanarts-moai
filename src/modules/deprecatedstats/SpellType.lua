-- Usage: 'SpellType.define { ... attributes ... }', 'SpellType.lookup(<name or ID>)'
local S = require "@Schemas"
local ResourceTypes = require "@ResourceTypes"
local Actions = require "@Actions"

local M = nilprotect {} -- Submodule

local DEFAULT_GLOBAL_COOLDOWN = 40
local DEFAULT_RANGE = 300

local function sprite_assert(s) 
    if not s.draw then
        assert(s.draw, "Schema expected sprite (ie, has draw() member) but got:\n " .. pretty_tostring(s,nil,true))
    end
end

local schema = {
    lookup_key = S.STRING,
--    sprite = sprite_assert,

    target_type = S.one_of(Actions.TARGET_TYPES, --[[default]] Actions.TARGET_HOSTILE_POSITION),
    range = S.defaulted(S.NUMBER, DEFAULT_RANGE),
    mp_cost = S.defaulted(S.NUMBER, 0),

--    use_action = S.TABLE,
    on_create = S.FUNCTION
}

local function create(t)
    t.lookup_key = t.lookup_key or t.name
    S.enforce(schema, t)
    return t
end

local SpellType = ResourceTypes.type_create(create, nil, nil, --[[Lookup key]] "lookup_key")

M.define = SpellType.define
M.lookup = SpellType.lookup

return M