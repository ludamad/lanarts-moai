BoolGrid = require "BoolGrid"
mtwist = require "mtwist"
modules = require "game.modules"
T = modules.get_tilelist_id

import print_map, make_tunnel_oper, make_rectangle_criteria, make_rectangle_oper, place_instances
    from require "@map_util"

import FloodFillPaths, GameInstSet, GameTiles, GameView, util, TileMap
    from require "core"

generate_test_model = (rng) ->
    padding = {10, 10}
    size = {120, 80}
    padded_size = {size[1]+padding[1]*2, size[2]+padding[2]*2}

    map = TileMap.map_create { 
        size: padded_size
        content: T('dungeon_wall')
        flags: TileMap.FLAG_SOLID
        instances: {}
    }

    oper = TileMap.random_placement_operator {
        size_range: {6,9}
        rng: rng
        amount_of_placements_range: {20, 20}
        create_subgroup: true
        child_operator: (map, subgroup, bounds) ->
            --Purposefully convoluted for test purposes
            queryfn = () ->
                query = make_rectangle_criteria()
                return query(map, subgroup, bounds)
            oper = make_rectangle_oper(queryfn)
            if oper(map, subgroup, bounds)
                --place_instances(rng, map, bounds)
                return true
            return false
    }
 
    -- Apply the binary space partitioning (bsp)
    oper map, TileMap.ROOT_GROUP, bbox_create(padding, size)

    tunnel_oper = make_tunnel_oper(rng)

    tunnel_oper map, TileMap.ROOT_GROUP, bbox_create({0,0}, padded_size)

    --print_map(map, map.instances) -- Uncomment to print
    return map

-- Simple model for exemplary purposes
generate_empty_model = (rng) ->
    padding = {10, 10}
    size = {120, 80}
    padded_size = {size[1]+padding[1]*2, size[2]+padding[2]*2}
    map = TileMap.map_create { 
        size: padded_size
        content: T('dungeon_wall')
        flags: TileMap.FLAG_SOLID
        instances: {}
    }
 
    TileMap.rectangle_apply {
        map: map
        area: bbox_create(padding, size)
        fill_operator: add: TileMap.FLAG_SEETHROUGH, remove: TileMap.FLAG_SOLID, content: T('grey_floor')
    }

    --print_map(map, map.instances) -- Uncomment to print
    return map



return {:generate_test_model, :generate_empty_model}