
BoolGrid = require 'BoolGrid'
user_io = require 'user_io'
modules = require 'modules'
import camera, util_geometry from require "core"
import ObjectBase, CombatObjectBase, Player, NPC from require 'core.object_types'
import FieldOfView, FloodFillPaths, GameInstSet, RVOWorld, GameTiles from require "core"

MAX_SPEED = 32

-- Stores all objects for a given level, providing convenience 
-- methods for accessing subsets of the active objects
LevelObjectStore = with newtype()
    .init = () =>
        @list = {}
        @map = {}
        @highest_id = 0

    .add = (obj) => 
        assert(type(obj) == 'table')
        @highest_id += 1
        append @list, obj
        @map[@highest_id] = obj
        return @highest_id

    .get = (id) =>
        assert(type(id) == 'number')
        return @map[id]

    .remove = (obj_or_id) => 
        id, obj = (obj_or_id), (obj_or_id)
        if type(obj) ~= 'table'
            obj = @get(id)
        else -- id is an object
            id = obj.id

        @map[id] = nil
        table.remove_occurrences @list, obj

    .iter = (filter = nil) =>
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

    .closest = (obj1, filter) =>
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
        return closest

    .get_all = (filter) =>
        ret = {}
        for obj in @iter(filter) do append ret, obj
        return ret

_setup_level_state_helpers = (L) ->
    {w, h} = L.tilemap.size
    tw, th = L.tile_width, L.tile_height

    -- Function to convert a tile location to a real location
    L.tile_xy_to_real = (x, y) -> 
        return (x - .5) * tw, (y - .5) * th

    -- Function to convert a real location to a tile location
    -- Returns 'nil' if not possible
    L.real_xy_to_tile = (rx, ry) -> 
        -- Solve the inverse function of above
        x = math.floor(rx / tw + .5)
        y = math.floor(ry / th + .5)
        if (x >= 1 and x <= w) and (y >= 1 and y <= h)
            return x, y
        -- Otherwise, return nils
        return nil, nil

    -- Find the nearest multiple of the tile size
    L.real_xy_snap = (rx, ry) -> 
        rx = math.floor(rx / tw) * tw
        ry = math.floor(ry / th) * th
        return rx, ry

    L.tile_check = (obj, dx=0, dy=0, dradius=0) ->
        return GameTiles.radius_test(L.tilemap, obj.x + dx, obj.y + dy, obj.radius + dradius)

    L.object_check = (obj, dx=0, dy=0, dradius=0) ->
        return L.collision_world\object_radius_test(obj.id_col, obj.x + dx, obj.y + dy, obj.radius + dradius)

    L.solid_check = (obj, dx=0, dy=0, dradius=0) ->
        return L.tile_check(obj, dx, dy, dradius) or L.object_check(obj, dx, dy, dradius)

    L.object_iter = () ->
        return L.objects\iter()

    L.combat_object_iter = () ->
        return L.objects\iter(CombatObjectBase)

    L.player_iter = () ->
        return L.objects\iter(Player)

    L.local_player = () ->
        G = L.gamestate
        for p in L.player_iter()
            if G.is_local_player(p)
                return p
        return nil

    L.npc_iter = () ->
        return L.objects\iter(NPC)

    L.closest_player = (obj) ->
        return L.objects\closest(obj, Player)

setup_level_state = (L) ->
    -- The object store and ID allocator
    L.objects = LevelObjectStore.create()

    -- The game collision detection 'world'
    L.collision_world = GameInstSet.create(L.pix_width, L.pix_height)

    -- The game collision avoidance 'world'
    L.rvo_world = RVOWorld.create()

    L.step = () ->
        L.players\step(L)
        L.npcs\step(L)

    -- Run the generation functions that were delayed until
    -- the level creation (mainly instance spawning):
    for gen_func in *L.tilemap.instances
        gen_func(L)

    -- For good measure, clear generation functions:
    table.clear(L.tilemap.instances)

    level_logic = require 'core.level_logic'

    L.handle_io = () -> level_logic.handle_io(L)
    L.step = () -> level_logic.step(L)

    -- Set up various helper accesors
    _setup_level_state_helpers(L)


return {:setup_level_state}
