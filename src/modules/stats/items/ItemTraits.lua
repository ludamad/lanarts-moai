local Apts = require "@stats.AptitudeTypes"
local M = nilprotect {} -- Submodule

M.equipment_slot_capacities = {
    WEAPON = 1,
    BODY_ARMOUR = 1,
    RING = 2,
    GLOVES = 1,
    BOOTS = 1,
    BRACERS = 1,
    AMULET = 1,
    HEADGEAR = 1,
    AMMUNITION = 1
}

local consumable_types = {
    "POTION", 
    "SCROLL",
}

M.ammunition_types = {
    ARROW = "arrows", -- For bows
    STONE = "stones" -- For unarmed use
}

for type,cap in pairs(M.equipment_slot_capacities) do M[type] = type end
for type,cap in pairs(M.ammunition_types) do M[type] = type end
for type in values(consumable_types) do M[type] = type end

M.default_equipment_slot_types = {
    [M.WEAPON] = Apts.WEAPON_IDENTIFICATION,
    [M.AMMUNITION] = Apts.WEAPON_IDENTIFICATION,
    [M.RING] = Apts.MAGIC_ITEMS,
    [M.AMULET] = Apts.MAGIC_ITEMS,
    [M.HEADGEAR] = Apts.ARMOUR,
    [M.BODY_ARMOUR] = Apts.ARMOUR,
    [M.GLOVES] = Apts.ARMOUR,
    [M.BOOTS] = Apts.ARMOUR,
    [M.BRACERS] = Apts.ARMOUR
}

return M