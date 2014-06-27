local RaceType = require "@RaceType"

local Apts = require "@stats.AptitudeTypes"
local Stats = require "@Stats"
local StatContext = require "@StatContext"
local ContentUtils = require "@stats.ContentUtils"
local ActionUtils = require "@stats.ActionUtils"
local Attacks = require "@Attacks"

local M = nilprotect {} -- Submodule

-- A more convenient race_define
function M.races_define(args)
    args.description = args.description:pack()
    if args.on_create then -- Full custom
        return RaceType.define(args)
    end

    args.aptitude_types = args.aptitude_types or {Apts.BLUNT, Apts.MELEE} -- For ActionUtils.derive_action
    args.damage = args.damage or 5
    local action = args.unarmed_action or args
    action.sound = {"Swing1", "Swing2", "Swing3"}
    args.unarmed_action = ActionUtils.derive_action(action, ActionUtils.ALL_ACTION_COMPONENTS, --[[Cleanup]] true)
    -- Create based off embedded stats, aptitudes & spells
    args.movement_speed = 4
    local stat_template = ContentUtils.resolve_embedded_stats(args, --[[Resolve skill costs]] true)
    function args.on_create(name)
        local stats = Stats.stats_create(stat_template, --[[Add skills]] true)
        stats.name = name
        stats.race = args
        return stats
    end

    return RaceType.define(args)
end

return M