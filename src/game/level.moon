-------------------------------------------------------------------------------
-- Standard requires from Lanarts engine 
-------------------------------------------------------------------------------

BoolGrid, mtwist = require "BoolGrid", require "mtwist" 

import FloodFillPaths, GameInstSet, GameTiles, GameView, util, TileMap, RVOWorld
    from require "core"

-------------------------------------------------------------------------------
-- Other requires
-------------------------------------------------------------------------------

import create_thread from require 'game.util'
import ui_ingame_scroll, ui_ingame_select from require "game.ui"

import modules, camera from require 'game'

user_io = require 'user_io'
res = require 'resources'
gamestate = require 'core.gamestate'

-------------------------------------------------------------------------------
-- Set up the camera & viewport
-------------------------------------------------------------------------------
setup_camera = (V) ->
    w,h = V.level.tilemap_width, V.level.tilemap_height
    tw, th = V.level.tile_width, V.level.tile_height

    cx, cy = w * tw / 2, h * th / 2
    assert(not V.camera and not V.viewport, "Double call to setup_view!")
    V.camera = with MOAICamera2D.new()
        \setLoc(cx,cy)
    V.viewport = with MOAIViewport.new()
        \setSize(V.cameraw, V.camerah)
        \setScale(V.cameraw, -V.camerah)

