local CooldownSet = require "@CooldownSet"
local SlotUtils = require "@SlotUtils"
local SpellType = require "@SpellType"
local Actions = require "@Actions"

local SpellsKnown = newtype()

function SpellsKnown:init()
    self.spells = {}
end

function SpellsKnown:add_spell(spell_slot)
    -- Resolve item slot
    if type(spell_slot) == "string" then 
        spell_slot = SpellType.lookup(spell_slot) 
    end
    if not getmetatable(spell_slot) then
        if not spell_slot.type then spell_slot = {type = spell_slot} end
        spell_slot = spell_slot.type:on_create(spell_slot)
    end
    table.insert(self.spells, spell_slot)
end

function SpellsKnown:copy()
    local copy = SpellsKnown.create()
    for _, spell in ipairs(self.spells) do
        append(copy.spells, spell)
    end
    return copy
end

function SpellsKnown:values()
    return values(self.spells)
end

return SpellsKnown
