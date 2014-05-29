import Map from require "levels"

import TextEditBox from require "interface"
import ErrorReporting from require "system"
import BuildingObject from require "objects"
import get_texture, get_json from require "resources"
import ui_ingame_scroll, ui_ingame_select from require "ui"

user_io = require "user_io"

-------------------------------------------------------------------------------
-- Tiled-loading structures
-------------------------------------------------------------------------------

TiledMap = typedef [[
    tile_width, tile_height : int 
    layers, tile_sets : list
    iso_width, iso_height : int
]]

TiledLayer = typedef [[
    name : string
    width, height : int 
    x, y : int
    data : list
]]

TiledTileSet = typedef [[
    name : string
    path : string
    first_id : int
    image_width, image_height : int
    tile_width, tile_height : int 
]]

-------------------------------------------------------------------------------
-- Tiled-loading functions
-------------------------------------------------------------------------------

-- Return Level object, parsed from Tiled map
parse_tiled_json = (path) ->
    -- Parse the JSON representation of the Tiled map
    json = get_json path

    -- Parse the tile sets from the Tiled map
    tile_sets = {} 
    for tset in *json.tilesets
        append tile_sets,
            TiledTileSet.create tset.name, tset.image, 
                tset.firstgid,
                tset.imagewidth, tset.imageheight,
                tset.tilewidth, tset.tileheight

    -- Parse the tile layers from the Tiled map
    layers = {} 
    for lay in *json.layers
        append layers,
            TiledLayer.create lay.name, 
                lay.width, lay.height,
                lay.x, lay.y,
                lay.data

    -- Parse the top-level attributes
    -- Hardcode the width and height of the isometric placement, for now
    return TiledMap.create(json.tilewidth, json.tileheight, layers, tile_sets, 32, 16)

-- Setup up layers from a Tiled description.
-- Returns a table with the components, with a function
-- to set up and one to tear-down the layers.

load_tiled_json = (path, vieww, viewh) ->
    map = parse_tiled_json path 

    C = { :vieww, :viewh } -- The components

    cx, cy = map.tile_width * map.iso_height / 2, map.tile_height * map.iso_width / 2
    C.camera = with MOAICamera2D.new()
        \setLoc(-cx, cy)
    C.viewport = with MOAIViewport.new()
        \setSize(vieww, viewh)
        \setScale(vieww, -viewh)

    -- Create a conversion map from Tiled GID to deck
    gidmap = {}

    -- Create a map of objects to base construction off of
    for tset in *map.tile_sets

        -- Texture for tile image
        texture = get_texture(tset.path)

        -- Width and height of texture
        w, h = tset.image_width,tset.image_height
        -- Width and height in tiles
        tilew, tileh = tset.tile_width,tset.tile_height
        -- Width and height of each individual tile
        tw, th = (w / tilew), (h / tileh)

        -- Counter for each ID
        gid = tset.first_id

        for y=1,th 
            for x=1,tw 
                x1, x2 = (x-1) * 1 / tw, (x) * 1 / tw
                y1, y2 = (y-1) * 1 / th, (y) * 1 / th
                quad = with MOAIGfxQuad2D.new()
                    \setTexture texture
                    -- Center tile on origin:
                    \setUVQuad x1, y1, 
                        x2, y1, 
                        x2, y2,
                        x1, y2
                    \setRect -tilew/2, tileh/2, 
                        tilew/2, -tileh/2

                assert(gidmap[gid] == nil, "Tile GID overlap, logic error!")
                gidmap[gid] = quad
                gid = gid + 1

    -- Function to convert a tile location to a real location
    C.tile_xy_to_real = (x, y) -> 
        return (x - y - .5)*map.iso_width, (x + y - .5)*map.iso_height

    -- Function to convert a real location to a tile location
    -- Returns 'nil' if not possible
    C.real_xy_to_tile = (rx, ry) -> 
        -- Solve the inverse function of above
        x_sub_y = rx / map.iso_width + .5
        x_plus_y = ry / map.iso_height + .5
        -- Calculate x and y, return if within acceptable bounds
        x = (x_sub_y + x_plus_y) / 2
        y = (x_plus_y - x)
        -- Floor
        x, y = math.floor(x), math.floor(y)
        -- Are we in acceptable bounds?
        if (x >= 1 and x <= map.tile_width) and (y >= 1 and y <= map.tile_height)
            return x, y
        -- Otherwise, return nils
        return nil, nil
            
    -- Find the nearest multiple of the tile size
    C.real_xy_snap = (rx, ry) -> 
        rx = math.floor(rx / map.iso_width) * map.iso_width
        ry = math.floor(ry / map.iso_height) * map.iso_height
        return rx, ry

    -- The MOAI layers to accumulate
    C.layers = {}
    -- The UI or animation threads to accumulate
    C.threads = {}

    -- Create the MOAI layers from the Tiled layers
    for lay in *map.layers
        w, h = lay.width, lay.height
        dx, dy = lay.x, lay.y

        layer = with MOAILayer2D.new()
            \setCamera(C.camera) -- All layers use the same camera
            \setViewport(C.viewport) -- All layers use the same viewport
            \setSortMode(MOAILayer.SORT_Y_ASCENDING)

        for y=1,h
            for x=1,w
                i = (y-1) * w + x
                gid = lay.data[i]
                if gid > 0 -- Is something here?
                    -- Create the prop
                    layer\insertProp with MOAIProp2D.new()
                        \setDeck(gidmap[gid])
                        \setLoc(C.tile_xy_to_real(x, y))

        append C.layers, layer

    -- Add the UI threads for a typical game
    append C.threads, ui_ingame_scroll C
    append C.threads, ui_ingame_select C
    pretty("threads", C.threads)

    -- Add the UI layer, which is sorted by priority (the default sort mode):
    C.ui_layer = with MOAILayer2D.new()
            \setCamera(C.camera) -- All layers use the same camera
            \setViewport(C.viewport) -- All layers use the same viewport

    append C.layers, C.ui_layer

    -- Setup function
    C.start = () -> 
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

    return C

return { :parse_tiled_json, :load_tiled_json }
