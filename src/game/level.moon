-------------------------------------------------------------------------------
-- Standard requires from Lanarts engine 
-------------------------------------------------------------------------------

BoolGrid, mtwist = require "BoolGrid", require "mtwist" 

import print_map, make_tunnel_oper, make_rectangle_criteria, make_rectangle_oper, place_instances
    from require "levels.map_util"

import FloodFillPaths, GameInstSet, GameTiles, GameView, util, mapgen
    from require "lanarts"

-------------------------------------------------------------------------------
-- Other requires
-------------------------------------------------------------------------------

import generate_test_model from require 'levels.generate'

import ui_ingame_scroll, ui_ingame_select from require "ui"


-------------------------------------------------------------------------------
-- Set up the camera & viewport
-------------------------------------------------------------------------------
setup_view = (C) ->
    cx, cy = map.tile_width * map.iso_height / 2, map.tile_height * map.iso_width / 2
    C.camera = with MOAICamera2D.new()
        \setLoc(cx,cy)
    C.viewport = with MOAIViewport.new()
        \setSize(vieww, viewh)
        \setScale(vieww, -viewh)

-------------------------------------------------------------------------------
-- Set up the layers for the map
-------------------------------------------------------------------------------
setup_layers = (C) ->

    -- Create the tile layers
    {w, h} = C.model.size
    for y=1,h do for x=1,w do 
       -- Note: Model access is 0-based (for now! TODO)
       {:flags, :content, :group} = map.model\get {x-1, y-1}
       print(x, y, content)

-------------------------------------------------------------------------------
-- Set up helper methods (closures, to be exact)
-------------------------------------------------------------------------------
setup_helpers = (C) ->
    {w, h} = C.map.size
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
        rx = math.floor(rx / map.iso_width) * map.iso_width
        ry = math.floor(ry / map.iso_height) * map.iso_height
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
    C.solidity, C.seethrough = util.extract_solidity_and_seethrough_maps(source_map)

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

return {:create}