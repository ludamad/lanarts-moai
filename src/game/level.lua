local BoolGrid, mtwist = require("BoolGrid", require("mtwist"))
local FloodFillPaths, GameInstSet, GameTiles, GameView, util, TileMap, RVOWorld
do
  local _obj_0 = require("core")
  FloodFillPaths, GameInstSet, GameTiles, GameView, util, TileMap, RVOWorld = _obj_0.FloodFillPaths, _obj_0.GameInstSet, _obj_0.GameTiles, _obj_0.GameView, _obj_0.util, _obj_0.TileMap, _obj_0.RVOWorld
end
local create_thread
do
  local _obj_0 = require('game.util')
  create_thread = _obj_0.create_thread
end
local ui_ingame_scroll, ui_ingame_select
do
  local _obj_0 = require("game.ui")
  ui_ingame_scroll, ui_ingame_select = _obj_0.ui_ingame_scroll, _obj_0.ui_ingame_select
end
local modules, camera
do
  local _obj_0 = require('game')
  modules, camera = _obj_0.modules, _obj_0.camera
end
local user_io = require('user_io')
local res = require('resources')
local gamestate = require('core.gamestate')
local setup_camera
setup_camera = function(V)
  local w, h = V.level.tilemap_width, V.level.tilemap_height
  local tw, th = V.level.tile_width, V.level.tile_height
  local cx, cy = w * tw / 2, h * th / 2
  assert(not V.camera and not V.viewport, "Double call to setup_view!")
  do
    local _with_0 = MOAICamera2D.new()
    _with_0:setLoc(cx, cy)
    V.camera = _with_0
  end
  do
    local _with_0 = MOAIViewport.new()
    _with_0:setSize(V.cameraw, V.camerah)
    _with_0:setScale(V.cameraw, -V.camerah)
    V.viewport = _with_0
  end
