local mapgen = require "lanarts.mapgen"

local modules = require "game.modules"
local T = modules.get_tilelist_id

local function make_rectangle_criteria()
        return mapgen.rectangle_criteria { 
                fill_selector = { matches_all = mapgen.FLAG_SOLID, matches_none = mapgen.FLAG_PERIMETER }, 
                perimeter_width = 1, 
                perimeter_selector = { matches_all = mapgen.FLAG_SOLID }
        }
end

local function make_rectangle_oper(--[[Optional]] area_query)
    return mapgen.rectangle_operator { 
        area_query = area_query,
        perimeter_width = 1,
       fill_operator = { remove = {mapgen.FLAG_SOLID}, content = T('grey_floor') },
        perimeter_operator = { add = {mapgen.FLAG_PERIMETER}, content = T('dungeon_wall') },
    }
end

local function make_tunnel_oper(rng) 
        return mapgen.tunnel_operator {
        validity_selector = { 
            fill_selector = { matches_all = mapgen.FLAG_SOLID, matches_none = mapgen.FLAG_TUNNEL },
            perimeter_selector = { matches_all = mapgen.FLAG_SOLID, matches_none = mapgen.FLAG_TUNNEL }
        },

        completion_selector = {
            fill_selector = { matches_none = {mapgen.FLAG_SOLID, mapgen.FLAG_PERIMETER, mapgen.FLAG_TUNNEL} },
            perimeter_selector = { matches_none = mapgen.FLAG_SOLID } 
        },

        fill_operator = { add = mapgen.FLAG_TUNNEL, remove = mapgen.FLAG_SOLID, content = T('grey_floor')},
        perimeter_operator = { matches_all = mapgen.FLAG_SOLID, add = {mapgen.FLAG_SOLID, mapgen.FLAG_TUNNEL, mapgen.FLAG_PERIMETER}, content = T('dungeon_wall') },

            rng = rng,
                perimeter_width = 1,
        size_range = {1,2},
        tunnels_per_room_range = {1,2}
    }
end

local function place_instance(rng, map, area, type)          
        local xy = mapgen.find_random_square { map = map, area = area, selector = {matches_none = {mapgen.FLAG_HAS_OBJECT, mapgen.FLAG_SOLID} }, rng = rng }
        if xy ~= nil then
                map.instances:add(type, xy)
                map:square_apply(xy, {add = mapgen.FLAG_HAS_OBJECT})
        end
end

local function place_instances(rng, map, area)
        for i=1,4 do
                place_instance(rng, map, area, '1')
                place_instance(rng, map, area, '2')
                place_instance(rng, map, area, '3')
        end
end


local function print_map(map, instances)
    local parts = {}
    instances = instances

    local function add_part(strpart) 
        table.insert(parts, strpart)
    end

    for y=0,map.size[2]-1 do
        for x=0,map.size[1]-1 do
                local inst = instances:at({x,y})
            local sqr = map:get({x, y})

            local n, g = sqr.content, sqr.group
            local solid = mapgen.flags_match(sqr.flags, mapgen.FLAG_SOLID)
            local perimeter = mapgen.flags_match(sqr.flags, mapgen.FLAG_PERIMETER)
            local tunnel = mapgen.flags_match(sqr.flags, mapgen.FLAG_TUNNEL)

            if inst then 
                add_part(inst .. " ") 
            elseif solid and tunnel then
                add_part("T ")
            elseif not solid and tunnel then
                add_part("- ")
            elseif perimeter and solid then
                add_part("O ")
            elseif n == 0 then
                add_part(solid and "# " or "0 ")
            elseif n == 1 then
                add_part("  ")
            elseif n == 2 then
                add_part("# ")
            elseif n == 3 then
                add_part("  ")
            elseif n == 4 then
                add_part("# ")
            end
        end
        add_part("\n")
    end

    print(table.concat(parts))
end

return {
    print_map = print_map, make_rectangle_criteria = make_rectangle_criteria, 
    make_rectangle_oper = make_rectangle_oper, make_tunnel_oper = make_tunnel_oper,
    place_instances = place_instances
}
