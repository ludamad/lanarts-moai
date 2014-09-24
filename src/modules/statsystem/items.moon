-- Provides methods for defining object kinds, and creating item objects.

name_gen = require "@name_gen"
constants = require "@constants"

M = nilprotect {} -- Submodule

-- Stores items, both by name and by unique integer ID:

M.ITEM_DB = nilprotect {}

-------------------------------------------------------------------------------
-- Helpful constants:
-------------------------------------------------------------------------------

M.UNCURSED, M.CURSED, M.BLESSED = 1,2,3
M.CURSE_DESC = {"Uncursed", "Cursed", "Blessed"}

M.SCROLL, M.POTION = 1,2
-- Double as item types, and equipment-slot types:
M.WEAPON, M.AMMO, M.BODY_ARMOUR, M.HEADGEAR, M.GLOVES, M.BOOTS = 2,3,4,5,6,7
-- Rings are special: Can wear two of them (TODO: I want octopodes with eight rings!)
M.RING, M.BRACERS, M.AMULET = 8, 9, 10

M.EQUIP_SLOTS = {M.WEAPON, M.AMMO, M.BODY_ARMOUR, M.HEADGEAR, M.GLOVES, M.BOOTS, M.RING, M.BRACERS, M.AMULET}

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
  -- For stackable items only.
  -- Note that distinct items may stack! They might differ by cursedness.
  should_occupy_same_slot: (o) =>
    if not @is_stackable
      return false
    if @kind_id != o.kind_id then return false
    if @identified_cursedness != o.identified_cursedness 
      return false
    if @identified_cursedness and o.identified_cursedness
      return (if @cursedness == o.cursedness then "identical" else false)
    return true -- Both do not have curse ID'd

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
    if @amount > 1
       -- Replace eg "(es)" with "es"
      name\gsub("(%(.*%))", _EXTRACT_IN_BRACKETS)
      name = amount .. ' ' .. name
    else
       -- Replace eg "(es)" with ""
      name\gsub("(%(.*%))", "")
    return name
  return type

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
  return type

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
-- ItemSet (Mainly == player/monster inventory, but also item piles on the floor) definition:
-------------------------------------------------------------------------------

-- Item slots are mostly items as defined above -- with one complication
-- distinct items sometimes get merged into the same slot when the player cannot distinguish them.
-- It would be possible to make these items non-distinct, and instead differentiate them randomly on identification
-- however, this route was felt to be more flexible.

M.ItemSet = newtype {
  init: () =>
    @item_slots = {}
  add: (item) => 
    @_try_merge(item)
    if #@item_slots >= constants.MAX_ITEMS
      return false
    append @item_slots, item
    return true

  get_amount: (i) => 
    slot = @item_slots[i]
    amount = slot.amount or 0 -- Note: Will be 0 here if multiple _distinct_ items occupy the slot
    if amount > 0 then return amount
    -- Otherwise, sum over parts:
    for item in *slot
      amount += item.amount
    return amount

  get_item: (i) => 
    slot = @item_slots[i]
    if getmetatable(slot) -- If we have a metatable, we are a single item
      return slot
    return slot[1]

  size: () => #@item_slots

  copy: (o) =>
    @item_slots = table.deep_clone(o.item_slots)
  _try_merge: (newitem) =>
    for i=1,#@item_slots
      slot = @item_slots[i]
      item = @get_item(i)
      should_occupy = newitem\should_occupy_same_slot(item)
      if should_occupy == "identical" and slot == item
        item.amount += newitem.amount
        return true
      elseif should_occupy
        if slot == item -- Only a single item currently
          slot = {slot} -- Make a list of items instead, so we can add the new one
          @item_slots[i] = slot
        append slot, newitem
        return true
    return false
}

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
  assert rawget(M.ITEM_DB, t.name) == nil, "#{t.item_type} #{t.name} already exists!"
  M.ITEM_DB[t.name] = t
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
