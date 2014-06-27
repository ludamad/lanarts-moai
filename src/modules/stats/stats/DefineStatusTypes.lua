local StatusType = require "@StatusType"
local StatContext = require "@StatContext"

local CooldownTypes = require "@stats.CooldownTypes"
local Apts = require "@stats.AptitudeTypes"
local LogUtils = require "core.LogUtils"
local status_type_define = (require "@stats.StatusTypeUtils").status_type_define

-- EXHAUSTION
local EXHAUSTION_MOVEMENT_MULTIPLIER = 0.75
local EXHAUSTION_ATTACK_COOLDOWN_MULTIPLIER = 0.75
local Exhausted = status_type_define {
    name = "Exhausted",
    time_limited = true,
    on_draw = { sprite = "exhausted.png", new_color = COL_PALE_BLUE },
    init = function(self, stats, ...)
        self.base.init(self, stats, ...)
        LogUtils.event_log_player(stats.obj, "$You {is}[are] now exhausted.", {255,200,200})
    end,
    on_calculate = function(self, stats)
        local D = stats.derived
        CooldownTypes.multiply_all_cooldown_rates(stats, 0.8)
        StatContext.add_damage(stats, Apts.MELEE, -2)
        StatContext.add_defence(stats, Apts.MELEE, -3)
        D.movement_speed = D.movement_speed / 2
    end,
    on_deregister = function(self, stats)
       LogUtils.event_log_player(stats.obj, "$You {is}[are] no longer exhausted.", {200,200,255})
    end
}

-- BERSERKING
local BERSERK_EXHAUSTION_DURATION = 275

status_type_define {
    name = "Berserk",
    time_limited = true,
    init = function(self, stats, ...)
       self.base.init(self, stats, ...)
       self.extensions = 0
       LogUtils.event_log_player(stats.obj, "$You enter{s} a powerful rage!", {200,200,255})
    end,
    on_draw = { sprite = "berserk.png", new_color = COL_PALE_RED },
    on_calculate = function(self, stats)
        local D = stats.derived

        -- Stat bonuses
        StatContext.add_damage(stats, Apts.MELEE, 2)
        StatContext.add_defence(stats, Apts.MELEE, 4 + D.level)

        -- Speed bonsues
        D.movement_speed = D.movement_speed + 1
        StatContext.add_effectiveness(stats, Apts.MELEE_SPEED, 7)

        CooldownTypes.reset_rest_cooldown(stats)
    end,
    on_kill = function(self, stats)
        -- Extend the berserking
        local time_bonus = self.extensions < 5 and 20 or 5
        if self.extensions == 0 then time_bonus = 30 end
        self:add_duration(time_bonus)
        self.extensions = self.extensions + 1
        LogUtils.debug_log(stats.obj.name," berserking time extends by ", time_bonus)
        LogUtils.event_log_resolved(stats.obj, "<The >{$You's}[Your] rage grows ...", {200,200,255})
    end,
    on_deregister = function(self, stats)
       local B = stats.base
       StatusType.update_hook(B.hooks, Exhausted, stats, BERSERK_EXHAUSTION_DURATION)
    end
}