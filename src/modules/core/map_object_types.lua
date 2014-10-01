local BoolGrid = require('BoolGrid')
local user_io = require('user_io')
local res = require("resources")
local data = require("core.data")
local statsystem = require("statsystem")
local util_draw, TileMap
do
  local _obj_0 = require("core")
  util_draw, TileMap = _obj_0.util_draw, _obj_0.TileMap
end
local Display
do
  local _obj_0 = require("ui")
  Display = _obj_0.Display
end
local FieldOfView, FloodFillPaths, util_geometry
do
  local _obj_0 = require("core")
  FieldOfView, FloodFillPaths, util_geometry = _obj_0.FieldOfView, _obj_0.FloodFillPaths, _obj_0.util_geometry
end
local DAMAGE_TEXT_PRIORITY = 98
local ATTACK_ANIMATION_PRIORITY = 98
local PROJECTILE_PRIORITY = 99
local BASE_PRIORITY = 101
local FEATURE_PRIORITY = 102
local Y_PRIORITY_INCR = -(2 ^ -16)
local Animation, Player
local ObjectBase = newtype({
  alpha = 1.0,
  sprite = false,
  priority = 0,
  init = function(self, M, args)
    self.x, self.y, self.radius = args.x, args.y, args.radius or 15
    self.target_radius, self.solid = (args.target_radius or args.radius or 16), args.solid or false
    if args.priority then
      self.priority = args.priority
    end
    self.map = M
    self.id = M.objects:add(self)
    self.id_col = 0
    self.frame = 0
    self.remove_queued = false
  end,
  queue_remove = function(self, M)
    if not self.remove_queued then
      append(M.removal_list, self)
      self.remove_queued = false
    end
  end,
  remove = function(self, M)
    return M.objects:remove(self)
  end,
  pre_draw = function(self, V) end,
  draw = function(self, V, r, g, b)
    if r == nil then
      r = 1
    end
    if g == nil then
      g = 1
    end
    if b == nil then
      b = 1
    end
    if self.sprite then
      return self.sprite:draw(self.x, self.y, self.frame, self.alpha, 0.5, 0.5, r, g, b)
    end
  end,
  sync = function(self, M)
    return nil
  end
})
local Feature = newtype({
  parent = ObjectBase,
  priority = FEATURE_PRIORITY,
  init = function(self, M, args)
    if args.solid then
      local tx, ty = math.floor(args.x / 32), math.floor(args.y / 32)
      M.tilemap:square_apply({
        tx,
        ty
      }, {
        add = TileMap.FLAG_SOLID
      })
      args.solid = false
    end
    ObjectBase.init(self, M, args)
    self.true_sprite = data.get_sprite(args.sprite)
    self.sprite = false
    self.frame = M.rng:random(1, self.true_sprite:n_frames() + 1)
  end,
  was_seen = function(self)
    return (self.sprite ~= false)
  end,
  mark_seen = function(self)
    self.sprite = self.true_sprite
  end
})
local draw_statbar
draw_statbar = function(x, y, w, h, ratio)
  MOAIGfxDevice.setPenColor(1, 0, 0)
  MOAIDraw.fillRect(x, y, x + w, y + h)
  MOAIGfxDevice.setPenColor(0, 1, 0)
  return MOAIDraw.fillRect(x, y, x + w * ratio, y + h)
