local TileMap = require "core.TileMap"
local modules = require "core.data"

local T = modules.get_tilelist_id

local function make_rectangle_criteria()
        return TileMap.rectangle_criteria { 
                fill_selector = { matches_all = TileMap.FLAG_SOLID, matches_none = TileMap.FLAG_PERIMETER }, 
                perimeter_width = 1, 
                perimeter_selector = { matches_all = TileMap.FLAG_SOLID }
        }
end

local function make_rectangle_oper(--[[Optional]] area_query)
    return TileMap.rectangle_operator { 
        area_query = area_query,
        perimeter_width = 1,
       fill_operator = { add = {TileMap.FLAG_SEETHROUGH}, remove = {TileMap.FLAG_SOLID}, content = T('grey_floor') },
        perimeter_operator = { add = {TileMap.FLAG_PERIMETER}, content = T('dungeon_wall') },
    }
end

local function make_tunnel_oper(rng) 
    return TileMap.tunnel_operator {
        validity_selector = { 
            fill_selector = { matches_all = TileMap.FLAG_SOLID, matches_none = TileMap.FLAG_TUNNEL },
            perimeter_selector = { matches_all = TileMap.FLAG_SOLID, matches_none = TileMap.FLAG_TUNNEL }
        },

        completion_selector = {
            fill_selector = { matches_none = {TileMap.FLAG_SOLID, TileMap.FLAG_PERIMETER, TileMap.FLAG_TUNNEL} },
            perimeter_selector = { matches_none = TileMap.FLAG_SOLID } 
        },

        fill_operator = { add = {TileMap.FLAG_SEETHROUGH, TileMap.FLAG_TUNNEL}, remove = TileMap.FLAG_SOLID, content = T('grey_floor')},
        perimeter_operator = { matches_all = TileMap.FLAG_SOLID, add = {TileMap.FLAG_SOLID, TileMap.FLAG_TUNNEL, TileMap.FLAG_PERIMETER}, content = T('dungeon_wall') },

        rng = rng,
        perimeter_width = 1,
        size_range = {1,2},
        tunnels_per_room_range = {1,2}
    }
end

local function place_instance(rng, map, area, type)          
        local xy = TileMap.find_random_square { map = map, area = area, selector = {matches_none = {TileMap.FLAG_HAS_OBJECT, TileMap.FLAG_SOLID} }, rng = rng }
        if xy ~= nil then
                append(map.instances, type)
                map:square_apply(xy, {add = TileMap.FLAG_HAS_OBJECT})
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
            -- TODO: Broken
                local inst = instances:at({x,y})
            local sqr = map:get({x, y})

            local n, g = sqr.content, sqr.group
            local solid = TileMap.flags_match(sqr.flags, TileMap.FLAG_SOLID)
            local perimeter = TileMap.flags_match(sqr.flags, TileMap.FLAG_PERIMETER)
            local tunnel = TileMap.flags_match(sqr.flags, TileMap.FLAG_TUNNEL)

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
