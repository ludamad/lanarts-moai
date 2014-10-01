local M = nilprotect {}
local races = nilprotect {}
M.races = races

UNARMED = {
    damage = 5,
    power =  0,
    delay = 1.0,
    cooldown = 1.0,
    range = 4
}

local function base_stat_adjustment(race, stats)
    local sA = stats.attributes
    sA.raw_hp, sA.raw_mp, sA.raw_ep = race.hp, race.mp, race.ep
    sA.raw_max_hp, sA.raw_max_mp, sA.raw_max_ep = race.hp, race.mp, race.ep
    sA.raw_hp_regen, sA.raw_mp_regen = race.hp_regen, race.mp_regen
    local A = stats.attack
    A.on_hit_sprite = "Unarmed"

    -- Default unarmed attack
    A.raw_physical_dmg = UNARMED.damage
    A.raw_physical_power = UNARMED.power
    A.raw_delay = require("@constants").BASE_ACTION_DELAY * UNARMED.delay
    A.raw_cooldown = require("@constants").BASE_ACTION_COOLDOWN * UNARMED.cooldown
    A.raw_range = UNARMED.range
    -- Unlikely to change, for any race:
    sA.raw_move_speed = 6
end

races.Undead = {
    description = string.pack [[
    A creature of unlife, summoned by an ancient curse. The greatest of the undead can control their new form.
    Undead adventurers do not regenerate HP naturally, instead manipulating their curse to heal themselves.
    They possess great aptitude in the dark arts.
]],

    stat_race_adjustments = function(stats)
        base_stat_adjustment(races.Undead, stats)
    end,

    avatar_sprite = "sr-undead",
    hp = 80,  hp_regen = 0, -- None!
    ep = 25, ep_regen = 0.020,
    mp = 100, mp_regen = 0.012,

    -- [Apts.DARK] = {2,1,2,1}, 
    -- [Apts.CURSES] = {2,0,0,0}, 
    -- [Apts.ENCHANTMENTS] = {2,0,0,0}, 
    -- [Apts.POISON] = {0,0,20,0},

    -- [Apts.LIGHT] = -2,

    spells = {{
        name = "Benevolent Curse",
        description = "You gain control of the curse that brought you to unlife, manipulating it to heal yourself.",
        traits = {"buff"},
        mp_cost = 30,
        cooldown_offensive = 35,
        target_type = "none",

        heal_amount = 30,

        on_prerequisite = function (self, caster)
            return caster.base.hp < caster.derived.max_hp, "That would be a waste!"
        end,

        on_use = function (self, caster)
            local StatContext = require "@StatContext"
            local LogUtils = require "core.LogUtils"
            local actual = StatContext.add_hp(caster, self.heal_amount)
            LogUtils.event_log_resolved(caster.obj, "<The >$You invoke [the]{its} curse to gain{s} " .. actual .. "HP!", Display.COL_GREEN)
        end
    }}
}

races.Human = {
    description = string.pack [[
    A versatile race. Humans adventurers have high health and mana reserves. 
    They possess great aptitude at using tools and performing physical maneuvers. 
]],

    stat_race_adjustments = function(stats)
        base_stat_adjustment(races.Human, stats)
    end,

    avatar_sprite = "sr-human",
    hp = 100, hp_regen = 0.020,
    ep = 25, ep_regen = 0.020,
    mp = 100, mp_regen = 0.012,

    -- [Apts.SELF_MASTERY] = {2,0,0,0},
    -- [Apts.MAGIC_ITEMS] = {2,0,0,0},
    -- [Apts.WEAPON_IDENTIFICATION] = {2,0,0,0}
}

races.Orc = {
    description = string.pack [[
    A brutish race. Orcish magic and combat focuses on dealing heavy blows. 
    Additionally, they possess great aptitude at using magic devices and performing physical maneuvers.
    They train Armour & Force skills 15% faster. 
]],

    stat_race_adjustments = function(stats)
        base_stat_adjustment(races.Orc, stats)
    end,

    avatar_sprite = "sr-orc",
    hp = 100, hp_regen = 0.010,
    ep = 25, ep_regen = 0.020,
    mp = 80,  mp_regen = 0.008,

    -- [Apts.MELEE] = {-2,1,0,0},
    -- [Apts.MAGIC] = {-2,1,0,0},

    -- [Apts.FORTITUDE] = {2,0,0,0},
    -- [Apts.WILLPOWER] = {2,0,0,0},
    -- [Apts.EARTH] = {2,0,0,0},

    -- [Apts.AIR] = {-2,0,0,0},

    skill_costs = {
        ["Armour"] = 0.85, 
        ["Force"] = 0.85
    }
}

table.merge(M, races)
return M
