local Display = require "ui.Display"

local StatContext = require "stats.StatContext"
local Apts = require "stats.stats.AptitudeTypes"
local StatUtils = require "stats.stats.StatUtils"
local Stats = require "stats.Stats"
local StatContext = require "stats.StatContext"
local CooldownTypes = require "stats.stats.CooldownTypes"
local ExperienceCalculation = require "stats.stats.ExperienceCalculation"

local M = nilprotect {} -- Module

-- Color escape utility:
local function C(col, text)
    return Display.colorEscapeCode(col) .. text
end

function M.stats_to_string(s, --[[Optional]] use_color, --[[Optional]] use_new_lines, --[[Optional]] alternate_name)
    local R = StatUtils.round_for_print

    local ret = ("%s %s %s %s %s"):format(
        C(Display.COL_WHITE, alternate_name or s.name),
        C(Display.COL_GREEN, ("HP %d/%d"):format(R(s.hp), s.max_hp)), 
        C(Display.COL_BLUE, ("MP %d/%d"):format(R(s.mp), s.max_mp)),
        C(Display.COL_YELLOW, ("XP %d/%d"):format(s.xp, ExperienceCalculation.level_experience_needed(s.level))),
        C(Display.COL_YELLOW, ("(%d%%)"):format(math.floor(ExperienceCalculation.level_progress(s.xp, s.level)*100)))
    )

    local traits = {}
    for category,apts in pairs(s.aptitudes) do
        for trait,amnt in pairs(apts) do
            traits[trait] = true
        end
    end

    local trait_list = table.key_list(traits)
    table.sort(trait_list)
    local trait_strings = {""}
    for trait in values(trait_list) do
        local apts = s.aptitudes
        local not_all_0 = false
        local function apt(cat) -- Helper function
            local s = apts[cat][trait]
            local pre = to_camelcase(cat:sub(1,3)) .. ' '
            if s and s ~= 0 then
                not_all_0  = true 
                        if s > 0 then 
                    return C(Display.COL_CYAN, pre.. '+' .. s)
                else 
                    return C(Display.COL_RED, pre .. s)
                end
            end
            return C(Display.COL_MAGENTA, pre .. '--')
        end
        local str = ("%s%s %s %s %s %s%s"):format(
            C(Display.COL_WHITE, '('),
            C(Display.COL_GREEN, to_camelcase(trait)), 
            apt("effectiveness"), apt("damage"), apt("resistance"), apt("defence"),
            C(Display.COL_WHITE, ')')
        )
        if not_all_0 then
            table.insert(trait_strings, str)
        end
    end
    ret = ret .. (use_new_lines and "\n" or " "):join(trait_strings)
    return ret
end

return M -- Return module