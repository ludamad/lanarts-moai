-- Intentionally a dumb listing of attributes -- all the information that deals with these attributes
-- could not potentially be collected here. 
-- Therefore, simplicity is preferred and it reads as a simple list of attributes that are simple one number each.

ffi = require "ffi"

M = nilprotect {} -- Submodule

-- Basic stats:
-- Basic statistics about a combat entity (eg player or monster). These statistics are collected in an object
-- with a 'base_' prefix indicating the statistics before modifiers.
-- These statistics are all represented by 32-bit floating point numbers (requires LuaJIT!).

M.CORE_ATTRIBUTES = {
  "hp"
  "max_hp"
  "hp_regen"
  "mp"
  "max_mp"
  "mp_regen"
  "ep"
  "max_ep"
  "ep_regen"
  "defence" -- Direct subtraction from physical_dmg
  "physical_resist" -- Used with physical_power to determine attack ratio

  "move_speed"

  "fire_resist"
  "water_resist"
  "earth_resist"
  "air_resist"
  "death_resist"
  "life_resist"
  "poison_resist"
}

M.COOLDOWN_ATTRIBUTES = {
  "rest_cooldown"
  "action_cooldown"
  "move_cooldown"
  "hurt_cooldown"
  "action_wait"
}

-- Used to calculate core attributes, and attack attributes.
M.SKILL_ATTRIBUTES = {
  "melee"
  "magic"
  "piercing_weapons"
  "slashing_weapons"
  "blunt_weapons"
  "ranged_weapons"

  "force_spells"
  "fire_mastery"
  "water_mastery"
  "earth_mastery"
  "air_mastery"
  "death_mastery"
  "life_mastery"
  "poison_mastery"

  "armour"
  "defending"
  "curses"
  "enchantments"
}

-- Basic stats for an attack
-- Eg a 'magic fire missile' has magic AND fire AND physical.
M.ATTACK_ATTRIBUTES = {
  -- Weapon type plays a large part:
  "physical_dmg"
  "physical_power"
  "delay"
  "multiplier"
  "cooldown"
  "range"

  -- Various sources, eg enchantments, weapon type:
  "magic_dmg"
  "fire_dmg"
  "water_dmg"
  "earth_dmg"
  "air_dmg"
  "death_dmg"
  "life_dmg"
  -- Damage over time:
  "poison_dmg"

  "magic_power"
  "fire_power"
  "water_power"
  "earth_power"
  "air_power"
  "death_power"
  "life_power"
  "poison_power"

  -- Enchantment plays a large part:
  "enchantment_bonus"
  "slaying_bonus"
}

-------------------------------------------------------------------------------
-- Pretty-name lookup, suitable for showing the user.
-------------------------------------------------------------------------------
to_camelcase = (str) ->
    parts = str\split("_")
    for i,part in ipairs(parts) do
        parts[i] = part\lower()\gsub("^%l", string.upper)
    return (" ")\join(parts)

M.CORE_ATTRIBUTE_NAMES   = {attr, to_camelcase(attr) for attr in *M.CORE_ATTRIBUTES}
M.SKILL_ATTRIBUTE_NAMES  = {attr, to_camelcase(attr) for attr in *M.SKILL_ATTRIBUTES}
M.ATTACK_ATTRIBUTE_NAMES = {attr, to_camelcase(attr) for attr in *M.ATTACK_ATTRIBUTES}
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- new_attr_vector_type:
-- Local utility. Define an FFI type with a list of attributes as floating-point members of the struct.
--
-- Argument table: 
--   stat_list: The attributes to include.
--   struct_name: Name must be unique, but otherwise not important for our purposes.
--   methods: The methods on the defined type. Must not change after this call!
--   raw_copies: Whether to duplicate all members with the raw_* prefix, and add a 'revert' method to copy current values to raw values.
-------------------------------------------------------------------------------
new_attr_vector_type = (args) -> 
  {:struct_name, :stat_list, :methods, :raw_copies} = args
  methods.init or= () => --Do nothing

  -- Resolve attribute list, depending on whether we keep raw_* members
  local attr_list
  if raw_copies
    -- Define the attribute list
    attr_list = ["float raw_#{s}; float #{s};" for s in *stat_list]
    -- Define the body of the revert method, copying raw_* to each non-raw field.
    -- NB: Must be valid Lua code (NOT Moonscript!)
    revert_body = ["self.#{s} = self.raw_#{s}" for s in *stat_list]
    revert_definer = loadstring "
      return function (self)
        #{table.concat revert_body, '\n'}
      end
    "
    -- Define a special-tuned 'revert' method
    methods.revert or= revert_definer()
  else
    attr_list = ["float #{s};" for s in *stat_list]

  -- Define the structure using LuaJIT FFI
  ffi.cdef "
    typedef struct {
      #{table.concat attr_list, '\n'}
    } #{struct_name};
  "
  meta = ffi.metatype struct_name, {__index: methods}
  return {
    create: (...) ->
      obj = meta()
      obj\init(...)
      return obj
  }
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Define the actual structures.
-------------------------------------------------------------------------------
M.Skills = new_attr_vector_type {
  struct_name: "__skills_t"
  stat_list: M.SKILL_ATTRIBUTES
  methods: {
    copy: (o) => ffi.copy(@, o, ffi.sizeof @)
  }
  raw_copies: false
}

M.Cooldowns = new_attr_vector_type {
  struct_name: "__cooldown_t"
  stat_list: M.COOLDOWN_ATTRIBUTES
  methods: {
    copy: (o) => ffi.copy(@, o, ffi.sizeof @)
  }
  raw_copies: false
}

M.CoreAttributes = new_attr_vector_type {
  struct_name: "__core_attributes_t"
  stat_list: M.CORE_ATTRIBUTES
  methods: {
    copy: (o) => ffi.copy(@, o, ffi.sizeof @)
  }
  raw_copies: true
}

M.AttackAttributes = new_attr_vector_type {
  struct_name: "__attack_t"
  stat_list: M.ATTACK_ATTRIBUTES
  methods: {
    copy: (o) => ffi.copy(@, o, ffi.sizeof @)
  }
  raw_copies: true
}
-------------------------------------------------------------------------------

return M
