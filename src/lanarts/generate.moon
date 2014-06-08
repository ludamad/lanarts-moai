BoolGrid = require "BoolGrid"
mtwist = require "mtwist"

import print_map, make_tunnel_oper, make_rectangle_criteria, make_rectangle_oper, place_instances
    from require "map_util"

import FloodFillPaths, GameInstSet, GameTiles, GameView, util, mapgen
    from require "lanarts"

InstanceList =
    create: () ->
        obj = {instances: {}}
 
        obj.add = (content, xy) =>
            assert @\at(xy) == nil, "Overlapping instances! Some placement check failed."
            table.insert(@instances, {content, xy}) 

        obj.at = (xy) =>
            for inst in *@instances
                content, cxy = unpack(inst)
                if cxy[1] == xy[1] and cxy[2] == xy[2] 
                    return content 
            return nil

        return obj

generate = (rng) ->
    -- Uses 'InstanceList' class defined above
    map = mapgen.map_create { size: {80,40}, flags: mapgen.FLAG_SOLID, instances: InstanceList.create() }

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
                place_instances(rng, map, bounds)
                return true
            return false
    }
 
    -- Apply the binary space partitioning (bsp)
    oper map, mapgen.ROOT_GROUP, bbox_create({0,0}, map.size)

    tunnel_oper = make_tunnel_oper(rng)

    tunnel_oper map, mapgen.ROOT_GROUP, bbox_create( {0,0}, map.size) 

    print_map(map, map.instances)

rng = mtwist.create(1)
generate(rng)
