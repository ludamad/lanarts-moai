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
    total = 0
    for mon, n in pairs monsters
        total += n
    for i=1,total
        num = M.rng\random(1, total+1)
        for mon, n in pairs monsters
            if n >= num
                assert map_place_object M, (px, py) ->
                    map_object_types.NPC.create M, {
                        x: px*32+16
                        y: py*32+16
                        type: mon
                        solid: true
                    }, area, selector
                break
            num -= n
    require("@map_logic").assertSync "step_objects (frame #{M.gamestate.step_number})", M

return {:map_place_object, :map_place_monsters}
