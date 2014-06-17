BoolGrid = require "BoolGrid"
mtwist = require "mtwist"
modules = require "game.modules"
T = modules.get_tilelist_id

import print_map, make_tunnel_oper, make_rectangle_criteria, make_rectangle_oper, place_instances
    from require "@map_util"

import FloodFillPaths, GameInstSet, GameTiles, GameView, util, mapgen
    from require "lanarts"

InstanceList =
    create: () ->
        obj = {instances: {}, positions: {}}
 
        obj.add = (content, xy) =>
            assert @\at(xy) == nil, "Overlapping instances! Some placement check failed."
            table.insert(@instances, content) 
            table.insert(@positions, xy) 

        obj.at = (xy) =>
            for i=1,#@instances
                content, cxy  = @instances[i], @positions[i]
                if cxy[1] == xy[1] and cxy[2] == xy[2] 
                    return content 
            return nil

        return obj

generate_test_model = (rng) ->
    padding = {10, 10}
    size = {80, 40}
    padded_size = {size[1]+padding[1]*2, size[2]+padding[2]*2}
    -- Uses 'InstanceList' class defined above
    map = mapgen.map_create { 
        size: padded_size
        content: T('dungeon_wall')
        flags: mapgen.FLAG_SOLID
        instances: InstanceList.create()
    }

    oper = mapgen.random_placement_operator {
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
    oper map, mapgen.ROOT_GROUP, bbox_create(padding, size)

    tunnel_oper = make_tunnel_oper(rng)

    tunnel_oper map, mapgen.ROOT_GROUP, bbox_create({0,0}, padded_size)

    --print_map(map, map.instances) -- Uncomment to print
    return map

return {:generate_test_model}