-------------------------------------------------------------------------------
-- Set up the layers for the map
-------------------------------------------------------------------------------
setup_tile_layers = (V) ->
    -- Map and tile dimensions
    w,h = V.level.tilemap_width, V.level.tilemap_height
    tw, th = V.level.tile_width, V.level.tile_height

    -- Prop lists, and grid map
    -- There :is one prop and grid for each tile texture used
    props, grids = {}, {}

    -- Get the appropriate grid for a tile ID
    _grid = (tileid) ->
        tilelist = modules.get_tilelist(tileid)
        file = tilelist.texfile

        if not grids[file] 
            grids[file] = with MOAIGrid.new()
                \setSize(w, h, tw, th)

            tex = res.get_texture(file)
            tex_w, tex_h = tex\getSize()
            -- Create the tile prop:
            append props, with MOAIProp2D.new()
                \setDeck with MOAITileDeck2D.new()
                    \setTexture(res.get_texture(file))
                    \setSize(tex_w / tw, tex_h / th)
                \setGrid(grids[file])
        return grids[file]

    -- Assign a tile to the appropriate grid
    _set_xy = (x, y, tileid) ->
        -- 0 represents an empty tile, for now
        if tileid == 0 then return
        -- Otherwise, locate the correct grid instance
        -- and set the tile grid position accordingly
        grid = _grid(tileid)
        tilelist = modules.get_tilelist(tileid)
        -- The tile number
        n = _RNG\random(1, #tilelist.tiles + 1)
        tile = tilelist.tiles[n]

        grid\setTile(x, y, tile.grid_id)

    for y=1,h do for x=1,w
        _set_xy(x, y, V.level.tilemap\get({x,y}).content)

    layer = V.add_layer()

    pretty("Props", props)
    -- Add all the different textures to the layer
    for p in *props do layer\insertProp(p)

setup_fov_layer = (V) ->
    w,h = V.level.tilemap_width, V.level.tilemap_height
    tw, th = V.level.tile_width, V.level.tile_height
    tex = res.get_texture "fogofwar.png"
    tex_w, tex_h = tex\getSize()

    V.fov_layer = V.add_layer()
    V.fov_grid = with MOAIGrid.new()
        \setSize(w, h, tw, th)

    V.fov_layer\insertProp with MOAIProp2D.new()
        \setDeck with MOAITileDeck2D.new()
            \setTexture(tex)
            \setSize(tex_w / tw, tex_h / th)
        \setGrid(V.fov_grid)

    for y=1,h do for x=1,w 
        -- Set to unexplored (black)
        V.fov_grid\setTile(x,y, 2)

setup_overlay_layers = (V) ->
    -- Add the object layer, which holds assorted game objects. 
    V.object_layer = V.add_layer()
    -- Add the field of view layer, which hides unexplored regions.
    setup_fov_layer(V)

    -- Add the UI layer.
    V.ui_layer = V.add_layer()

    -- Helpers for layer management
    V.add_ui_prop = (prop) -> V.ui_layer\insertProp(prop)
    V.remove_ui_prop = (prop) -> V.ui_layer\removeProp(prop)
    V.add_object_prop = (prop) -> V.object_layer\insertProp(prop)
    V.remove_object_prop = (prop) -> V.object_layer\removeProp(prop)

-------------------------------------------------------------------------------
-- Set up helper methods (closures, to be exact)
-------------------------------------------------------------------------------

setup_level_state_helpers = (L) ->
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

create_level_state = (rng, tilemap) ->
    L = { :rng, :tilemap }

    -- Hardcoded for now:
    L.tile_width,L.tile_height = 32,32

    {L.tilemap_width, L.tilemap_height} = L.tilemap.size
    L.pix_width, L.pix_height = (L.tile_width*L.tilemap_width), (L.tile_height*L.tilemap_height)

    -- TODO: Reevaluate spread of state
    L.instances = L.tilemap.instances.instances

    setup_level_state_helpers(L)

    -------------------------------------------------------------------------------
    -- Set up level state
    -------------------------------------------------------------------------------

    -- The game-logic objects
    L.objects = {}
    -- The game collision detection 'world'
    L.collision_world = GameInstSet.create(L.pix_width, L.pix_height)

    -- The game collision avoidance 'world'
    L.rvo_world = RVOWorld.create()

    for inst in *L.instances
        inst\register(L)

    L.step = () ->
        for inst in *L.instances
            inst\step(L)

        -- Synchronize data to the subsystems
        for inst in *L.instances
            inst\post_step(L)

        -- Step the subsystems
        L.collision_world\step()
        L.rvo_world\step()

    return L

create_level_view = (level, cameraw, camerah) ->
    V = {:level, :cameraw, :camerah}

    -- The MOAI layers to accumulate
    V.layers = {}
    -- The UI objects that run each step
    V.ui_components = {}

    -- Create and add a layer, sorted by priority (the default sort mode):
    V.add_layer = () -> 
        layer = with MOAILayer2D.new()
            \setCamera(V.camera) -- All layers use the same camera
            \setViewport(V.viewport) -- All layers use the same viewport
        append(V.layers, layer)
        return layer

    -- Setup function
    V.start = () -> 
         -- Begin rendering the MOAI layers
        for layer in *V.layers
           MOAISim.pushRenderPass(layer)
        for inst in *V.level.instances
            inst\register_prop(V)

    V.pre_draw = () ->
        -- print MOAISim.getPerformance()
        if not _SETTINGS.headless
            for component in *V.ui_components
                -- Step the component
                component()

        -- Update the sight map
        for inst in *V.level.instances do 
            inst\pre_draw(V)
            if inst.is_focus
               {seen_tile_map: seen, prev_seen_bounds: prev, current_seen_bounds: curr, fieldofview: fov} = inst.vision
               x1,y1,x2,y2 = camera.tile_region_covered(V)
               for y=y1,y2 do for x=x1,x2
                    tile = if seen\get(x,y) then 1 else 2
                    V.fov_grid\setTile(x, y, tile)
               {x1,y1,x2,y2} = curr
               for y=y1,y2-1 do for x=x1,x2-1
                    if fov\within_fov(x,y)
                        V.fov_grid\setTile(x, y, 0) -- Currently seen

    V.stop = () ->
        -- Cease rendering the MOAI layers
        for layer in *V.layers
            MOAISim.removeRenderPass(layer)

    V.clear = () ->
        for layer in *V.layers
            layer\clear()

    setup_camera(V)
    setup_tile_layers(V)
    setup_overlay_layers(V)

    append V.ui_components, ui_ingame_select V
    append V.ui_components, ui_ingame_scroll V

    return V

-------------------------------------------------------------------------------
-- The main stepping 'thread' (coroutine)
-------------------------------------------------------------------------------

main_thread = (G) -> create_thread () ->
    while true
        coroutine.yield()

        before = MOAISim.getDeviceTime()
        G.step()
        G.pre_draw()

-------------------------------------------------------------------------------
-- Returns a 'components object' that holds the various parts of the 
-- level's state.
-- The 'tilemap' is created by the core.TileMap module.
-------------------------------------------------------------------------------

create_game_state = (level, cameraw, camerah) ->
    V = create_level_view(level, cameraw, camerah)
    G = {level_view: V, level: level}

    -- Setup function
    G.start = () -> 
        V.start()

        thread = main_thread(G)
        thread.start()
        return thread

    -- Tear-down function
    G.stop = () -> 
        V.stop()
        for thread in *G.threads
            thread.stop()

    -- Game step function
    G.step = () -> G.level.step()

    G.handle_io = () ->
        if user_io.key_down "K_Q"
            gamestate.push_state(G.level)

        if user_io.key_down "K_E"
            gamestate.pop_state(G.level)

        G.level\handle_io(G)

    G.pre_draw = () -> G.level_view.pre_draw()

        -- print "Pre-draw took ", (MOAISim.getDeviceTime() - before) * 1000, 'ms'

    return G

return {:create_game_state, :create_level_state, :create_level_view}