end
local CombatObjectBase = newtype({
  parent = ObjectBase,
  init = function(self, M, stats, args)
    args.solid = true
    ObjectBase.init(self, M, args)
    self.stats = stats
    self.id_col = M.collision_world:add_instance(self.x, self.y, self.radius, self.target_radius, self.solid)
    M.col_id_to_object[self.id_col] = self
    self.id_rvo = M.rvo_world:add_instance(self.x, self.y, self.radius, self.stats.move_speed)
    append(M.combat_object_list, self)
    self:set_priority()
    return self:_reset_delayed_action()
  end,
  _reset_delayed_action = function(self)
    self.delayed_action = false
    self.delayed_action_target_id = false
    self.delayed_action_target_x = false
    self.delayed_action_target_y = false
    self.delayed_action_initial_delay = false
  end,
  remove = function(self, M)
    ObjectBase.remove(self, M)
    M.collision_world:remove_instance(self.id_col)
    M.rvo_world:remove_instance(self.id_rvo)
    M.col_id_to_object[self.id_col] = nil
    return table.remove_occurrences(M.combat_object_list, self)
  end,
  sync_col = function(self, M)
    return M.collision_world:update_instance(self.id_col, self.x, self.y, self.radius, self.target_radius, self.solid)
  end,
  sync = function(self, M)
    ObjectBase.sync(self, M)
    return self:sync_col(M)
  end,
  set_priority = function(self)
    self.priority = BASE_PRIORITY + Y_PRIORITY_INCR * self.y
  end,
  set_rvo = function(self, M, dx, dy, max_speed, radius)
    if max_speed == nil then
      max_speed = self.stats.move_speed
    end
    if radius == nil then
      radius = self.radius
    end
    return M.rvo_world:update_instance(self.id_rvo, self.x, self.y, radius, max_speed, dx, dy)
  end,
  get_rvo_velocity = function(self, M)
    return M.rvo_world:get_velocity(self.id_rvo)
  end,
  get_rvo_heading = function(self, M)
    return M.rvo_world:get_preferred_velocity(self.id_rvo)
  end,
  check_delayed_action = function(self, M)
    if self.stats.cooldowns.action_wait <= 0 and self.delayed_action then
      local _exp_0 = self.delayed_action
      if 'weapon_attack' == _exp_0 then
        local obj = M.objects:get(self.delayed_action_target_id)
        if obj then
          local dmg = self.stats.attack:apply(M.rng, obj.stats)
          local tx, ty = obj.x, obj.y
          local dx, dy = obj.x - self.x, obj.y - self.y
          local mag = math.sqrt(dx * dx + dy * dy)
          dx, dy = dx / mag, dy / mag
          local hit_spr = self.stats.attack.on_hit_sprite
          if hit_spr then
            Animation.create(M, {
              sprite = data.get_sprite(hit_spr),
              x = obj.x,
              y = obj.y,
              vx = 0,
              vy = 0,
              priority = ATTACK_ANIMATION_PRIORITY,
              fade_rate = 0.1
            })
          end
          local is_player = (getmetatable(self) == Player)
          local text_color = ((function()
            if is_player then
              return Display.COL_LIGHT_GRAY
            else
              return Display.COL_PALE_RED
            end
          end)())
          Animation.create(M, {
            drawn_text = tostring(dmg),
            x = tx,
            y = ty,
            vx = dx,
            vy = dy,
            color = text_color,
            priority = DAMAGE_TEXT_PRIORITY,
            fade_rate = 0.04
          })
        end
        return self:_reset_delayed_action()
      else
        return error("Unexpected branch!")
      end
    end
  end,
  queue_weapon_attack = function(self, id)
    assert(self.stats.cooldowns.action_cooldown <= 0)
    self.stats.cooldowns.action_cooldown = self.stats.attack.cooldown
    self.stats.cooldowns.action_wait = math.min(self.stats.attack.delay, statsystem.MAX_MELEE_QUEUE)
    self.stats.cooldowns.move_cooldown = math.max(self.stats.attack.delay, self.stats.cooldowns.move_cooldown)
    self.delayed_action = 'weapon_attack'
    self.delayed_action_target_id = id
    self.delayed_action_initial_delay = self.stats.attack.delay
  end,
  on_death = function(self, M, attacker)
    return self:queue_remove(M)
  end,
  _spike_color_mod = function(self, v, max)
    if v == 0 then
      return 1
    elseif v < max / 2 then
      return v / max * 0.35 + 0.3
    else
      return (max - v) * 0.07 + 0.3
    end
  end,
  _get_rgb = function(self)
    if self.delayed_action then
      local v1 = self:_spike_color_mod(self.stats.cooldowns.action_wait, self.delayed_action_initial_delay)
      local v2 = v1 * 0.25 + 0.75
      return v2, v2, v1
    elseif self.stats.cooldowns.move_cooldown > 0 then
      return 0.5, 0.5, 0.5
    else
      local cmod = self:_spike_color_mod(self.stats.cooldowns.hurt_cooldown, statsystem.HURT_COOLDOWN)
      return 1, cmod, cmod
    end
  end,
  WAIT_SPRITE = data.get_sprite("stat-wait"),
  draw = function(self, V)
    ObjectBase.draw(self, V, self:_get_rgb())
    if self.stats.cooldowns.move_cooldown > 0 then
      self.WAIT_SPRITE:draw(self.x, self.y, self.frame, 1, 0.5, 0.5)
    end
    local healthbar_offsety = 20
    if self.target_radius > 16 then
      healthbar_offsety = self.target_radius + 8
    end
    if self.stats.hp < self.stats.max_hp then
      local x, y = self.x - 10, self.y - healthbar_offsety
      local w, h = 20, 5
      return draw_statbar(x, y, w, h, self.stats.hp / self.stats.max_hp)
    end
  end
})
local SHARED_LINE_OF_SIGHT = 3
local PlayerVision = newtype({
  init = function(self, M, id_player, line_of_sight)
    self.line_of_sight = line_of_sight
    self.id_player = id_player
    self.fieldofview = FieldOfView.create(self.line_of_sight)
    self.shared_fieldofview = FieldOfView.create(SHARED_LINE_OF_SIGHT)
    self.prev_seen_bounds = {
      0,
      0,
      0,
      0
    }
    self.current_seen_bounds = {
      0,
      0,
      0,
      0
    }
    self.shared_prev_seen_bounds = {
      0,
      0,
      0,
      0
    }
    self.shared_current_seen_bounds = {
      0,
      0,
      0,
      0
    }
  end,
  get_fov_and_bounds = function(self, M)
    if M.gamestate.local_player_id == self.id_player then
      return self.fieldofview, self.current_seen_bounds
    end
    return self.shared_fieldofview, self.shared_current_seen_bounds
  end,
  update = function(self, M, x, y)
    self.fieldofview:calculate(M.tilemap, x, y)
    self.shared_fieldofview:calculate(M.tilemap, x, y)
    self.fieldofview:update_seen_map(M.player_seen_map(self.id_player))
    local _list_0 = M.gamestate.players
    for _index_0 = 1, #_list_0 do
      local other_player = _list_0[_index_0]
      if other_player.id_player ~= self.id_player then
        self.shared_fieldofview:update_seen_map(M.player_seen_map(other_player.id_player))
      end
    end
    self.prev_seen_bounds = self.current_seen_bounds
    self.current_seen_bounds = self.fieldofview:tiles_covered()
    self.shared_prev_seen_bounds = self.shared_current_seen_bounds
    self.shared_current_seen_bounds = self.shared_fieldofview:tiles_covered()
  end
})
local PlayerActionState = newtype({
  init = function(self)
    self.last_dir_x = 0
    self.last_dir_y = 0
    self.constraint_dir_x = 0
    self.constraint_dir_y = 0
  end
})
Player = newtype({
  parent = CombatObjectBase,
  init = function(self, M, args)
    logI("Player::init")
    local stats = statsystem.PlayerStatContext.create(self, args.name, args.race)
    args.race.stat_race_adjustments(stats)
    args.class.stat_class_adjustments(args.class_args, stats)
    stats:calculate(false)
    CombatObjectBase.init(self, M, stats, args)
    self.name = args.name
    self.action_state = PlayerActionState.create()
    logI("Player::init stats created")
    self.player_path_radius = 300
    self.id_player = args.id_player
    self.vision = PlayerVision.create(M, self.id_player, M.line_of_sight)
    self.paths_to_player = FloodFillPaths.create()
    self.paths_to_player:set_map(M.tilemap)
    append(M.player_list, self)
    return logI("Player::init complete")
  end,
  remove = function(self, M)
    CombatObjectBase.remove(self, M)
    return table.remove_occurrences(M.player_list, self)
  end,
  SMALL_SPRITE_ORDER = {
    "__LEGS",
    statsystem.BODY_ARMOUR,
    statsystem.WEAPON,
    statsystem.RING,
    statsystem.GLOVES,
    statsystem.BOOTS,
    statsystem.BRACERS,
    statsystem.AMULET,
    statsystem.HEADGEAR,
    statsystem.AMMO
  },
  REST_SPRITE = data.get_sprite("stat-rest"),
  draw = function(self, V)
    local r, g, b = self:_get_rgb()
    local sp = data.get_sprite(self.stats.race.avatar_sprite)
    sp:draw(self.x, self.y, self.frame, 1, 0.5, 0.5, r, g, b)
    local _list_0 = self.SMALL_SPRITE_ORDER
    for _index_0 = 1, #_list_0 do
      local equip_type = _list_0[_index_0]
      local avatar_sprite
      if equip_type == "__LEGS" then
        avatar_sprite = "sl-gray-pants"
      else
        local equip = self.stats:get_equipped(equip_type)
        avatar_sprite = equip and equip.avatar_sprite
      end
      if avatar_sprite then
        sp = data.get_sprite(avatar_sprite)
        sp:draw(self.x, self.y, self.frame, 1, 0.5, 0.5, r, g, b)
      end
    end
    if self.stats.is_resting then
      self.REST_SPRITE:draw(self.x, self.y, self.frame, 1, 0.5, 0.5)
    end
    return CombatObjectBase.draw(self, V)
  end,
  pre_draw = do_nothing,
  nearest_enemy = function(self, M)
    local min_obj, min_dist = nil, math.huge
    local _list_0 = M.npc_list
    for _index_0 = 1, #_list_0 do
      local obj = _list_0[_index_0]
      local dist = util_geometry.object_distance(self, obj)
      if dist < min_dist then
        min_obj = obj
        min_dist = dist
      end
    end
    return min_obj, min_dist
  end,
  on_death = function(self, M)
    logI("Player " .. tostring(self.id_player) .. " has died.")
    M.gamestate.local_death = true
  end,
  can_see = function(self, obj)
    return self.vision.fieldofview:circle_visible(obj.x, obj.y, obj.radius)
  end,
  sync = function(self, M)
    CombatObjectBase.sync(self, M)
    self.vision:update(M, self.x / M.tile_width, self.y / M.tile_height)
    return self.paths_to_player:update(self.x, self.y, self.player_path_radius)
  end
})
local NPC_RANDOM_WALK, NPC_CHASING = 0, 1
local NPC = newtype({
  parent = CombatObjectBase,
  init = function(self, M, args)
    self.npc_type = statsystem.MONSTER_DB[args.type]
    args.radius = self.npc_type.radius
    CombatObjectBase.init(self, M, self.npc_type.stats:clone(self), args)
    append(M.npc_list, self)
    self.sprite = data.get_sprite(args.type)
    self.ai_action = NPC_RANDOM_WALK
    self.ai_target = false
  end,
  nearest_enemy = function(self, M)
    local min_obj, min_dist = nil, math.huge
    local _list_0 = M.player_list
    for _index_0 = 1, #_list_0 do
      local obj = _list_0[_index_0]
      local dist = util_geometry.object_distance(self, obj)
      if dist < min_dist then
        min_obj = obj
        min_dist = dist
      end
    end
    return min_obj, min_dist
  end,
  on_death = function(self, M)
    CombatObjectBase.on_death(self, M)
    local n_players = #M.player_list
    local _list_0 = M.player_list
    for _index_0 = 1, #_list_0 do
      local obj = _list_0[_index_0]
      local xp_gain = statsystem.challenge_rating_to_xp_gain(obj.stats.level, self.npc_type.level)
      xp_gain = math.round(xp_gain / n_players)
      statsystem.gain_xp(obj.stats, xp_gain)
    end
    return Animation.create(M, {
      sprite = self.sprite,
      x = self.x,
      y = self.y,
      vx = 0,
      vy = 0,
      priority = self.priority
    })
  end,
  RANDOM_WALK_SPRITE = data.get_sprite("stat-random"),
  draw = function(self, V)
    ObjectBase.draw(self, V)
    if self.ai_action == NPC_RANDOM_WALK then
      return self.RANDOM_WALK_SPRITE:draw(self.x, self.y, self.frame, 1, 0.5, 0.5)
    end
  end,
  remove = function(self, M)
    CombatObjectBase.remove(self, M)
    return table.remove_occurrences(M.npc_list, self)
  end
})
Animation = newtype({
  parent = ObjectBase,
  init = function(self, M, args)
    ObjectBase.init(self, M, args)
    assert(args.priority, "Animation requires specifying priority! Alternative is chaos.")
    self.vx = args.vx or 0
    self.vy = args.vy or 0
    self.alpha = args.alpha or 1.0
    self.fade_rate = args.fade_rate or 0.05
    self.sprite = args.sprite or false
    self.drawn_text = args.drawn_text or false
    self.color = table.clone(args.color or Display.COL_WHITE)
    return append(M.animation_list, self)
  end,
  font = res.get_bmfont('Liberation-Mono-20.fnt'),
  draw = function(self, V)
    ObjectBase.draw(self, V)
    if self.drawn_text then
      self.color[4] = self.alpha / 2 + .5
      return Display.drawTextCenter(self.font, self.drawn_text, self.x, self.y, self.color)
    end
  end,
  remove = function(self, M)
    ObjectBase.remove(self, M)
    return table.remove_occurrences(M.animation_list, self)
  end,
  step = function(self, M)
    self.x = self.x + self.vx
    self.y = self.y + self.vy
    self.alpha = math.max(self.alpha - self.fade_rate, 0)
    if self.alpha == 0 then
      return self:queue_remove(M)
    end
  end
})
local Projectile = newtype({
  parent = ObjectBase,
  priority = PROJECTILE_PRIORITY,
  init = function(self, M, args)
    ObjectBase.init(self, M, args)
    self.sprite = args.sprite
    self.vx = args.vx
    self.vy = args.vy
    self.action = args.action
    return append(M.projectile_list, self)
  end,
  step = function(self, M)
    self.x = self.x + self.vx
    self.y = self.y + self.vy
    local _list_0 = M.object_query(self)
    for _index_0 = 1, #_list_0 do
      local col_id = _list_0[_index_0]
      local obj = M.col_id_to_object[col_id]
      if getmetatable(obj) == NPC then
        Animation.create(M, {
          sprite = self.sprite,
          x = self.x,
          y = self.y,
          vx = self.vx,
          vy = self.vy,
          priority = self.priority
        })
        self:queue_remove(M)
        return 
      end
    end
    if M.tile_check(self) then
      return self:queue_remove(M)
    end
  end,
  remove = function(self, M)
    ObjectBase.remove(self, M)
    return table.remove_occurrences(M.projectile_list, self)
  end
})
return {
  ObjectBase = ObjectBase,
  Feature = Feature,
  CombatObjectBase = CombatObjectBase,
  Player = Player,
  NPC = NPC,
  Projectile = Projectile,
  NPC_RANDOM_WALK = NPC_RANDOM_WALK,
  NPC_CHASING = NPC_CHASING
}
