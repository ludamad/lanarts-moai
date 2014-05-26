import get_tiles_bg from require "resources"

Map = newtype()

Map.init = () =>
    @layers = {}
    @obj_layer = MOAILayer2D.new()
    @objs = {}

Map.step = () =>
    for obj in *@objs
        obj\step()

Map.remove_obj = (obj) =>
    -- Remove & deregister a game object
    obj\deregister(@, @obj_layer)
    table.remove_occurrences(@objs, obj)

Map.add_obj = (obj) =>
    -- Add & register a game object
    append(@objs, obj)
    obj\register(@, @obj_layer)

Map.add_layer = (layer) =>
    append(@layers, layer)

Map.deregister = () =>
    -- Unregister the misc. layers:
    for layer in values(@layers)
        MOAISim.removeRenderPass(layer)
    -- Unregister the object layer:
    MOAISim.removeRenderPass(@obj_layer)
    -- Remove callback prop that calls draw & step:
    @obj_layer\removeProp @callback_prop

Map.register = (vp) =>
    -- Register the misc. layers
    for layer in values(@layers)
        MOAISim.pushRenderPass(layer)
        layer\setViewport(vp)

    -- Register the object layer
    MOAISim.pushRenderPass(@obj_layer)
    @obj_layer\setViewport(vp)

    -- Register callback prop that calls draw & step:
    @callback_prop = with MOAIProp2D.new()
        \setDeck with MOAIScriptDeck.new()
            \setDrawCallback () ->
                @\draw()

    @obj_layer\insertProp @callback_prop

data2grid = (w, h, data) ->
    ret = table.zeros(w, h)
    for y=1,h
        for x=1,w
            ret[h - y + 1][x] = data[(y-1)*w + x]
    return ret

load_layer = (map, L) ->
    layer = MOAILayer2D.new()
    w,h = L.width, L.height
    tiles = resources.get_tiles_bg("terrain.png", data2grid(w, h, L.data), 32, 32)
    tiles:setLoc(L.x, L.y)
    layer:insertProp(tiles)
    map\add_layer(layer)

load_map = (ppath) ->
    data = require("maps." .. ppath)
    map = Map.create()
    for L in values(data.layers)
        load_layer(map, L)
    return map

return { :load_map, create: Map.create }
