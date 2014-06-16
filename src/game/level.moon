-------------------------------------------------------------------------------
-- Standard requires from Lanarts engine 
-------------------------------------------------------------------------------

BoolGrid, mtwist = require "BoolGrid", require "mtwist" 

import FloodFillPaths, GameInstSet, GameTiles, GameView, util, mapgen, RVOWorld
    from require "lanarts"

-------------------------------------------------------------------------------
-- Other requires
-------------------------------------------------------------------------------

import create_thread from require 'game.util'
import ui_ingame_scroll, ui_ingame_select from require "game.ui"
modules = require 'game.modules'
res = require 'resources'

-------------------------------------------------------------------------------
-- Set up the camera & viewport
-------------------------------------------------------------------------------
setup_view = (C) ->
    w,h = C.model_width, C.model_height
    tw, th = C.tile_width, C.tile_height

    cx, cy = w * tw / 2, h * th / 2
    assert(not C.camera and not C.viewport, "Double call to setup_view!")
    C.camera = with MOAICamera2D.new()
        \setLoc(cx,cy)
    C.viewport = with MOAIViewport.new()
        \setSize(C.vieww, C.viewh)
        \setScale(C.vieww, -C.viewh)

-------------------------------------------------------------------------------
-- Set up the layers for the map
-------------------------------------------------------------------------------
setup_tile_layers = (C) ->
    -- Map and tile dimensions
    w,h = C.model_width, C.model_height
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
        _set_xy(x, y, C.model\get({x,y}).content)

    layer = C.add_layer()

    pretty("Props", props)
    -- Add all the different textures to the layer
    for p in *props do layer\insertProp(p)

setup_overlay_layers = (C) ->
    -- Add the object layer, which holds assorted game objects. 
    C.object_layer = C.add_layer()
    -- Add the field of view layer, which hides unexplored regions.
    C.fov_layer = C.add_layer()
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
    {w, h} = C.model.size
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

    C.tile_check = (obj) ->
        return GameTiles.radius_test(C.model, obj.x, obj.y, obj.radius)

    C.object_check = (obj) ->
        return C.collision_world\object_radius_test(obj.id_col)

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

    -- C.solidity, C.seethrough = util.extract_solidity_and_seethrough_maps(C.model)

-------------------------------------------------------------------------------
-- The main stepping 'thread' (coroutine)
-------------------------------------------------------------------------------

main_thread = (C) -> create_thread () ->
    while true
        coroutine.yield()
        C.step()

-------------------------------------------------------------------------------
-- Returns a 'components object' that holds the various parts of the 
-- level's state.
-- The 'model' is created by the lanarts.mapgen module.
-------------------------------------------------------------------------------

create = (rng, model, vieww, viewh) ->
    -- Initialize our components object
    C = { :rng, :model, :vieww, :viewh }

    -- Hardcoded for now:
    C.tile_width,C.tile_height = 32,32

    {C.model_width, C.model_height} = C.model.size
    C.pix_width, C.pix_height = (C.tile_width*C.model_width), (C.tile_height*C.model_height)

    -- The MOAI layers to accumulate
    C.layers = {}
    -- The UI or animation threads to accumulate
    C.threads = {}
    -- TODO: Reevaluate spread of state
    C.instances = C.model.instances.instances

    setup_helpers(C)
    setup_level_state(C)
    setup_view(C)
    setup_tile_layers(C)
    setup_overlay_layers(C)

    -- Setup function
    C.start = () -> 
        -- Set up the camera & viewport
        for thread in *C.threads
            thread.start()
         -- Begin rendering the MOAI layers
        for layer in *C.layers
           MOAISim.pushRenderPass(layer)
        for inst in *C.instances
            inst\register(C)

    -- Tear-down function
    C.stop = () -> 
        for thread in *C.threads
            thread.stop()
        -- Cease rendering the MOAI layers
        for layer in *C.layers
            MOAISim.removeRenderPass(layer)

    -- Game step function
    C.step = () ->
        for inst in *C.instances
            inst\step(C)
        -- Synchronize data to the subsystems
        for inst in *C.instances
            inst\update(C)
        -- Step the subsystems
        C.collision_world\step()
        C.rvo_world\step()

    -- Add the UI threads for a typical game
    append C.threads, main_thread C
    append C.threads, ui_ingame_scroll C
    append C.threads, ui_ingame_select C

    return C

return {:create}