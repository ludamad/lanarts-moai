-------------------------------------------------------------------------------
-- Game state class
-------------------------------------------------------------------------------

import Map from require "levels"

import TextEditBox from require "interface"
import ErrorReporting from require "system"
import BuildingObject from require "objects"
import get_texture, get_json from require "resources"

user_io = require "user_io"

-------------------------------------------------------------------------------
-- Game setup
-------------------------------------------------------------------------------

charcodes = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 .,/;!?()&/-'

font = with MOAIFont.new()
    \loadFromTTF('resources/LiberationMono-Regular.ttf', charcodes, 120, 72)

setup_game = () ->
    w, h = 800,600
    if MOAIEnvironment.osBrand == "Android" or MOAIEnvironment.osBrand == "iOS" 
       w, h = 320,480  

    MOAISim.openWindow("Lanarts", w,h)

	camera = MOAICamera2D.new()
	cx, cy = 128,128
	camera\setLoc(cx,cy)

    map = with Map.create()
        \add_obj BuildingObject.create(32, 32)
        -- Set up this map for drawing:
        \register with MOAIViewport.new()
             \setSize(w,h)
             \setScale(w,h), 
            camera

	with MOAIThread.new()
		\run () ->
			mX,mY = user_io.mouse_xy()
			dragging = false
			while true
				coroutine.yield()
				-- Handle dragging for scroll:
				if user_io.mouse_right_pressed()
					dragging = true
				if user_io.mouse_right_released()
					dragging = false
				if dragging and user_io.mouse_right_down() 
					newMX,newMY = user_io.mouse_xy()
					prevX, prevY = camera\getLoc()
					camera\setLoc(prevX + (mX - newMX), prevY - (mY - newMY))

				mX,mY = user_io.mouse_xy()

				map\step()
-------------------------------------------------------------------------------
-- Tiled-loading functions
-------------------------------------------------------------------------------

TiledMap = typedef [[
    tile_width, tile_height : int 
    layers, tile_sets : list
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
    return TiledMap.create(json.tilewidth, json.tileheight, layers, tile_sets)

-- Setup up layers from a Tiled description.
-- Returns a table with the components, with a function
-- to set up and one to tear-down the layers.

load_tiled_json = (path, vieww, viewh) ->
    map = parse_tiled_json path 

    C = {} -- The components

    C.camera = with MOAICamera2D.new()
        \setLoc(0,0)--map.tile_width / 2 * 64, map.tile_height /2 * 32)
    C.viewport = with MOAIViewport.new()
        \setSize(vieww, viewh)
        \setScale(vieww, viewh)

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
                    \setRect -tilew/2, -tileh/2, 
                        tilew/2, tileh/2

                assert(gidmap[gid] == nil, "Tile GID overlap, logic error!")
                gidmap[gid] = quad
                gid = gid + 1

    -- The MOAI layers to accumulate
    C.layers = {}

    -- Create the MOAI layers from the Tiled layers
    for lay in *map.layers
        w, h = lay.width, lay.height
        dx, dy = lay.x, lay.y

        layer = with MOAILayer2D.new()
            \setCamera(C.camera) -- All layers use the same camera
            \setViewport(C.viewport) -- All layers use the same viewport
            \setSortMode(MOAILayer.SORT_ISO)

        for y=1,h
            for x=1,w
                i = (y-1) * w + x
                gid = lay.data[i]
                if gid > 0 -- Is something here?
                    -- Create the prop
                    px,py = (x-.5)*64,(y-.5)*32
                    layer\insertProp with MOAIProp2D.new()
                        \setDeck(gidmap[gid])
                        \setLoc(px,py)
                    print("Going",px,py)

        append C.layers, layer
    -- Setup function
    C.setup = () -> 
        top_layer = C.layers[#C.layers]

        -- Run a MOAIThread for scrolling by mouse
        text_box = with MOAITextBox.new()
            \setFont( font )
            \setTextSize( 24 )
            \setString( "" )
            \setAlignment( MOAITextBox.CENTER_JUSTIFY, MOAITextBox.CENTER_JUSTIFY )

        top_layer\insertProp(text_box)
        MOAIThread.new()\run () ->
           mX,mY = user_io.mouse_xy()
           dragging = false
           while true
               coroutine.yield()
               -- Handle dragging for scroll:
               if user_io.mouse_right_pressed()
                   dragging = true
               if user_io.mouse_right_released()
                   dragging = false
               if dragging and user_io.mouse_right_down() 
                   newMX,newMY = user_io.mouse_xy()
                   prevX, prevY = C.camera\getLoc()
                   C.camera\setLoc(prevX + (mX - newMX), prevY - (mY - newMY))

               mX,mY = user_io.mouse_xy()
               cX, cY = C.camera\getLoc()

               text_box\setString(mX .. ", " .. mY)
               text_box\setLoc(mX + cX, mY + cY)
               text_box\setColor(1,1,1)

        print "test"
         -- Begin rendering the MOAI layers
        for layer in *C.layers
           MOAISim.pushRenderPass(layer)

    -- Tear-down function
    C.teardown = () -> 
        -- Cease rendering the MOAI layers
        for layer in *C.layers
            MOAISim.removeRenderPass(layer)

    return C

setup_game2 = () ->
    w, h = 800,600

    if MOAIEnvironment.osBrand == "Android" or MOAIEnvironment.osBrand == "iOS" 
       w, h = 320,480  

    MOAISim.openWindow "Citymode", w,h

    camera = with MOAICamera2D.new()
        \setNearPlane(10000)
        \setFarPlane(-10000)
        \setRot(45, 0)

    layer = with MOAILayer2D.new()
        \setCamera( camera )
        \setViewport with MOAIViewport.new()
            \setSize(w,h)
            \setScale(w,h)

    MOAISim.pushRenderPass(layer)

    tileDeck = with MOAITileDeck2D.new()
        \setTexture( get_texture "diamond-tiles.png" )
        \setSize( 4, 4 )
        \setUVQuad( 0, 0.5, 0.5, 0, 0, -0.5, -0.5, 0 )

    map = parse_tiled_json "iso-test.json"

    layer\insertProp with MOAIProp2D.new()
        \setDeck( tileDeck )
        \setPiv( 256, 256 )
        \setScl( 1, -1 )
        \setGrid with MOAIGrid.new()
            \setSize(8, 8, 64, 64)
            \setRow( 1, 	0x01, 0x02, 0x03, 0x04, 0x03, 0x03, 0x03, 0x03 )
            \setRow( 2, 	0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03 )
            \setRow( 3, 	0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03 )
            \setRow( 4, 	0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03 )
            \setRow( 5, 	0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03 )
            \setRow( 6, 	0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03 )
            \setRow( 7, 	0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03 )
            \setRow( 8, 	0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03 )

setup_game3 = () ->
    w, h = 800,600

    if MOAIEnvironment.osBrand == "Android" or MOAIEnvironment.osBrand == "iOS" 
       w, h = 320,480  

    MOAISim.openWindow "Citymode", w,h

    -- The components of the map
    C = load_tiled_json "iso-test.json", w, h
    -- Push the layers for rendering
    C.setup()

    if user_io.key_pressed("K_ESCAPE")
        C.teardown()


setup_game3()

--inspect()

