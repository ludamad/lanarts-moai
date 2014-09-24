attributes = require "@attributes"

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

classes.Mage = {
  description: (args) -> "A magical warrior, specializing in " .. attributes.SKILL_ATTRIBUTE_NAMES[args.magic_skill] .. "."
  items: {}

  -- Takes 'weapon_skill', 'skill'
  stat_class_adjustments: (args, stats) ->
    stats.class_name = M.MAGE_NAMES_FOR_SKILL[args.magic_skill]
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
    "Health Potion", 
    {type: "Leather Boots", bonus: 0, equipped: true}
    {type: "Chainshirt", bonus: 1, equipped: true}
    {type: "Horned Helmet", bonus: 1, equipped: true}
  }
  spells: {"Berserk"}

  -- Takes 'weapon_skill', 'skill'
  stat_class_adjustments: (args, stats) ->
     stats.class_name = "Knight"
     W = stats.skill_weights
     W.melee = MAJOR
     W[args.weapon_skill] = MAJOR
     W.armour = MODERATE
     W.defending = MINOR
}

classes.Archer = {
  description: (__unused) -> "A master of ranged combat. Fires swiftly from afar."
  items: { 
    "Health Potion", 
    {type: "Leather Armour", bonus: 0, equipped: true}
    {type: "Leather Cap", bonus: 1, equipped: true}
    {type: "Short Bow", bonus: 1, equipped: true}
    {type: "Arrow", amount: 50, equipped: true}
  }
  spells: {"Magic Arrow"}
  stat_class_adjustments: (__unused, stats) ->
    stats.class_name = "Archer"
    W = stats.skill_weights
    W.melee = MINOR
    W.ranged_weapons = MAJOR
    W.armour = MINOR
    W.defending = MODERATE
}

table.merge(M, classes)
return M