----
-- Map object/feature placement

import map_object_types, TileMap from require 'core'

DEFAULT_SELECTOR = {matches_none: {TileMap.FLAG_SOLID, TileMap.FLAG_HAS_OBJECT}}
map_place_object = (M, spawner, area = nil, selector = DEFAULT_SELECTOR) ->
    sqr = TileMap.find_random_square {
        map: M.tilemap
        rng: M.rng
        :selector
        :area,
        operator: add: TileMap.FLAG_HAS_OBJECT
    }
    if not sqr
        return false
    {px, py} = sqr

    spawner(px, py)
    return true

map_place_monsters = (M, monsters, area = nil, selector = DEFAULT_SELECTOR) ->
    for mon, n in pairs monsters
        for i=1,n
            assert map_place_object M, (px, py) ->
                map_object_types.NPC.create M, {
                    x: px*32+16
                    y: py*32+16
                    type: mon
                    solid: true
                }, area, selector
    require("@map_logic").assertSync "step_objects (frame #{M.gamestate.frame})", M

return {:map_place_object, :map_place_monsters}
