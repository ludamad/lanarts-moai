local Map
do
  local _obj_0 = require("levels")
  Map = _obj_0.Map
end
local TextEditBox
do
  local _obj_0 = require("interface")
  TextEditBox = _obj_0.TextEditBox
end
local ErrorReporting
do
  local _obj_0 = require("system")
  ErrorReporting = _obj_0.ErrorReporting
end
local BuildingObject
do
  local _obj_0 = require("objects")
  BuildingObject = _obj_0.BuildingObject
end
local get_texture, get_json
do
  local _obj_0 = require("resources")
  get_texture, get_json = _obj_0.get_texture, _obj_0.get_json
end
local user_io = require("user_io")
local charcodes = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 .,/;!?()&/-'
local font
do
  local _with_0 = MOAIFont.new()
  _with_0:loadFromTTF('resources/LiberationMono-Regular.ttf', charcodes, 120, 72)
  font = _with_0
end
local setup_game
setup_game = function()
  local w, h = 800, 600
  if MOAIEnvironment.osBrand == "Android" or MOAIEnvironment.osBrand == "iOS" then
    w, h = 320, 480
  end
  MOAISim.openWindow("Lanarts", w, h)
  local camera = MOAICamera2D.new()
  local cx, cy = 128, 128
  camera:setLoc(cx, cy)
  local map
  do
    local _with_0 = Map.create()
    _with_0:add_obj(BuildingObject.create(32, 32))
    _with_0:register((function()
      do
        local _with_1 = MOAIViewport.new()
        _with_1:setSize(w, h)
        _with_1:setScale(w, h)
        return _with_1
      end
    end)(), camera)
    map = _with_0
  end
  do
    local _with_0 = MOAIThread.new()
    _with_0:run(function()
      local mX, mY = user_io.mouse_xy()
      local dragging = false
      while true do
        coroutine.yield()
        if user_io.mouse_right_pressed() then
          dragging = true
        end
        if user_io.mouse_right_released() then
          dragging = false
        end
        if dragging and user_io.mouse_right_down() then
          local newMX, newMY = user_io.mouse_xy()
          local prevX, prevY = camera:getLoc()
          camera:setLoc(prevX + (mX - newMX), prevY - (mY - newMY))
        end
        mX, mY = user_io.mouse_xy()
        map:step()
      end
    end)
    return _with_0
  end
end
local TiledMap = typedef([[    tile_width, tile_height : int 
    layers, tile_sets : list
]])
local TiledLayer = typedef([[    name : string
    width, height : int 
    x, y : int
    data : list
]])
local TiledTileSet = typedef([[    name : string
    path : string
    first_id : int
    image_width, image_height : int
    tile_width, tile_height : int 
]])
local parse_tiled_json
parse_tiled_json = function(path)
  local json = get_json(path)
  local tile_sets = { }
  local _list_0 = json.tilesets
  for _index_0 = 1, #_list_0 do
    local tset = _list_0[_index_0]
    append(tile_sets, TiledTileSet.create(tset.name, tset.image, tset.firstgid, tset.imagewidth, tset.imageheight, tset.tilewidth, tset.tileheight))
  end
  local layers = { }
  local _list_1 = json.layers
  for _index_0 = 1, #_list_1 do
    local lay = _list_1[_index_0]
    append(layers, TiledLayer.create(lay.name, lay.width, lay.height, lay.x, lay.y, lay.data))
  end
  return TiledMap.create(json.tilewidth, json.tileheight, layers, tile_sets)
