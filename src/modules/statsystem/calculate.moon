-- Tries to consolidate the effects of stat calculations
-- Mostly, these are not used directly.
-- Instead the functions are assigned as methods of the relevant objects.

attributes = require "@attributes"
items = require "@items"
constants = require "@constants"

M = nilprotect {}

M.stat_step = (S) ->
  for cooldown in *attributes.COOLDOWN_ATTRIBUTES
     S.cooldowns[cooldown] = math.max(0, S.cooldowns[cooldown] - S.cooldown_rates[cooldown])
  S.attributes.raw_hp = math.min(S.attributes.raw_hp + S.hp_regen, S.max_hp)
  S.attributes.raw_mp = math.min(S.attributes.raw_mp + S.mp_regen, S.max_mp)
  S.attributes.hp = math.min(S.hp + S.hp_regen, S.max_hp)
  S.attributes.mp = math.min(S.mp + S.mp_regen, S.max_mp)

-- Attack calculations
M.attack_calculate = (A) ->
  A\revert()

M.attack_apply = (A, rng, dS) ->
  pow = A.physical_power - dS.physical_resist
  pow = math.max(pow + rng\random(10, 31), 0)
  dmg = math.max(A.physical_dmg - dS.defence, 0)
  dmg *= pow * 0.05

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

-- Calculate derived stats from bonuses and their raw_* counterparts
M.stat_calculate = (S) ->
  S\revert()
  M.attack_calculate(S.attack)

M.player_stat_step = (S) ->
   if S.is_resting
     -- Handling healing due to rest
     S.attributes.hp_regen += S.attributes.raw_hp_regen * 7
     S.attributes.mp_regen += S.attributes.raw_mp_regen * 7
   M.stat_step(S)
-- Calculate derived stats from bonuses and their raw_* counterparts
M.player_stat_calculate = (S) ->
  M.stat_calculate(S)

return M
