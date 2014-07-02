local HookSet = require "@HookSet"
local CooldownSet = require "@CooldownSet"
local Inventory = require "@Inventory"
local SpellsKnown = require "@SpellsKnown"
local Attacks = require "@Attacks"
local SkillType = require "@SkillType"

local M = {} -- Submodule

-- Create a skill table with the given values. Defaults are used for anything not provided.
function M.skills_create(--[[Optional]] params, --[[Optional]] add_skills)
    local ret = {}
    if params then 
        for skill_slot in values(params) do
            table.insert(ret, table.clone(skill_slot)) 
        end
    end
    if add_skills then
        for skill in values(SkillType.list) do
            local has_already = false
            for s in values(ret) do
                if s.type == skill then
                    has_already = true
                    break
                end 
            end
            if not has_already then
                table.insert(ret, skill:on_create())
            end
        end
    end
    return ret
end

-- Create an aptitude table with the given values. Defaults are used for anything not provided.
function M.aptitudes_create(--[[Optional]] params)
    params = params and table.deep_clone(params) or {}
    return {
        -- Each table is associated with a trait
        effectiveness = params.effectiveness or {},
        resistance = params.resistance or {},
        damage = params.damage or {},
        defence = params.defence or {}
    }
end

local function clone_if_exists(v, assert_metatable)
    if v then 
        local clone = table.deep_clone(v)
        assert(getmetatable(v) == getmetatable(clone))
        assert(not assert_metatable or getmetatable(v))
        return clone
    end
    return nil
end

-- Create stats with defaults, or copy over from other stats
function M.stats_create(--[[Optional]] params, --[[Optional]] add_skills)
    local C = clone_if_exists
    params = params or {}
    return {
        name = params.name,
        team = params.team,
        gold = params.gold or 0,

        level = params.level or 1,
        xp = params.xp or 0, -- Note, XP needed is a function of level
        skill_points = params.skill_points or 0,

    	-- The 'core stats', hp & mp. The rest of the stats are defined in terms of aptitudes.
        hp = params.hp or params.max_hp,
        max_hp = params.max_hp or params.hp,
        hp_regen = params.hp_regen or 0,

        mp = params.mp or params.max_mp or 0,
        max_mp = params.max_mp or params.mp or 0,
        mp_regen = params.mp_regen or 0,

        inventory = C(params.inventory, true) or Inventory.create(),
        aptitudes = M.aptitudes_create(params.aptitudes),
        skills = M.skills_create(params.skills, add_skills),
        hooks = C(params.hooks, true) or HookSet.create(),
        spells = C(params.spells, true) or SpellsKnown.create(),

        cooldowns = C(params.cooldowns, true) or CooldownSet.create(),

        movement_speed = params.movement_speed or 4
    }
end

function M.get_skill(stats, skill_type)
    for skill_slot in values(stats.skills) do
        if skill_slot.type == skill_type then
            return skill_slot
        end
    end
    assert(false)
end

return M