end
local load_tiled_json
load_tiled_json = function(path, vieww, viewh)
  local map = parse_tiled_json(path)
  local C = { }
  do
    local _with_0 = MOAICamera2D.new()
    _with_0:setLoc(map.tile_width / 2 * 64, map.tile_height / 2 * 32)
    C.camera = _with_0
  end
  do
    local _with_0 = MOAIViewport.new()
    _with_0:setSize(vieww, viewh)
    _with_0:setScale(vieww, viewh)
    C.viewport = _with_0
  end
  local gidmap = { }
  local _list_0 = map.tile_sets
  for _index_0 = 1, #_list_0 do
    local tset = _list_0[_index_0]
    local texture = get_texture(tset.path)
    local w, h = tset.image_width, tset.image_height
    local tilew, tileh = tset.tile_width, tset.tile_height
    local tw, th = (w / tilew), (h / tileh)
    local gid = tset.first_id
    for y = 1, th do
      for x = 1, tw do
        local x1, x2 = (x - 1) * tilew, (x) * tilew
        local y1, y2 = (y - 1) * tileh, (y) * tileh
        local quad
        do
          local _with_0 = MOAIGfxQuad2D.new()
          _with_0:setTexture(texture)
          _with_0:setQuad(x1, y1, x2, y1, x2, y2, x1, y2)
          _with_0:setRect(-tilew / 2, -tileh / 2, tilew / 2, tileh / 2)
          quad = _with_0
        end
        assert(gidmap[gid] == nil, "Tile GID overlap, logic error!")
        gidmap[gid] = quad
        gid = gid + 1
      end
    end
  end
  C.layers = { }
  local _list_1 = map.layers
  for _index_0 = 1, #_list_1 do
    local lay = _list_1[_index_0]
    local w, h = lay.width, lay.height
    local dx, dy = lay.x, lay.y
    local layer
    do
      local _with_0 = MOAILayer2D.new()
      _with_0:setCamera(C.camera)
      _with_0:setViewport(C.viewport)
      _with_0:setSortMode(MOAILayer.SORT_ISO)
      layer = _with_0
    end
    for y = 1, h do
      for x = 1, w do
        local i = (y - 1) * w + x
        local gid = lay.data[i]
        if gid > 0 then
          local px, py = (x - .5) * 64, (y - .5) * 32
          layer:insertProp((function()
            do
              local _with_0 = MOAIProp2D.new()
              _with_0:setDeck(gidmap[gid])
              _with_0:setLoc(px, py)
              return _with_0
            end
          end)())
          print("Going", px, py)
        end
      end
    end
    append(C.layers, layer)
  end
  C.setup = function()
    local _list_2 = C.layers
    for _index_0 = 1, #_list_2 do
      local layer = _list_2[_index_0]
      MOAISim.pushRenderPass(layer)
    end
    local top_layer = C.layers[#C.layers]
    local text_box
    do
      local _with_0 = MOAITextBox.new()
      _with_0:setFont(font)
      _with_0:setTextSize(24)
      _with_0:setString("")
      _with_0:spool()
      _with_0:setAlignment(MOAITextBox.CENTER_JUSTIFY, MOAITextBox.CENTER_JUSTIFY)
      text_box = _with_0
    end
    return top_layer:insertProp(text_box)
  end
  MOAIThread.new():run(function()
    local mX, mY = user_io.mouse_xy()
    local dragging = false
    while true do
      coroutine.yield()
      if user_io.mouse_right_pressed() then
        dragging = true
      end
      if user_io.mouse_right_released() then
        dragging = false
      end
      if dragging and user_io.mouse_right_down() then
        local newMX, newMY = user_io.mouse_xy()
        local prevX, prevY = C.camera:getLoc()
        C.camera:setLoc(prevX + (mX - newMX), prevY - (mY - newMY))
      end
      mX, mY = user_io.mouse_xy()
      text_box:setString(mX .. ", " .. mY)
    end
  end)
  C.teardown = function()
    local _list_2 = C.layers
    for _index_0 = 1, #_list_2 do
      local layer = _list_2[_index_0]
      MOAISim.removeRenderPass(layer)
    end
  end
  return C
end
local setup_game2
setup_game2 = function()
  local w, h = 800, 600
  if MOAIEnvironment.osBrand == "Android" or MOAIEnvironment.osBrand == "iOS" then
    w, h = 320, 480
  end
  MOAISim.openWindow("Citymode", w, h)
  local camera
  do
    local _with_0 = MOAICamera2D.new()
    _with_0:setNearPlane(10000)
    _with_0:setFarPlane(-10000)
    _with_0:setRot(45, 0)
    camera = _with_0
  end
  local layer
  do
    local _with_0 = MOAILayer2D.new()
    _with_0:setCamera(camera)
    _with_0:setViewport((function()
      do
        local _with_1 = MOAIViewport.new()
        _with_1:setSize(w, h)
        _with_1:setScale(w, h)
        return _with_1
      end
    end)())
    layer = _with_0
  end
  MOAISim.pushRenderPass(layer)
  local tileDeck
  do
    local _with_0 = MOAITileDeck2D.new()
    _with_0:setTexture(get_texture("diamond-tiles.png"))
    _with_0:setSize(4, 4)
    _with_0:setUVQuad(0, 0.5, 0.5, 0, 0, -0.5, -0.5, 0)
    tileDeck = _with_0
  end
  local map = parse_tiled_json("iso-test.json")
  return layer:insertProp((function()
    do
      local _with_0 = MOAIProp2D.new()
      _with_0:setDeck(tileDeck)
      _with_0:setPiv(256, 256)
      _with_0:setScl(1, -1)
      _with_0:setGrid((function()
        do
          local _with_1 = MOAIGrid.new()
          _with_1:setSize(8, 8, 64, 64)
          _with_1:setRow(1, 0x01, 0x02, 0x03, 0x04, 0x03, 0x03, 0x03, 0x03)
          _with_1:setRow(2, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03)
          _with_1:setRow(3, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03)
          _with_1:setRow(4, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03)
          _with_1:setRow(5, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03)
          _with_1:setRow(6, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03)
          _with_1:setRow(7, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03)
          _with_1:setRow(8, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03)
          return _with_1
        end
      end)())
      return _with_0
    end
  end)())
end
local setup_game3
setup_game3 = function()
  local w, h = 800, 600
  if MOAIEnvironment.osBrand == "Android" or MOAIEnvironment.osBrand == "iOS" then
    w, h = 320, 480
  end
  MOAISim.openWindow("Citymode", w, h)
  local C = load_tiled_json("iso-test.json", w, h)
  C.setup()
  if user_io.key_pressed("K_ESCAPE") then
    return C.teardown()
  end
end
return setup_game3()
