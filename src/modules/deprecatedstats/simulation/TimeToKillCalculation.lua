-- Calculate the steps ('time') required to kill a monster.
-- Intended for a rough, comparable figure of a character's damage output when using a certain weapon / spell / action.

local StatContext = require "@StatContext"
local LogUtils = require "core.LogUtils"
local Actions = require "@Actions"
local ActionContext = require "@ActionContext"
local ActionUtils = require "@stats.ActionUtils"
local ProjectileEffect = require "@stats.ProjectileEffect"
local RangedWeaponActions = require "@items.RangedWeaponActions"
local StatContext = require "@StatContext"
local StatPrereqs = require "@StatPrereqs"
local EventLog = require "ui.EventLog"
local StatUtils = require "@stats.StatUtils"

local M = nilprotect {} -- Submodule

local function mock_object(stat_context)
    local obj = {
        xy = {0,0},
        base_stats = stat_context.base,
        radius = stat_context.obj.radius,
        traits = {}
    }
    setmetatable(obj, {__index = function() return do_nothing end})
    return obj
end

local function mock_stat_context(SC)
    local base, derived = table.deep_clone(SC.base), table.deep_clone(SC.derived)
    return StatContext.stat_context_create(base, derived, mock_object(SC)) 
end

local function action_remove_distance_prereq(A)
    Actions.reset_prerequisite(A, StatPrereqs.DistancePrereq)
end

local function action_remove_sound(A)
    local custom_effects = Actions.get_all_effects(A, ActionUtils.CustomEffect)
    for custom_effect in values(custom_effects) do
        if rawget(custom_effect, "sound") then -- TODO: Ad hoc check for sounds, for now.
            table.remove_occurrences(A.effects, custom_effect)
        end
    end
end

local function action_collapse_nested(A, effect_type)
    local effect = Actions.reset_effect(A, effect_type) -- Grab and remove
    if effect then
        table.insert_all(A.effects, effect.action.effects)
    end
end

local function mock_action(A)
    local copy = table.deep_clone(A)
    action_collapse_nested(copy, ProjectileEffect)
    action_collapse_nested(copy, RangedWeaponActions.AmmoFireEffect)
    action_remove_distance_prereq(copy)
    action_remove_sound(copy)
    return copy
end

local function mock_action_context(AC)
    local copy = table.clone(AC)
    copy.user = mock_stat_context(AC.user)
    copy.base = mock_action(AC.base)
    copy.derived = mock_action(AC.derived)
    return copy
end

local function simulate(action_context, target, max_time)
    action_context = mock_action_context(action_context)
    target = mock_stat_context(target)

    for steps=1,max_time do
        StatUtils.stat_context_on_step(action_context.user)
        StatContext.on_calculate(action_context.user)

        StatUtils.stat_context_on_step(target)
        StatContext.on_calculate(target)

        if ActionContext.can_use_action(action_context, target) then
            ActionContext.use_action(action_context, target)
        end
        if target.base.hp <= 0 then 
            return steps
        end
    end

    pretty(action_context.derived)
    pretty(target.base)
    assert(false)
    return math.huge
end

local MAX_TIME = 5000
function M.calculate_time_to_kill(action_context, target, --[[Optional]] max_time)
    -- Silence the system
    local was_debug = LogUtils.get_debug_mode()
    local log_add_prev = EventLog.add

    LogUtils.set_debug_mode(false)
    EventLog.add = do_nothing

    local steps = simulate(action_context, target, max_time or MAX_TIME)

    -- Louden the system
    LogUtils.set_debug_mode(was_debug)
    EventLog.add = log_add_prev

    return steps
end

return M
