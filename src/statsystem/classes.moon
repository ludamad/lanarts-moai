attributes = require "@attributes"
items = require "@items"

M = nilprotect {} -- Submodule
classes = nilprotect {}
M.classes = classes

M.MAGE_NAMES_FOR_SKILL = nilprotect {
    ["fire_mastery"]: "Pyromancer"
    ["water_mastery"]: "Aquamancer"
    ["death_mastery"]: "Deathmage"
    ["life_mastery"]: "Lifemage"
    ["curses"]: "Hexcrafter"
    ["enchantments"]: "Enchanter"
    ["force_spells"]: "Warmage"
    ["earth_mastery"]: "Druid"
    ["air_mastery"]: "Windsmage"
}

MINOR = 100
MODERATE = 200
MAJOR = 400

add_item = (stats, itemdesc) ->
    {:type, :enchantment, :is_equipped} = itemdesc
    item = items.make_item(type)
    if enchantment ~= nil
        item.enchantment = enchantment
    if is_equipped ~= nil
        item.is_equipped = is_equipped
    stats.inventory\add item

add_spells_and_items = (stats, _class) ->
    for itemdesc in *_class.items
        add_item(stats, itemdesc)

classes.Mage = {
    description: (args) -> "A magical warrior, specializing in " .. attributes.SKILL_ATTRIBUTE_NAMES[args.magic_skill] .. "."
    items: {}

    -- Takes 'weapon_skill', 'skill'
    stat_class_adjustments: (args, stats) ->
        stats.class_name = M.MAGE_NAMES_FOR_SKILL[args.magic_skill]
        add_spells_and_items(stats, classes.Mage)
        W = stats.skill_weights
        W.magic = MAJOR
        W[args.magic_skill] = MAJOR
        W[args.weapon_skill] = MINOR
        W.melee = MINOR
        W.armour = MINOR
        W.defending = MINOR

    spells: {"Minor Missile"}
}

classes.Knight = {
    description: (__unused) -> "A disciplined, heavily armoured warrior."
    items: { 
        {type: "Health Potion"}, 
        {type: "Leather Boots", enchantment: 0, is_equipped: true}
        {type: "Chainshirt", enchantment: 1, is_equipped: true}
        {type: "Horned Helmet", enchantment: 1, is_equipped: true}
    }
    spells: {"Berserk"}

    -- Takes 'weapon_skill', 'skill'
    stat_class_adjustments: (args, stats) ->
        -- TODO: Skill dependence
        add_item stats, {type: "Dagger", is_equipped: true}
        stats.class_name = "Knight"
        add_spells_and_items(stats, classes.Knight)
        W = stats.skill_weights
        W.melee = MAJOR
        W[args.weapon_skill] = MAJOR

        W.armour = MODERATE
        W.defending = MINOR
}

classes.Archer = {
    description: (__unused) -> "A master of ranged combat. Fires swiftly from afar."
    items: { 
        {type: "Health Potion"}, 
        {type: "Leather Armour", enchantment: 0, is_equipped: true}
        {type: "Leather Cap", enchantment: 1, is_equipped: true}
        {type: "Short Bow", enchantment: 1, is_equipped: true}
        {type: "Arrow", amount: 50, is_equipped: true}
    }
    spells: {"Magic Arrow"}
    stat_class_adjustments: (__unused, stats) ->
        stats.class_name = "Archer"
        add_spells_and_items(stats, classes.Archer)
        W = stats.skill_weights
        W.melee = MINOR
        W.ranged_weapons = MAJOR
        W.armour = MINOR
        W.defending = MODERATE
}

table.merge(M, classes)
return M
