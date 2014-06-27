local spell_define = (require "@spells.SpellDefineUtils").spell_define
local StatusType = require "@StatusType"
local Apts = require "@stats.AptitudeTypes"
local ItemTraits = require "@items.ItemTraits"
local SpellTraits = require "@spells.SpellTraits"

spell_define {
	name = "Magic Arrow",
	description = "Allows you to create an arrow of pure energy. Requires a bow.", -- TODO COLOURS!!
	mp_cost = 20,
	sprite = "sprites/crystal_spear.png%32x32",

    equipment_prereq = {trait = Apts.BOWS, name = "a Bow", slot = ItemTraits.WEAPON},

    range = 150,
    cooldown_spell = 45,

    created_projectile = {
        speed = 9, radius = 8,
        aptitude_types = {Apts.MAGIC, Apts.BOWS, Apts.RANGED},
        damage = 5, effectiveness = 0
    }
}