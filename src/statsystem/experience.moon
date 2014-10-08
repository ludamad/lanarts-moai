attributes = require "@attributes"

M = nilprotect {} -- Submodule

M.SKILL_POINT_START_AMOUNT = 500
M.SKILL_POINT_COST_RATE = 100

M.EXPERIENCE_EXPONENT = 2.7
M.EXPERIENCE_COST_RATE = 75
M.EXPERIENCE_COST_BASE = 125

average_kills_per_level = (rating) -> 10 + 5 * rating

M.challenge_rating_to_xp_gain = (user_level, rating) ->
    gain = M.level_experience_needed(rating) / average_kills_per_level(rating)
    -- For every CR point lower than user_level - 1, remove 25%
    multiplier = math.max(0, 1 - (user_level-1 - rating) / 4)
    multiplier = math.min(multiplier, 1.0)
    return multiplier * gain

-- xp_level is the current level, and the amount of experience needed for the next level is returned.
M.level_experience_needed = (xp_level) ->
    return math.round(xp_level ^ M.EXPERIENCE_EXPONENT * M.EXPERIENCE_COST_RATE) + M.EXPERIENCE_COST_BASE

skill_cost_increment = (level) ->
    return level * M.SKILL_POINT_COST_RATE

-- Determines the amount of skill points received at each level-up
M.skill_points_at_level_up = (xp_level) ->
    return skill_cost_increment(xp_level+1)

skill_point_cost = (multiplier, xp_level) ->
    return skill_cost_increment(math.floor(xp_level * (xp_level + 1) / 2 * multiplier))

M.cost_from_skill_level = (multiplier, xp_level) ->
    f = math.floor(xp_level)
    rem = xp_level - f
    xp = (1-rem) * skill_point_cost(multiplier, f) + rem * skill_cost_increment(f+1)
    return math.ceil(xp)

M.skill_level_from_cost = (multiplier, xp) ->
    for lvl=0,math.huge do
        xp_base = skill_point_cost(multiplier, lvl)
        incr = skill_cost_increment(lvl + 1) 
        if xp_base + incr > xp then
           true_level = lvl + (xp - xp_base) / incr
           return math.floor(true_level * 10) / 10
    assert(false)

M.level_progress = (xp, level) ->
    pre_xp_cost = 0
    if level > 1 then 
        pre_xp_cost = M.level_experience_needed(level - 1)
    xp_cost = M.level_experience_needed(level)
    return (xp - pre_xp_cost) / (xp_cost - pre_xp_cost)

-- Gain skill points in 'SKILL_POINT_INTERVALS' intervals
SKILL_POINT_INTERVALS = 10

amount_needed = (xp, level) -> M.level_experience_needed(level) - xp

-------------------------------------------------------------------------------
-- Experience gain resolution:
-------------------------------------------------------------------------------
on_spend_skill_points = (stats, skill, points, logger = nil) ->
    old_level = stats.skill_levels[skill]
    stats.skill_points[skill] += points
    new_level = M.skill_level_from_cost(stats.skill_cost_multipliers[skill], stats.skill_points[skill])
    stats.skill_levels[skill] = new_level
    if logger and math.floor(old_level) < math.floor(new_level) then
        logger "$YOUR %s skill has reached level %d!", 
            attributes.CORE_ATTRIBUTE_NAMES[skill], math.floor(new_level)

-- Allocate skill points, according to chosen weights.
-- Safe even for a skill point increase of one (will be spread thin, but will accumulate over time).
M.allocate_skill_points = (stats, skill_points, logger = nil) ->
    total_weight = 0
    for skill in *attributes.SKILL_ATTRIBUTES
        total_weight += stats.skill_weights[skill]
    assert total_weight > 0, "Should have at least one skill chosen!"
    for skill in *attributes.SKILL_ATTRIBUTES
        allocation = (stats.skill_weights[skill] * skill_points / total_weight)
        on_spend_skill_points(stats, skill, allocation, logger)

M.level_up = (stats) ->
    stats.level += 1
    stats.raw_hp += 10
    stats.raw_max_hp += 10
    stats.raw_mp += 10
    stats.raw_max_mp += 10

M.gain_xp = (stats, xp, log = nil) ->
    assert(xp >= 0, "Cannot gain negative experience!")
    old_hp, old_mp = stats.raw_max_hp, stats.raw_max_mp
    old_level = stats.level
    skill_points_gained = 0

    -- Loop if we have enough XP to levelup.
    -- Guarantees correctness for large XP gains.
    while xp > 0 
        old_xp, new_xp = stats.xp,stats.xp+xp

        intervals_prev = math.floor(M.level_progress(old_xp, stats.level) * SKILL_POINT_INTERVALS)
        intervals_new = math.floor(M.level_progress(new_xp, stats.level) * SKILL_POINT_INTERVALS)
        intervals_new = math.min(intervals_new, SKILL_POINT_INTERVALS)

        -- Gain skill points at regular intervals:
        for i=intervals_prev+1,intervals_new do
            skill_points_gained += M.skill_points_at_level_up(stats.level) / SKILL_POINT_INTERVALS 

        needed = math.max(0, amount_needed(old_xp, stats.level))
        xp_spent = math.min(xp, needed)
        xp = xp - xp_spent
        stats.xp = stats.xp + xp_spent

        if needed <= 0 
            -- Levelup!
            M.level_up(stats)

    M.allocate_skill_points(stats, skill_points_gained, log)

    levels_gained = stats.level - old_level
    if skill_points_gained > 0 and log
        log("YOU gain(s) %d skill points!", skill_points_gained)
    if levels_gained > 0 and log
        level_str = (levels_gained == 1) and ("a level") or (levels_gained.. " levels")
        log("$YOU (has)[have] levelled up! $YOU (is)[are] now level %d!", level_str, stats.level)

    -- Log any changes to MP or HP
    hp_gained, mp_gained = stats.raw_max_hp - old_hp, stats.raw_max_mp - old_mp
    if mp_gained > 0 and log
        log("$You gain(s) %d MP!", mp_gained)
    if hp_gained > 0  and log
        log("$You gain(s) %d HP!", hp_gained)
-------------------------------------------------------------------------------

return M
