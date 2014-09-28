
BoolGrid = require 'BoolGrid'
user_io = require 'user_io'
modules = require 'core.data'
import util_geometry from require "core"
import ObjectBase, CombatObjectBase, Player, NPC from require 'core.map_object_types'
import FieldOfView, FloodFillPaths, GameInstSet, RVOWorld, GameTiles from require "core"

MAX_SPEED = 32

-- Stores all objects for a given map, providing convenience 
-- methods for accessing subsets of the active objects
MapObjectStore = newtype {
    init: () =>
        @list = {}
        @map = {}
        @highest_id = 0

    add: (obj) => 
        assert(type(obj) == 'table')
        @highest_id += 1
        append @list, obj
        @map[@highest_id] = obj
        return @highest_id

    get: (id) =>
        assert(type(id) == 'number')
        return @map[id]

    remove: (obj_or_id) => 
        id, obj = (obj_or_id), (obj_or_id)
        if type(obj) ~= 'table'
            obj = @get(id)
        else -- id is an object
            id = obj.id

        @map[id] = nil
        table.remove_occurrences @list, obj

    iter: (filter = nil) =>
        if filter == nil
            return values(@list)
        if type(filter) == 'table' 
            -- Assume 'filter' was created by 'newtype'
            filter = filter.isinstance
        idx = 1
        return () -> while true
            val = @list[idx]
            idx += 1
            if val == nil or filter(val)
                return val

    closest: (obj1, filter) =>
        if type(filter) == 'table' 
            -- Assume 'filter' was created by 'newtype'
            filter = filter.isinstance

        least_dist,closest = math.huge,nil
        for obj2 in *@list do 
            if filter == nil or filter(obj2)
                d = util_geometry.object_distance(obj1, obj2) 
                if d < least_dist
                    least_dist, closest = d, obj2
        -- Return closest object
        return closest, least_dist

    get_all: (filter) =>
        ret = {}
        for obj in @iter(filter) do append ret, obj
        return ret
}

_setup_map_state_helpers = (M) ->
    {w, h} = M.tilemap.size
    tw, th = M.tile_width, M.tile_height

    -- Function to convert a tile location to a real location
    M.tile_xy_to_real = (x, y) -> 
        return (x - .5) * tw, (y - .5) * th

    -- Function to convert a real location to a tile location
    -- Returns 'nil' if not possible
    M.real_xy_to_tile = (rx, ry) -> 
        -- Solve the inverse function of above
        x = math.floor(rx / tw + .5)
        y = math.floor(ry / th + .5)
        if (x >= 1 and x <= w) and (y >= 1 and y <= h)
            return x, y
        -- Otherwise, return nils
        return nil, nil

    -- Find the nearest multiple of the tile size
    M.real_xy_snap = (rx, ry) -> 
        rx = math.floor(rx / tw) * tw
        ry = math.floor(ry / th) * th
        return rx, ry

    M.tile_check = (obj, dx=0, dy=0, radius=obj.radius) ->
        return GameTiles.radius_test(M.tilemap, obj.x + dx, obj.y + dy, radius)

    M.object_check = (obj, dx=0, dy=0, radius=obj.target_radius) ->
        return M.collision_world\object_radius_test(obj.id_col, obj.x + dx, obj.y + dy, radius)

    _OBJ_BUFFER = {}
    M.object_query = (obj, dx=0, dy=0, radius=obj.target_radius) ->
        table.clear(_OBJ_BUFFER)
        M.collision_world\object_radius_query(obj.id_col, _OBJ_BUFFER, obj.x + dx, obj.y + dy, radius)
        return _OBJ_BUFFER

    M.solid_check = (obj, dx=0, dy=0, radius=nil) ->
        return M.tile_check(obj, dx, dy, dradius) or M.object_check(obj, dx, dy, radius)

    M.free_resources = () ->
        -- Don't need to set things to nil (the Lua GC will handle this)
        -- but we should explicitly large data blocks allocated on the C++ side,
        -- as these won't be freed until the _Lua_ memory usage grows too large.
        M.tilemap\clear()
        M.rvo_world\clear()

    M.local_player = () ->
        G = M.gamestate
        for p in *M.player_list
            if G.is_local_player(p)
                return p
        return nil

    _SEEN_MAPS = {}
    M.player_seen_map = (id_player) ->
        seen_map = _SEEN_MAPS[id_player]
        if not seen_map
            seen_map = BoolGrid.create(M.tilemap_width, M.tilemap_height, false)
            _SEEN_MAPS[id_player] = seen_map
        return seen_map

    M.npc_iter = () ->
        return M.objects\iter(NPC)

    M.closest_player = (obj) ->
        return M.objects\closest(obj, Player)

setup_map_state = (M) ->
    -- The object store and ID allocator
    M.objects = MapObjectStore.create()
    -- Various object lists:
    M.object_list = M.objects.list
    M.combat_object_list = {}
    M.npc_list = {}
    M.player_list = {}
    M.projectile_list = {}
    M.animation_list = {}
    M.item_list = {}
    -- Features include any interactable dungeon element
    M.feature_list = {}
    -- Map from a collision ID to an active object
    M.col_id_to_object = {}
    -- Objects to be removed
    M.removal_list = {}

    -- The game collision detection 'world'
    M.collision_world = GameInstSet.create(M.pix_width, M.pix_height)

    -- The game collision avoidance 'world'
    M.rvo_world = RVOWorld.create()

    map_logic = require 'core.map_logic'

    M.handle_io = () -> map_logic.handle_io(M)
    M.step = () -> map_logic.step(M)

    -- Set up various helper accesors
    _setup_map_state_helpers(M)

-------------------------------------------------------------------------------
-- Set up helper methods (closures, to be exact)
-------------------------------------------------------------------------------

create_map_state = (G, id, rng, tilemap) ->
    M = {gamestate: G, :id, :rng, :tilemap}

    -- Set up map dimensions
    -- Hardcoded for now:
    M.tile_width,M.tile_height = 32,32

    {M.tilemap_width, M.tilemap_height} = M.tilemap.size
    M.pix_width, M.pix_height = (M.tile_width*M.tilemap_width), (M.tile_height*M.tilemap_height)

    -- Set up map state
    setup_map_state(M)

    return M

-- Current map:
_current_map = nil

return {
    :create_map_state
    map_set: (map) -> _current_map = map
    map_get: () -> _current_map
    -- Size of map in pixels
    map_size: () -> 
        _current_map.pix_width, _current_map.pix_height
    -- Size of map in tiles
    map_tile_size: () -> 
        _current_map.tilemap_width, _current_map.tilemap_height
    -- Size of an individual tile
    map_tile_pixels: () -> 
        _current_map.tile_width, _current_map.tile_height
    map_rng: () -> _current_map.rng
}
