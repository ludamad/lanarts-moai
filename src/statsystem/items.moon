-- Provides methods for defining object kinds, and creating item objects.

name_gen = require "@name_gen"
constants = require "@constants"
data = require "core.data"

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
M.WEAPON, M.AMMO, M.BODY_ARMOUR, M.HEADGEAR, M.GLOVES, M.BOOTS = 3,4,5,6,7,8
-- Rings are special: Can wear two of them (TODO: I want octopodes with eight rings!)
M.RING, M.BRACERS, M.AMULET = 9, 10, 11

M.EQUIP_SLOTS = {M.WEAPON, M.AMMO, M.BODY_ARMOUR, M.HEADGEAR, M.GLOVES, M.BOOTS, M.RING, M.BRACERS, M.AMULET}

-------------------------------------------------------------------------------
-- Item classes:
-------------------------------------------------------------------------------

_ItemBase = newtype {
    init: (@id_kind) =>
        --cursedness: Whether the item is cursed, plain, or blessed.
        @cursedness = M.UNCURSED
        --identified_cursedness: Whether the item BUC status has been identified.
        @identified_cursedness = false
        @id_sprite = data.get_sprite(@kind.name).id
        @on_change()
    get: {
        kind: () => M.ITEM_DB[@id_kind]
        item_type: () => @kind.item_type
    }

    -- Item type traits:
    is_consumable: false
    is_equipment: false
    is_stackable: false
    is_id_kind_necessary: false
    -- For stackable items only.
    should_occupy_same_slot: (o) =>
        if not @is_stackable
            return false
        if @id_kind != o.id_kind then return false
        -- Don't merge items if we don't know their curse status:
        if not @identified_cursedness or not o.identified_cursedness 
            return false
        return @cursedness == o.cursedness

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

-- Class modification function
-- Modify an item type definition to be stackable:
_make_stackable = (type) ->
    type.is_stackable = true
    -- Cache parent methods
    pget_base_name = type._get_base_name
    pget_name = type._get_name
    pinit = type.init
    type.init = (id_kind) =>
        @amount = 1
        pinit(@, id_kind)

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

-- Class modification function
-- Modify an item type definition to need kind-identification:
_make_kind_need_id = (type) ->
    type.is_id_kind_necessary = true
    -- Cache parent methods
    pinit = type.init
    type.init = (id_kind) =>
        --identified_kind: Whether the item kind has been identified.
        @identified_kind = false
        pinit(@, id_kind)
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
    init: (id_kind) =>
        @identified_enchantment = false
        _ItemBase.init(@, id_kind)
        @enchantment = 0
        @id_avatar = data.get_sprite(@kind.avatar_sprite).id
        @is_equipped = false
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
    if kind.item_type <= M.POTION
        item = M.Consumable.create(id)
    else
        item = M.Equipment.create(id)
    return item

-------------------------------------------------------------------------------
-- ItemSet (Mainly == player/monster inventory, but also item piles on the floor) definition:
-------------------------------------------------------------------------------

-- Item slots are Item instances

M.ItemSet = newtype {
    init: () =>
        @slots = {}
    add: (item) => 
        if @_try_merge(item)
            return true
        if #@slots >= constants.MAX_ITEMS
            return false
        append @slots, item
        return true

    get_equipped: (type) =>
        for slot in *@slots
            if slot.item_type == type and slot.is_equipped
                return slot
        return nil
    copy: (o) =>
        @slots = table.deep_clone(o.slots)
    _try_merge: (newitem) =>
        for slot in *@slots
            if newitem\should_occupy_same_slot(slot)
                item.amount += newitem.amount
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

M.headgear_define = (t) ->
    t.item_type = M.HEADGEAR
    _equipment_define(t)

M.gloves_define = (t) ->
    t.item_type = M.GLOVES
    _equipment_define(t)

M.boots_define = (t) ->
    t.item_type = M.BOOTS
    _equipment_define(t)

M.bracers_define = (t) ->
    t.item_type = M.BRACERS
    _equipment_define(t)

M.ring_define = (t) ->
    t.item_type = M.RING
    -- TODO: Properly load this from save-file
    t.unidentified_name = name_gen.generate_unidentified_ring_name()
    _equipment_define(t)

-- Weapon helpers
M.make_weapon_attack = (t) ->
    import AttackContext from require "@statcontext"

    A = AttackContext.create(false)
    A.attack_sprite = t.name
    -- Default unarmed attack
    A.raw_physical_dmg = t.damage
    A.raw_physical_power = t.power or 0
    A.raw_delay = constants.BASE_ACTION_DELAY * (t.delay or 1)
    A.raw_multiplier = t.multiplier or t.cooldown or 1
    A.raw_cooldown = constants.BASE_ACTION_COOLDOWN * (t.cooldown or 1)
    A.raw_range = (t.range or 0)
    A.uses_projectile = (t.uses_projectile or false)
    if A.uses_projectile
        A.projectile_radius = (t.projectile_radius or 13)
        A.projectile_speed = (t.projectile_speed)
    A\revert()
    return A

M.weapon_define = (t) ->
    t.item_type = M.WEAPON
    t.attack = M.make_weapon_attack(t)
    _equipment_define(t)

return M
