import get_tiles_bg from require "resources"

Map = newtype()

Map.init = () =>
    @layers = {}
    @obj_layer = MOAILayer2D.new()
    @objs = {}

Map.step = () =>
    for obj in *@objs
        obj\step()

Map.draw = () =>
    for obj in *@objs do obj\draw()

Map.add_obj = (obj) =>
    append(@objs, obj)
    obj\register(self.obj_layer)

Map.add_layer = (layer) =>
    append(@layers, layer)

Map.push_render_pass = (vp) =>
    for layer in values(self.layers)
        MOAISim.pushRenderPass(layer)
        layer\setViewport(vp)
    MOAISim.pushRenderPass(self.obj_layer)
    @obj_layer\setViewport(vp)

data2grid = (w, h, data) ->
    ret = table.zeros(w, h)
    for y=1,h
        for x=1,w
            ret[h - y + 1][x] = data[(y-1)*w + x]
    return ret

load_layer = (map, L) ->
    layer = MOAILayer2D.new()
    w,h = L.width, L.height
--    tiles = resources.get_tiles_bg("terrain.png", data2grid(w, h, L.data), 32, 32)
--    tiles:setLoc(L.x, L.y)
--    layer:insertProp(tiles)
    map\add_layer(layer)

load_map = (ppath) ->
    data = require("maps." .. ppath)
    map = Map.create()
    for L in values(data.layers)
        load_layer(map, L)
    return map

return { :load_map, create: Map.create }
