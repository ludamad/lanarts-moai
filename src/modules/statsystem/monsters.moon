import NPCStatContext from require "@statcontext"
import BASE_ACTION_DELAY, BASE_ACTION_COOLDOWN from require "@constants"

M = nilprotect {}

-- Stores monsters, both by name and by unique integer ID:

M.MONSTER_DB = nilprotect {}

-- A type of monster -- eg "Giant Rat"
-- A specific Giant Rat would be a monster instance.
M.MonsterType = newtype {
  init: (data) =>
    @name = data.name
    @id = data.id
    @monster_kind = data.monster_kind
    @description = data.description
    @appear_message = data.appear_message
    @defeat_message = data.defeat_message
    @radius = data.radius
    @level = data.level
    @min_chase_dist = data.chase_distances[1]
    @max_chase_dist = data.chase_distances[2]

    -- We pass 'false' to indicate the StatContext has no proper GameObject associated with it.
    @stats = NPCStatContext.create(false, @name)  
    attr = @stats.attributes

    -- HP: Health points
    attr.raw_hp = data.hp
    attr.raw_max_hp = attr.raw_hp
    attr.raw_hp_regen = data.hp_regen
    -- MP: Mana Points
    attr.raw_mp = data.mp or 0
    attr.raw_max_mp = attr.raw_mp
    attr.raw_mp_regen = data.mp_regen or 0
    -- EP: Energy points
    attr.raw_ep = data.ep or 0
    attr.raw_max_ep = attr.raw_ep
    attr.raw_ep_regen = data.ep_regen or 0
    -- Move speed, default same as player
    attr.raw_move_speed = data.move_speed or 6

    atk = @stats.attack.attributes
    
    atk.raw_physical_dmg = data.damage
    atk.raw_physical_power = data.power

    atk.raw_cooldown = BASE_ACTION_COOLDOWN * data.cooldown
    atk.raw_delay = BASE_ACTION_DELAY * data.delay    
    atk.raw_range = data.range or 4
    
    -- Copy everything over from the raw_* components.
    @stats\revert()
    assert(atk.range >= 4, "Monster range should not be less than 4 pixels!")
    assert(@stats.attributes.hp >= 0, "Monster hp shouldn't be 0!")
}

-------------------------------------------------------------------------------
-- Monster definition functions:
-------------------------------------------------------------------------------

-- We should only refer to monsters by ID generally, but to be on the safe side
-- give a serialization hint:
MONSTER_META = {__constant: true}

-- Item definition helpers
M.monster_define = (t) ->
  next_id = #M.MONSTER_DB + 1
  t.id = next_id
  t = M.MonsterType.create(t)
  M.MONSTER_DB[next_id] = t
  assert rawget(M.MONSTER_DB, t.name) == nil, "Monster #{t.name} already exists!"
  M.MONSTER_DB[t.name] = t
  setmetatable t, MONSTER_META

return M
