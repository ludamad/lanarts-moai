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

M.attack_apply = (A, dS) ->
  Aa, dSa = A.attributes, dS.attributes
  A.source.cooldowns.action_cooldown = Aa.delay
  dSa.raw_hp = math.max(0, dSa.raw_hp - Aa.physical_dmg)
  dS.cooldowns.hurt_cooldown = constants.HURT_COOLDOWN

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
   -- Default to not resting:
   S.is_resting = false
   -- Handling resting due to staying-put
   if S.cooldowns.rest_cooldown == 0
     needs_hp = (S.hp < S.max_hp and S.hp_regen > 0)
     needs_mp = (S.mp < S.max_mp and S.mp_regen > 0)
     if needs_hp or needs_mp
       -- Rest if we can, and if its useful
       S.is_resting = true

   if S.is_resting
     -- Handling healing due to rest
     S.attributes.hp_regen += S.attributes.raw_hp_regen * 7
     S.attributes.mp_regen += S.attributes.raw_mp_regen * 7
   M.stat_step(S)
-- Calculate derived stats from bonuses and their raw_* counterparts
M.player_stat_calculate = (S) ->
  M.stat_calculate(S)

return M