end
local setup_tile_layers
setup_tile_layers = function(V)
  local w, h = V.level.tilemap_width, V.level.tilemap_height
  local tw, th = V.level.tile_width, V.level.tile_height
  local props, grids = { }, { }
  local _grid
  _grid = function(tileid)
    local tilelist = modules.get_tilelist(tileid)
    local file = tilelist.texfile
    if not grids[file] then
      do
        local _with_0 = MOAIGrid.new()
        _with_0:setSize(w, h, tw, th)
        grids[file] = _with_0
      end
      local tex = res.get_texture(file)
      local tex_w, tex_h = tex:getSize()
      append(props, (function()
        do
          local _with_0 = MOAIProp2D.new()
          _with_0:setDeck((function()
            do
              local _with_1 = MOAITileDeck2D.new()
              _with_1:setTexture(res.get_texture(file))
              _with_1:setSize(tex_w / tw, tex_h / th)
              return _with_1
            end
          end)())
          _with_0:setGrid(grids[file])
          return _with_0
        end
      end)())
    end
    return grids[file]
  end
  local _set_xy
  _set_xy = function(x, y, tileid)
    if tileid == 0 then
      return 
    end
    local grid = _grid(tileid)
    local tilelist = modules.get_tilelist(tileid)
    local n = _RNG:random(1, #tilelist.tiles + 1)
    local tile = tilelist.tiles[n]
    return grid:setTile(x, y, tile.grid_id)
  end
  for y = 1, h do
    for x = 1, w do
      _set_xy(x, y, V.level.tilemap:get({
        x,
        y
      }).content)
    end
  end
  local layer = V.add_layer()
  pretty("Props", props)
  for _index_0 = 1, #props do
    local p = props[_index_0]
    layer:insertProp(p)
  end
end
local setup_fov_layer
setup_fov_layer = function(V)
  local w, h = V.level.tilemap_width, V.level.tilemap_height
  local tw, th = V.level.tile_width, V.level.tile_height
  local tex = res.get_texture("fogofwar.png")
  local tex_w, tex_h = tex:getSize()
  V.fov_layer = V.add_layer()
  do
    local _with_0 = MOAIGrid.new()
    _with_0:setSize(w, h, tw, th)
    V.fov_grid = _with_0
  end
  V.fov_layer:insertProp((function()
    do
      local _with_0 = MOAIProp2D.new()
      _with_0:setDeck((function()
        do
          local _with_1 = MOAITileDeck2D.new()
          _with_1:setTexture(tex)
          _with_1:setSize(tex_w / tw, tex_h / th)
          return _with_1
        end
      end)())
      _with_0:setGrid(V.fov_grid)
      return _with_0
    end
  end)())
  for y = 1, h do
    for x = 1, w do
      V.fov_grid:setTile(x, y, 2)
    end
  end
end
local setup_overlay_layers
setup_overlay_layers = function(V)
  V.object_layer = V.add_layer()
  setup_fov_layer(V)
  V.ui_layer = V.add_layer()
  V.add_ui_prop = function(prop)
    return V.ui_layer:insertProp(prop)
  end
  V.remove_ui_prop = function(prop)
    return V.ui_layer:removeProp(prop)
  end
  V.add_object_prop = function(prop)
    return V.object_layer:insertProp(prop)
  end
  V.remove_object_prop = function(prop)
    return V.object_layer:removeProp(prop)
  end
end
local setup_level_state_helpers
setup_level_state_helpers = function(L)
  local w, h
  do
    local _obj_0 = L.tilemap.size
    w, h = _obj_0[1], _obj_0[2]
  end
  local tw, th = L.tile_width, L.tile_height
  L.tile_xy_to_real = function(x, y)
    return (x - .5) * tw, (y - .5) * th
  end
  L.real_xy_to_tile = function(rx, ry)
    local x = math.floor(rx / tw + .5)
    local y = math.floor(ry / th + .5)
    if (x >= 1 and x <= w) and (y >= 1 and y <= h) then
      return x, y
    end
    return nil, nil
  end
  L.real_xy_snap = function(rx, ry)
    rx = math.floor(rx / tw) * tw
    ry = math.floor(ry / th) * th
    return rx, ry
  end
  L.tile_check = function(obj, dx, dy, dradius)
    if dx == nil then
      dx = 0
    end
    if dy == nil then
      dy = 0
    end
    if dradius == nil then
      dradius = 0
    end
    return GameTiles.radius_test(L.tilemap, obj.x + dx, obj.y + dy, obj.radius + dradius)
  end
  L.object_check = function(obj, dx, dy, dradius)
    if dx == nil then
      dx = 0
    end
    if dy == nil then
      dy = 0
    end
    if dradius == nil then
      dradius = 0
    end
    return L.collision_world:object_radius_test(obj.id_col, obj.x + dx, obj.y + dy, obj.radius + dradius)
  end
  L.solid_check = function(obj, dx, dy, dradius)
    if dx == nil then
      dx = 0
    end
    if dy == nil then
      dy = 0
    end
    if dradius == nil then
      dradius = 0
    end
    return L.tile_check(obj, dx, dy, dradius) or L.object_check(obj, dx, dy, dradius)
  end
end
local create_level_state
create_level_state = function(rng, tilemap)
  local L = {
    rng = rng,
    tilemap = tilemap
  }
  L.tile_width, L.tile_height = 32, 32
  do
    local _obj_0 = L.tilemap.size
    L.tilemap_width, L.tilemap_height = _obj_0[1], _obj_0[2]
  end
  L.pix_width, L.pix_height = (L.tile_width * L.tilemap_width), (L.tile_height * L.tilemap_height)
  L.instances = L.tilemap.instances.instances
  setup_level_state_helpers(L)
  L.objects = { }
  L.collision_world = GameInstSet.create(L.pix_width, L.pix_height)
  L.rvo_world = RVOWorld.create()
  local _list_0 = L.instances
  for _index_0 = 1, #_list_0 do
    local inst = _list_0[_index_0]
    inst:register(L)
  end
  L.step = function()
    local _list_1 = L.instances
    for _index_0 = 1, #_list_1 do
      local inst = _list_1[_index_0]
      inst:step(L)
    end
    local _list_2 = L.instances
    for _index_0 = 1, #_list_2 do
      local inst = _list_2[_index_0]
      inst:post_step(L)
    end
    L.collision_world:step()
    return L.rvo_world:step()
  end
  return L
end
local create_level_view
create_level_view = function(level, cameraw, camerah)
  local V = {
    level = level,
    cameraw = cameraw,
    camerah = camerah
  }
  V.layers = { }
  V.ui_components = { }
  V.add_layer = function()
    local layer
    do
      local _with_0 = MOAILayer2D.new()
      _with_0:setCamera(V.camera)
      _with_0:setViewport(V.viewport)
      layer = _with_0
    end
    append(V.layers, layer)
    return layer
  end
  V.start = function()
    local _list_0 = V.layers
    for _index_0 = 1, #_list_0 do
      local layer = _list_0[_index_0]
      MOAISim.pushRenderPass(layer)
    end
    local _list_1 = V.level.instances
    for _index_0 = 1, #_list_1 do
      local inst = _list_1[_index_0]
      inst:register_prop(V)
    end
  end
  V.pre_draw = function()
    local _list_0 = V.level.instances
    for _index_0 = 1, #_list_0 do
      local inst = _list_0[_index_0]
      inst:pre_draw(V)
      if inst.is_focus then
        local seen, prev, curr, fov
        do
          local _obj_0 = inst.vision
          seen, prev, curr, fov = _obj_0.seen_tile_map, _obj_0.prev_seen_bounds, _obj_0.current_seen_bounds, _obj_0.fieldofview
        end
        local x1, y1, x2, y2 = camera.tile_region_covered(V)
        for y = y1, y2 do
          for x = x1, x2 do
            local tile
            if seen:get(x, y) then
              tile = 1
            else
              tile = 2
            end
            V.fov_grid:setTile(x, y, tile)
          end
        end
        x1, y1, x2, y2 = curr[1], curr[2], curr[3], curr[4]
        for y = y1, y2 - 1 do
          for x = x1, x2 - 1 do
            if fov:within_fov(x, y) then
              V.fov_grid:setTile(x, y, 0)
            end
          end
        end
      end
    end
  end
  V.stop = function()
    local _list_0 = V.layers
    for _index_0 = 1, #_list_0 do
      local layer = _list_0[_index_0]
      MOAISim.removeRenderPass(layer)
    end
  end
  V.clear = function()
    local _list_0 = V.layers
    for _index_0 = 1, #_list_0 do
      local layer = _list_0[_index_0]
      layer:clear()
    end
  end
  setup_camera(V)
  setup_tile_layers(V)
  setup_overlay_layers(V)
  append(V.ui_components, ui_ingame_select(V))
  append(V.ui_components, ui_ingame_scroll(V))
  return V
end
local main_thread
main_thread = function(G)
  return create_thread(function()
    while true do
      coroutine.yield()
      local before = MOAISim.getDeviceTime()
      G.step()
      G.pre_draw()
      if not _SETTINGS.headless then
        local _list_0 = G.ui_components
        for _index_0 = 1, #_list_0 do
          local component = _list_0[_index_0]
          component()
        end
      end
    end
  end)
end
local create_game_state
create_game_state = function(level, cameraw, camerah)
  local V = create_level_view(level, cameraw, camerah)
  local G = {
    level_view = V,
    level = level
  }
  G.start = function()
    V.start()
    local thread = main_thread(G)
    thread.start()
    return thread
  end
  G.stop = function()
    V.stop()
    local _list_0 = G.threads
    for _index_0 = 1, #_list_0 do
      local thread = _list_0[_index_0]
      thread.stop()
    end
  end
  G.step = function()
    return G.level.step()
  end
  G.handle_io = function()
    if user_io.key_down("K_Q") then
      gamestate.push_state(G.level)
    end
    if user_io.key_down("K_E") then
      gamestate.pop_state(G.level)
    end
    return G.level:handle_io(G)
  end
  G.pre_draw = function()
    return G.level_view.pre_draw()
  end
  return G
end
return {
  create_game_state = create_game_state,
  create_level_state = create_level_state,
  create_level_view = create_level_view
}
