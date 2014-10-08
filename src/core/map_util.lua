local TileMap = require "core.TileMap"

local function make_rectangle_criteria()
        return TileMap.rectangle_criteria { 
                fill_selector = { matches_all = TileMap.FLAG_SOLID, matches_none = TileMap.FLAG_PERIMETER }, 
                perimeter_width = 1, 
                perimeter_selector = { matches_all = TileMap.FLAG_SOLID }
        }
end

local function make_rectangle_oper(floor, wall, wall_seethrough, --[[Optional]] area_query)
    wall_flags = {TileMap.FLAG_SOLID}
    remove_wall_flags = {TileMap.FLAG_SEETHROUGH}
    if wall_seethrough then
        append(wall_flags, TileMap.FLAG_SEETHROUGH)
        remove_wall_flags = {}
    end
    return TileMap.rectangle_operator { 
        area_query = area_query,
        perimeter_width = 1,
       fill_operator = { add = {TileMap.FLAG_CUSTOM5, TileMap.FLAG_SEETHROUGH}, remove = {TileMap.FLAG_SOLID}, content = floor},
        perimeter_operator = { add = {TileMap.FLAG_PERIMETER}, remove = remove_wall_flags, content = wall },
    }
end

local function make_tunnel_oper(rng, floor, wall, wall_seethrough) 
    wall_flags = {TileMap.FLAG_SOLID, TileMap.FLAG_TUNNEL, TileMap.FLAG_PERIMETER}
    remove_flags = {}
    if wall_seethrough then
        append(wall_flags, TileMap.FLAG_SEETHROUGH)
    else
        append(remove_flags, TileMap.FLAG_SEETHROUGH)
    end
    return TileMap.tunnel_operator {
        validity_selector = { 
            fill_selector = { matches_all = TileMap.FLAG_SOLID, matches_none = TileMap.FLAG_TUNNEL },
            perimeter_selector = { matches_all = TileMap.FLAG_SOLID, matches_none = TileMap.FLAG_TUNNEL }
        },

        completion_selector = {
            fill_selector = { matches_none = {TileMap.FLAG_SOLID, TileMap.FLAG_PERIMETER, TileMap.FLAG_TUNNEL} },
            perimeter_selector = { matches_none = TileMap.FLAG_SOLID } 
        },
        fill_operator = { add = {TileMap.FLAG_SEETHROUGH, TileMap.FLAG_TUNNEL}, remove = TileMap.FLAG_SOLID, content = floor},
        perimeter_operator = { matches_all = TileMap.FLAG_SOLID, add = wall_flags, remove = remove_flags, content = wall},

        rng = rng,
        perimeter_width = 1,
        size_range = {1,2},
        tunnels_per_room_range = {1,2}
    }
end

return {
    make_rectangle_criteria = make_rectangle_criteria, 
    make_rectangle_oper = make_rectangle_oper, make_tunnel_oper = make_tunnel_oper,
}
