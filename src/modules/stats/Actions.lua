-- Actions consist of a 'target_type', 'prerequisites' list, and 'effects' list.
-- They are the main building blocks of spells, items, etc

local assert, table, type, ipairs, getmetatable = assert, table, type, ipairs, getmetatable -- Cache for small performance boost

local StatContext = require "@StatContext"

local M = nilprotect {} -- Submodule

M.TARGET_TYPES = {
-- Useful for monster AI and auto-targetting.
    "TARGET_NONE", -- NOTE: Sets up 'user' as 'target'!
-- Position targetting (eg projectile spells)
    "TARGET_HOSTILE_POSITION",
    "TARGET_FRIENDLY_POSITION",
-- Object targetting (eg melee attacks)
    "TARGET_HOSTILE",
    "TARGET_FRIENDLY"
}

-- Expose target types:
for v in values(M.TARGET_TYPES) do
    M[v] = v
end

function M.is_target_position(target)
    return not getmetatable(target) and (#target == 2)
end

function M.is_target_stat_context(target)
    return getmetatable(target) and target.obj
end

function M.can_use_action(user, action, target, --[[Optional]] action_source)
    if action.on_prerequisite then
        local ok, problem = action.on_prerequisite(action_source, user, target)
        if not ok then return false, problem end 
    end
    for _, prereq in ipairs(action.prerequisites) do
        local ok, problem = prereq:check(user, target)
        if not ok then return false, problem end 
    end
    return true
end

function M.use_action(user, action, target, --[[Optional]] action_source, --[[Optional]] ignore_death)
    local ret
    if action.on_use then
        local res = action.on_use(action_source, user, target)
        ret = ret or res
    end

    for _, effect in ipairs(action.effects) do
        local res = effect:apply(user, target)
        ret = ret or res
    end

    if not ignore_death and type(target) == "table" and target.obj then
        if target.base.hp <= 0 then
            StatContext.on_death(target, user)
        end
    end

    return ret
end

function M.copy_action(action, copy)
    copy.on_prerequisite, copy.on_use = action.on_prerequisite, action.on_use
    copy.effects = copy.effects or {}
    copy.prerequisites = copy.prerequisites or {} 
    table.deep_array_copy(action.effects, copy.effects)
    table.deep_array_copy(action.prerequisites, copy.prerequisites)
end

-- Lookup all effects of a certain type.
function M.get_all_effects(action, type)
    local effects = {}
    for _, v in ipairs(action.effects) do
        if getmetatable(v) == type then table.insert(effects,v) end
    end
    return effects
end

-- Lookup all prerequisites of a certain type.
function M.get_all_prerequisites(action, type)
    local prereqs = {}
    for _, v in ipairs(action.prerequisites) do
        if getmetatable(v) == type then table.insert(prereqs,v) end
    end
    return prereqs
end

-- Lookup the unique effect of a given type.
-- Errors if multiple matching effects exist!
function M.get_effect(action, type)
    local effects = M.get_all_effects(action, type)
    assert(#effects <= 1)
    return effects[1]
end

-- Replace the unique effect of a given type.
-- Errors if multiple matching effects exist!
-- Removes the type if new_effect is nil.
function M.reset_effect(action, type, --[[Optional]] new_effect)
    local effects = M.get_all_effects(action, type)
    assert(#effects <= 1)
    for _, effect in ipairs(effects) do 
        table.remove_occurrences(action.effects, effect)
    end
    if new_effect then
        table.insert(action.effects, new_effect)
    end
    return effects[1]
end

-- Replace the unique effect of a given type.
-- Errors if multiple matching effects exist!
-- Removes the type if new_effect is nil.
function M.reset_prerequisite(action, type, --[[Optional]] new_prereq)
    local prereqs = M.get_all_prerequisites(action, type)
    assert(#prereqs <= 1)
    for _, prereq in ipairs(prereqs) do 
        table.remove_occurrences(action.prerequisites, prereq)
    end
    if new_prereq then
        table.insert(action.prerequisites, new_prereq)
    end
    return prereqs[1]
end

-- Lookup the unique prerequisite of a given type.
-- Errors if multiple matching prerequisites exist!
function M.get_prerequisite(action, type)
    local prereqs = M.get_all_prerequisites(action, type)
    assert(#prereqs <= 1)
    return prereqs[1]
end

return M
