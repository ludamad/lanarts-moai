-- Every combat entity has a StatContext object
-- Note this file should not be used directly, except internally. Use 'require "statsystem"', instead.

attributes = require "@attributes"
items = require "@items"
constants = require "@constants"

M = nilprotect {}

M.StatContext = newtype {
  init: (name) =>
    @name = name
    @attributes = attributes.CoreAttributes.create()
    -- For monsters, this never changes.
    -- For players, this represents their currently wielded weapon's stats.
    -- Ranged attacks carry their own 'attack' object, in their projectile.
    @attack = attributes.Attack.create()
    -- For monsters, these items represent anything picked up by the monster,
    -- or anything they spawned with. Monsters can use items, but often too this
    -- is simply their 'loot'.
    @inventory = items.ItemSet.create()
    @gold = 0
    @cooldowns = attributes.Cooldowns.create()
    @cooldown_rates = attributes.Cooldowns.create()
    for cooldown in *attributes.COOLDOWN_ATTRIBUTES
      @cooldown_rates[cooldown] = 1.00
   get: {
     hp: () => @attributes.hp
     max_hp: () => @attributes.max_hp
     hp_regen: () => @attributes.hp_regen
     mp: () => @attributes.mp
     max_mp: () => @attributes.max_mp
     mp_regen: () => @attributes.mp_regen
   }
}

M.PlayerStatContext = newtype {
  parent: M.StatContext
  init: (name, race) =>
    M.StatContext.init(@, name)
    @race = race
    @level = 1
    @xp = 0
    -- The 'Skills' structure is used as an arbitrary structure for holding one float per skill.
    @skill_levels = attributes.Skills.create()
    @skill_points = attributes.Skills.create()
    @skill_cost_multipliers = attributes.Skills.create()
    for skill in *attributes.SKILL_ATTRIBUTES
      @skill_cost_multipliers[skill] = 1.00
    @skill_weights = attributes.Skills.create()
}

return M