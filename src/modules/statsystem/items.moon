-- Provides methods for defining object kinds, and creating item objects.

name_gen = require "@name_gen"

M = nilprotect {} -- Submodule

-------------------------------------------------------------------------------
-- Helpful constants:
-------------------------------------------------------------------------------

M.UNCURSED, M.CURSED, M.BLESSED = 1,2,3
M.CURSE_DESC = {"Uncursed", "Cursed", "Blessed"}

M.SCROLL, M.POTION = 1,2
-- Double as item types, and equipment-slot types:
M.WEAPON, M.AMMO, M.BODY_ARMOUR, M.HELMET, M.GLOVES, M.BOOTS = 2,3,4,5,6,7
-- Rings are special: Can wear two of them (TODO: I want octopodes with eight rings!)
M.RING = 8

M.EQUIP_SLOTS = {M.WEAPON, M.AMMO, M.BODY_ARMOUR, M.HELMET, M.GLOVES, M.BOOTS, M.RING}

-------------------------------------------------------------------------------
-- Item classes:
-------------------------------------------------------------------------------

_ItemBase = newtype {
  init: (@kind_id) =>
    --cursedness: Whether the item is cursed, plain, or blessed.
    @cursedness = M.UNCURSED
    --identified_cursedness: Whether the item BUC status has been identified.
    @identified_cursedness = false
    @on_change()
  get: {kind: () => M.ITEM_DB[@kind_id]}

-- Item type traits:
  is_consumable: false
  is_equipment: false
  is_stackable: false
  is_kind_id_necessary: false

  -- Overridden by classes that are stackable or need kind-identification
  _get_base_name: () => @kind.name 
  _get_name: () =>
    name = @_get_base_name()
    if @identified_cursedness
      name = M.CURSE_DESC[@cursedness]  .. name
    return name

  -- React to updates on the item.
  -- Mainly, cache the name so we don't constantly create it on each lookup.
  on_change: () =>
    @name = @_get_name()
}

_EXTRACT_IN_BRACKETS = (s) => s\match("%((.*)%)")

-- ITEM TYPE TRAITS --
-- Modify an item type definition to be stackable:
_make_stackable = (type) ->
  type.is_stackable = true
  -- Cache parent methods
  pget_base_name = type._get_base_name
  pinit = type.init
  type.init = () =>
    pinit(@)
    @amount = 1

  -- Pluralizable names have a component in parentheses (eg "Large Box(es)")
  -- Remove those if amount == 1.
  type._get_name = () =>
    name = pget_name(@)
       -- Replace eg "(es)" with "es"
      name\gsub("(%(.*%))", _EXTRACT_IN_BRACKETS)   if @amount > 1
      name = amount .. ' ' .. name
    else
       -- Replace eg "(es)" with ""
      name\gsub("(%(.*%))", "")
    return name

-- Modify an item type definition to need kind-identification:
_make_kind_need_id = (type) ->
  type.is_kind_id_necessary = true
  -- Cache parent methods
  pinit = type.init
  type.init = () =>
    pinit(@)
    --identified_kind: Whether the item kind has been identified.
    @identified_kind = false
  type._get_base_name = () =>
    if @identified_kind then 
      return @kind.name 
    else 
      return @kind.unidentified_name

-- ITEM TYPES --
-- Note: Kind requires identification for consumables
M.Consumable = _make_stackable _make_kind_need_id newtype {
  parent: _ItemBase
  is_consumable: true
}

-- Note: Kind is always 'self-evident' for Equipment -- unless it is a ring
-- Equipment is not stackable -- unless it is ammo
M.Equipment = newtype {
  parent: _ItemBase
  init: (kind_id) =>
    _ItemBase.init(@, kind_id)
    @equipped = false
    @identified_enchantment = false
  is_equipment: true
}

M.Ammo = _make_stackable newtype {parent: M.Equipment}

-- Note: Kind requires identification for rings
M.Ring = _make_kind_need_id newtype {
  parent: M.Equipment
}

-------------------------------------------------------------------------------
-- Item creation functions:
-------------------------------------------------------------------------------

-- Create an item, uncursed, unidentified and without any enchantments.
M.make_item = (id) ->
  kind = M.ITEM_DB[id]
  local item
  if kind <= M.POTION
    item = M.Consumable.create(id)
  else
    item = M.Equipment.create(id)
  return item

-------------------------------------------------------------------------------
-- Item definition functions:
-------------------------------------------------------------------------------

-- We should only refer to items by ID generally, but to be on the safe side
-- give a serialization hint:
ITEM_META = {__constant: true}

-- Item definition helpers
_item_define = (t) ->
  next_id = #M.ITEM_DB + 1
  t.id = next_id
  M.ITEM_DB[next_id] = t
  assert M.ITEM_DB[t.name] == nil, "#{t.item_type} #{t.name} already exists!"
  setmetatable t, ITEM_META

_equipment_define = (t) ->
  _item_define(t)

_consumable_define = (t) ->
  _item_define(t)

-- Consumable definition functions
M.potion_define = (t) ->
  t.item_type = M.POTION
  -- TODO: Properly load this from save-file
  t.unidentified_name = name_gen.generate_unidentified_potion_name()
  _item_define(t)

M.scroll_define = (t) ->
  t.item_type = M.SCROLL
  -- TODO: Properly load this from save-file
  t.unidentified_name = name_gen.generate_unidentified_scroll_name()
  _item_define(t)

-- Equipment definition functions
M.ammo_define = (t) ->
  t.item_type = M.AMMO
  _equipment_define(t)

M.body_armour_define = (t) ->
  t.item_type = M.BODY_ARMOUR
  _equipment_define(t)

M.helmet_define = (t) ->
  t.item_type = M.HELMET
  _equipment_define(t)

M.gloves_define = (t) ->
  t.item_type = M.GLOVES
  _equipment_define(t)

M.boots_define = (t) ->
  t.item_type = M.BOOTS
  _equipment_define(t)

M.ring_define = (t) ->
  t.item_type = M.RING
  -- TODO: Properly load this from save-file
  t.unidentified_name = name_gen.generate_unidentified_ring_name()
  _equipment_define(t)

M.weapon_define = (t) ->
  t.item_type = M.WEAPON
  _equipment_define(t)

return M
