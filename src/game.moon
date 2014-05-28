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

