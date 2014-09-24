-- Every combat entity has a StatContext object
-- Note this file should not be used directly, except internally. Use 'require "statsystem"', instead.

attributes = require "@attributes"
items = require "@items"
calculate = require "@calculate"

M = nilprotect {}

make_attribute_getters = (attrs) -> 
  return {k, (() => @attributes[k]) for k in *attrs}
make_attribute_setters = (attrs) ->
  return {k, ((v) => @attributes[k] = v) for k in *attrs}

M.AttackContext = newtype {
  -- Fallbacks for get and set:
  get: make_attribute_getters(attributes.ATTACK_ATTRIBUTES)
  set: make_attribute_setters(attributes.ATTACK_ATTRIBUTES)

  init: (source) =>
    @source = source
    @attributes = attributes.AttackAttributes.create()
  revert: () =>
    @attributes\revert()
  copy: (o) => -- Generally, we do not copy the source, as this can be a back-pointer
    @attributes\copy(o.attributes)
  -- Note; 'attacker' and 'deferender' are StatContext objects, as defined in statcontext.moon
  apply: calculate.attack_apply
}

M.StatContext = newtype {
  -- Fallbacks for get and set:
  get: make_attribute_getters(attributes.CORE_ATTRIBUTES)
  set: make_attribute_setters(attributes.CORE_ATTRIBUTES)

  init: (owner, name) =>
    -- The game object owning this context
    @obj = owner
    @name = name
    @attributes = attributes.CoreAttributes.create()
    -- For monsters, this never changes.
    -- For players, this represents their currently wielded weapon's stats.
    -- Ranged attacks carry their own 'attack' object, in their projectile.
    @attack = M.AttackContext.create(@)
    -- For monsters, these items represent anything picked up by the monster,
    -- or anything they spawned with. Monsters can use items, but often this
    -- is simply their 'loot'.
    @inventory = items.ItemSet.create()
    @gold = 0
    @cooldowns = attributes.Cooldowns.create()
    @cooldown_rates = attributes.Cooldowns.create()
    for cooldown in *attributes.COOLDOWN_ATTRIBUTES
      @cooldown_rates[cooldown] = 1.00

   copy: (S) =>
     @attributes\copy(S.attributes)
     @attack\copy(S.attack)
     @inventory\copy(S.inventory)
     @gold = S.gold
     @cooldowns\copy(S.cooldowns)
     @cooldown_rates\copy(S.cooldown_rates)

   clone: (new_owner) =>
     S = M.StatContext.create(new_owner, @name)
     S\copy(@)
     return S

   revert: () => 
     @attributes\revert()
     @attack\revert()
   step: calculate.stat_step
   -- Calculate derived stats from bonuses and their raw_* counterparts
   calculate: calculate.stat_calculate
}

M.PlayerStatContext = newtype {
  parent: M.StatContext
  init: (owner, name, race) =>
    M.StatContext.init(@, owner, name)
    @race = race
    @level = 1
    @xp = 0
    @is_resting = false
    -- The 'Skills' structure is used as an arbitrary structure for holding one float per skill.
    @skill_levels = attributes.Skills.create()
    @skill_points = attributes.Skills.create()
    @skill_cost_multipliers = attributes.Skills.create()
    for skill in *attributes.SKILL_ATTRIBUTES
      @skill_cost_multipliers[skill] = 1.00
    @skill_weights = attributes.Skills.create()

   clone: () => error("Not Yet Implemented")
   step: calculate.player_stat_step
   calculate: calculate.player_stat_calculate
   get_equipped: (item_type) =>
     for i=1,@inventory\size()
        item = @inventory\get(i)
        if item.is_equipment and item.item_type == item_type
            return item
     return nil
}

return M
