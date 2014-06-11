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

-------------------------------------------------------------------------------
-- Set up the camera & viewport
-------------------------------------------------------------------------------
setup_view = (C) ->
    {w,h} = C.model.size
    tw, th = C.tile_width, C.tile_height

    cx, cy = w * th / 2, h * tw / 2
    C.camera = with MOAICamera2D.new()
        \setLoc(cx,cy)
    C.viewport = with MOAIViewport.new()
        \setSize(C.vieww, C.viewh)
        \setScale(C.vieww, -C.viewh)

-------------------------------------------------------------------------------
-- Set up the layers for the map
-------------------------------------------------------------------------------
setup_layers = (C) ->
    {w, h} = C.model.size

    -- Create the tile layers
    for y=1,h do for x=1,w do 
       -- Note: Model access is 0-based (for now! TODO)
       {:flags, :content, :group} = C.model\get {x-1, y-1}

    -- Add the UI layer, which is sorted by priority (the default sort mode):
    C.ui_layer = with MOAILayer2D.new()
            \setCamera(C.camera) -- All layers use the same camera
            \setViewport(C.viewport) -- All layers use the same viewport


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

create = (model, vieww, viewh) ->
    -- Initialize our components object
    C = { :model, :vieww, :viewh }

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
        setup_view(C)
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