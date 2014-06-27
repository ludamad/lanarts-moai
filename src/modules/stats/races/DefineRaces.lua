local SpellType = require "@SpellType"
local SpellTraits = require "@spells.SpellTraits"
local Apts = require "@stats.AptitudeTypes"
local Actions = require "@Actions"

local races_define = (require "@races.RaceDefineUtils").races_define

races_define {
    name = "Undead",
    description = [[
    A creature of unlife, summoned by an ancient curse. The greatest of the undead can control their new form.
    Undead adventurers do not regenerate HP naturally, instead manipulating their curse to heal themselves.
    They possess great aptitude in the dark arts.
]],

    hp = 80,  hp_regen = 0, -- None!
    mp = 100, mp_regen = 0.012,

    [Apts.DARK] = {2,1,2,1}, 
    [Apts.CURSES] = {2,0,0,0}, 
    [Apts.ENCHANTMENTS] = {2,0,0,0}, 
    [Apts.POISON] = {0,0,20,0},

    [Apts.LIGHT] = -2,

    spells = {{
        name = "Benevolent Curse",
        description = "You gain control of the curse that brought you to unlife, manipulating it to heal yourself.",
        traits = {SpellTraits.BUFF_SPELL},
        mp_cost = 30,
        cooldown_offensive = 35,
        target_type = Actions.TARGET_NONE,

        heal_amount = 30,

        on_prerequisite = function (self, caster)
            return caster.base.hp < caster.derived.max_hp, "That would be a waste!"
        end,

        on_use = function (self, caster)
            local StatContext = require "@StatContext"
            local LogUtils = require "core.LogUtils"
            local actual = StatContext.add_hp(caster, self.heal_amount)
            LogUtils.event_log_resolved(caster.obj, "<The >$You invoke [the]{its} curse to gain{s} " .. actual .. "HP!", COL_GREEN)
        end
    }}
}

races_define {
    name = "Human",
    description = [[
    A versatile race. Humans adventurers have high health and mana reserves. 
    They possess great aptitude at using tools and performing physical maneuvers. 
]],

    hp = 100, hp_regen = 0.010,
    mp = 100, mp_regen = 0.012,

    [Apts.SELF_MASTERY] = {2,0,0,0},
    [Apts.MAGIC_ITEMS] = {2,0,0,0},
    [Apts.WEAPON_IDENTIFICATION] = {2,0,0,0}
}

races_define {
    name = "Orc",
    description = [[
    A brutish race. Orcish magic and combat focuses on dealing heavy blows. 
    Additionally, they possess great aptitude at using magic devices and performing physical maneuvers.
    They train Armour & Force skills 15% faster. 
]],

    hp = 100, hp_regen = 0.010,
    mp = 80,  mp_regen = 0.008,

    [Apts.MELEE] = {-2,1,0,0},
    [Apts.MAGIC] = {-2,1,0,0},

    [Apts.FORTITUDE] = {2,0,0,0},
    [Apts.WILLPOWER] = {2,0,0,0},
    [Apts.EARTH] = {2,0,0,0},

    [Apts.AIR] = {-2,0,0,0},

    skill_costs = {
        ["Armour"] = 0.85, 
        ["Force"] = 0.85
    }
}