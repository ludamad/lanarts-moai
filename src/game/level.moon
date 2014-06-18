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
setup_camera = (C) ->
    w,h = C.tilemap_width, C.tilemap_height
    tw, th = C.tile_width, C.tile_height

    cx, cy = w * tw / 2, h * th / 2
    assert(not C.camera and not C.viewport, "Double call to setup_view!")
    C.camera = with MOAICamera2D.new()
        \setLoc(cx,cy)
    C.viewport = with MOAIViewport.new()
        \setSize(C.cameraw, C.camerah)
        \setScale(C.cameraw, -C.camerah)

-------------------------------------------------------------------------------
-- Set up the layers for the map
-------------------------------------------------------------------------------
setup_tile_layers = (C) ->
    -- Map and tile dimensions
    w,h = C.tilemap_width, C.tilemap_height
    tw, th = C.tile_width, C.tile_height

    -- Prop lists, and grid map
    -- There is one prop and grid for each tile texture used
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
        n = C.rng\random(1, #tilelist.tiles + 1)
        tile = tilelist.tiles[n]

        grid\setTile(x, y, tile.grid_id)

    for y=1,h do for x=1,w
        _set_xy(x, y, C.tilemap\get({x,y}).content)

    layer = C.add_layer()

    pretty("Props", props)
    -- Add all the different textures to the layer
    for p in *props do layer\insertProp(p)

setup_fov_layer = (C) ->
    w,h = C.tilemap_width, C.tilemap_height
    tw, th = C.tile_width, C.tile_height
    tex = res.get_texture "fogofwar.png"
    tex_w, tex_h = tex\getSize()

    C.fov_layer = C.add_layer()
    C.fov_grid = with MOAIGrid.new()
        \setSize(w, h, tw, th)

    C.fov_layer\insertProp with MOAIProp2D.new()
        \setDeck with MOAITileDeck2D.new()
            \setTexture(tex)
            \setSize(tex_w / tw, tex_h / th)
        \setGrid(C.fov_grid)

    for y=1,h do for x=1,w 
        -- Set to unexplored (black)
        C.fov_grid\setTile(x,y, 2)

setup_overlay_layers = (C) ->
    -- Add the object layer, which holds assorted game objects. 
    C.object_layer = C.add_layer()
    -- Add the field of view layer, which hides unexplored regions.
    setup_fov_layer(C)

    -- Add the UI layer.
    C.ui_layer = C.add_layer()

    -- Helpers for layer management
    C.add_ui_prop = (prop) -> C.ui_layer\insertProp(prop)
    C.remove_ui_prop = (prop) -> C.ui_layer\removeProp(prop)
    C.add_object_prop = (prop) -> C.object_layer\insertProp(prop)
    C.remove_object_prop = (prop) -> C.object_layer\removeProp(prop)

-------------------------------------------------------------------------------
-- Set up helper methods (closures, to be exact)
-------------------------------------------------------------------------------

setup_helpers = (C) ->
    {w, h} = C.tilemap.size
    tw, th = C.tile_width, C.tile_height

    -- Function to convert a tile location to a real location
    C.tile_xy_to_real = (x, y) -> 
        return (x - .5) * tw, (y - .5) * th

    -- Function to convert a real location to a tile location
    -- Returns 'nil' if not possible
    C.real_xy_to_tile = (rx, ry) -> 
        -- Solve the inverse function of above
        x = math.floor(rx / tw + .5)
        y = math.floor(ry / th + .5)
        if (x >= 1 and x <= w) and (y >= 1 and y <= h)
            return x, y
        -- Otherwise, return nils
        return nil, nil

    -- Find the nearest multiple of the tile size
    C.real_xy_snap = (rx, ry) -> 
        rx = math.floor(rx / tw) * tw
        ry = math.floor(ry / th) * th
        return rx, ry

    C.tile_check = (obj, dx=0, dy=0, dradius=0) ->
        return GameTiles.radius_test(C.tilemap, obj.x + dx, obj.y + dy, obj.radius + dradius)

    C.object_check = (obj, dx=0, dy=0, dradius=0) ->
        return C.collision_world\object_radius_test(obj.id_col, obj.x + dx, obj.y + dy, obj.radius + dradius)

    C.solid_check = (obj, dx=0, dy=0, dradius=0) ->
        return C.tile_check(obj, dx, dy, dradius) or C.object_check(obj, dx, dy, dradius)

    -- Create and add a layer, sorted by priority (the default sort mode):
    C.add_layer = () -> 
        layer = with MOAILayer2D.new()
            \setCamera(C.camera) -- All layers use the same camera
            \setViewport(C.viewport) -- All layers use the same viewport
        append(C.layers, layer)
        return layer

-------------------------------------------------------------------------------
-- Set up game state
-------------------------------------------------------------------------------

setup_level_state = (C) ->
    -- The game-logic objects
    C.objects = {}
    -- The game collision detection 'world'
    C.collision_world = GameInstSet.create(C.pix_width, C.pix_height)

    -- The game collision avoidance 'world'
    C.rvo_world = RVOWorld.create()

    -- C.solidity, C.seethrough = util.extract_solidity_and_seethrough_maps(C.tilemap)

-------------------------------------------------------------------------------
-- The main stepping 'thread' (coroutine)
-------------------------------------------------------------------------------

main_thread = (C) -> create_thread () ->
    while true
        coroutine.yield()
        for i=1,2 do C.step()
        C.pre_draw()
        -- print MOAISim.getPerformance()
        if not _SETTINGS.headless
            for component in *C.ui_components
                -- Step the component
                component()

-------------------------------------------------------------------------------
-- Returns a 'components object' that holds the various parts of the 
-- level's state.
-- The 'tilemap' is created by the core.TileMap module.
-------------------------------------------------------------------------------

create = (rng, tilemap, cameraw, camerah) ->
    -- Initialize our components object
    C = { :rng, :tilemap, :cameraw, :camerah }

    -- Hardcoded for now:
    C.tile_width,C.tile_height = 32,32

    {C.tilemap_width, C.tilemap_height} = C.tilemap.size
    C.pix_width, C.pix_height = (C.tile_width*C.tilemap_width), (C.tile_height*C.tilemap_height)

    -- The MOAI layers to accumulate
    C.layers = {}
    -- The UI objects that run each step
    C.ui_components = {}
    -- TODO: Reevaluate spread of state
    C.instances = C.tilemap.instances.instances

    setup_helpers(C)
    setup_level_state(C)
    setup_camera(C)
    setup_tile_layers(C)
    setup_overlay_layers(C)

    -- Setup function
    C.start = () -> 
         -- Begin rendering the MOAI layers
        for layer in *C.layers
           MOAISim.pushRenderPass(layer)
        for inst in *C.instances
            inst\register(C)
        thread = main_thread(C)
        thread.start()
        return thread

    -- Tear-down function
    C.stop = () -> 
        for thread in *C.threads
            thread.stop()
        -- Cease rendering the MOAI layers
        for layer in *C.layers
            MOAISim.removeRenderPass(layer)

    -- Game step function
    C.step = () ->
        before = MOAISim.getDeviceTime()
        --if user_io.key_down "K_Q"
        gamestate.push_state(C.instances)

        if user_io.key_down "K_E"
            gamestate.pop_state(C.instances)

        for inst in *C.instances
            inst\step(C)
        -- Synchronize data to the subsystems
        for inst in *C.instances
            inst\post_step(C)

        -- Step the subsystems
        C.collision_world\step()
        C.rvo_world\step()
        print "Step took ", (MOAISim.getDeviceTime() - before) * 1000, 'ms'

    C.pre_draw = () ->
        before = MOAISim.getDeviceTime()
        -- Update the sight map
        for inst in *C.instances do if inst.is_focus
           {seen_tile_map: seen, prev_seen_bounds: prev, current_seen_bounds: curr, fieldofview: fov} = inst.vision
           x1,y1,x2,y2 = camera.tile_region_covered(C)
           for y=y1,y2 do for x=x1,x2
                tile = if seen\get(x,y) then 1 else 2
                C.fov_grid\setTile(x, y, tile)
           {x1,y1,x2,y2} = curr
           for y=y1,y2-1 do for x=x1,x2-1
                if fov\within_fov(x,y)
                    C.fov_grid\setTile(x, y, 0) -- Currently seen

        print "Pre-draw took ", (MOAISim.getDeviceTime() - before) * 1000, 'ms'

    append C.ui_components, ui_ingame_select C
    append C.ui_components, ui_ingame_scroll C

    return C

return {:create}