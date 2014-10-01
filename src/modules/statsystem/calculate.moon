-- Tries to consolidate the effects of stat calculations
-- Mostly, these are not used directly.
-- Instead the functions are assigned as methods of the relevant objects.

attributes = require "@attributes"
items = require "@items"
constants = require "@constants"

M = nilprotect {}

-- Common to NPC's and players
common_stat_calculate = (S, do_step = true) ->
    if do_step
        for cooldown in *attributes.COOLDOWN_ATTRIBUTES
             S.cooldowns[cooldown] = math.max(0, S.cooldowns[cooldown] - S.cooldown_rates[cooldown])
        S.raw_hp = math.min(S.raw_hp + S.hp_regen, S.max_hp)
        S.raw_mp = math.min(S.raw_mp + S.mp_regen, S.max_mp)
        S.raw_ep = math.min(S.raw_ep + S.ep_regen, S.max_ep)

    S.hp, S.mp, S.ep = S.raw_hp, S.raw_mp, S.raw_ep

-- NPC stat calculation.
-- Calculate derived stats from bonuses and their raw_* counterparts
M.npc_stat_calculate = (S, do_step = true) ->
    S\revert()
    M.attack_calculate(S.attack)
    common_stat_calculate(S, do_step)

-- Calculate derived stats from bonuses and their raw_* counterparts
M.player_stat_calculate = (S, do_step = true) ->
    S\revert()
    M.attack_calculate(S.attack)
    if do_step 
        S.is_sprinting = false
        if S.will_sprint_if_can and S.raw_ep >= constants.SPRINT_ENERGY_COST
            S.raw_ep -= constants.SPRINT_ENERGY_COST
            S.is_sprinting = true
            S.move_speed += constants.SPRINT_SPEEDUP
    if do_step and S.is_resting
         -- Handling healing due to rest
         S.hp_regen += S.raw_hp_regen * 7
         S.mp_regen += S.raw_mp_regen * 7
         S.ep_regen += S.raw_ep_regen * 7
    common_stat_calculate(S, do_step)

-- Attack calculations
M.attack_calculate = (A) ->
    inv = A.source.inventory
    weapon = inv\get_equipped(items.WEAPON)
    if weapon
        attack = weapon.kind.attack
        A\copy(attack)
    elseif A.source.is_player
        A\copy(A.source.race.attack)
    else
        A\revert()

M.attack_apply = (A, rng, dS) ->
    pow = A.physical_power - dS.physical_resist
    pow = math.max(pow + rng\random(10, 31), 0)
    dmg = math.max(A.physical_dmg - dS.defence, 0)
    dmg *= A.multiplier * pow * 0.05

    dS.raw_hp = math.max(0, dS.raw_hp - dmg)
    dS.cooldowns.hurt_cooldown = constants.HURT_COOLDOWN
    return math.round(dmg)

    -- "physical_dmg"
    -- "physical_power"

    -- -- Various sources, eg enchantments, weapon type:
    -- "magic_dmg"
    -- "fire_dmg"
    -- "water_dmg"
    -- "earth_dmg"
    -- "air_dmg"
    -- "death_dmg"
    -- "life_dmg"
    -- -- Damage over time:
    -- "poison_dmg"

    -- "magic_power"
    -- "fire_power"
    -- "water_power"
    -- "earth_power"
    -- "air_power"
    -- "death_power"
    -- "life_power"
    -- "poison_power"

    -- -- Enchantment plays a large part:
    -- "enchantment_bonus"
    -- "slaying_bonus"


return M
