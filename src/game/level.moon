-------------------------------------------------------------------------------
-- Standard requires from Lanarts engine 
-------------------------------------------------------------------------------

BoolGrid, mtwist = require "BoolGrid", require "mtwist" 

import FloodFillPaths, GameInstSet, GameTiles, GameView, util, mapgen
    from require "lanarts"

-------------------------------------------------------------------------------
-- Other requires
-------------------------------------------------------------------------------

import ui_ingame_scroll, ui_ingame_select from require "game.ui"
modules = require 'game.modules'
res = require 'resources'

-------------------------------------------------------------------------------
-- Set up the camera & viewport
-------------------------------------------------------------------------------
setup_view = (C) ->
    {w,h} = C.model.size
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
    {w,h} = C.model.size
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
        --n = C.rng\random(1, #tilelist.tiles + 1)
        n = x % (#tilelist.tiles) + 1
        tile = tilelist.tiles[n]

        grid\setTile(x, y, tile.grid_id)

    for y=1,th do for x=1,tw 
        _set_xy(x, y, C.model\get({x,y}).content)

    layer = with MOAILayer2D.new()
        \setViewport(C.viewport)
        \setCamera(C.camera)

    pretty("Props", props)
    -- Add all the different textures to the layer
    for p in *props do layer\insertProp(p)

    append(C.layers, layer)

setup_layers = (C) ->
    {w, h} = C.model.size

    -- Create the tile layers
    for y=1,h do for x=1,w do 
       -- Note: Model access is 0-based (for now! TODO)
       {:flags, :content, :group} = C.model\get {x, y}

    -- Add the UI layer, which is sorted by priority (the default sort mode):
    C.ui_layer = with MOAILayer2D.new()
        \setCamera(C.camera) -- All layers use the same camera
        \setViewport(C.viewport) -- All layers use the same viewport
    append(C.layers, C.ui_layer)

    setup_tile_layers(C)

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

    -- The MOAI layers to accumulate
    C.layers = {}
    -- The UI or animation threads to accumulate
    C.threads = {}

    C.solidity, C.seethrough = util.extract_solidity_and_seethrough_maps(model)

    setup_view(C)
    setup_layers(C)
    setup_helpers(C)

    -- Setup function
    C.start = () -> 
        -- Set up the camera & viewport
        for thread in *C.threads
            thread.start()
         -- Begin rendering the MOAI layers
        for layer in *C.layers
           MOAISim.pushRenderPass(layer)

    -- Tear-down function

    C.stop = () -> 
        for thread in *C.threads
            thread.stop()
        -- Cease rendering the MOAI layers
        for layer in *C.layers
            MOAISim.removeRenderPass(layer)

    -- Add the UI threads for a typical game
    append C.threads, ui_ingame_scroll C
    append C.threads, ui_ingame_select C

    return C

return {:create}