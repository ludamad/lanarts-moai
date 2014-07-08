-------------------------------------------------------------------------------
-- Standard requires from Lanarts engine 
-------------------------------------------------------------------------------

BoolGrid, mtwist = require "BoolGrid", require "mtwist" 

import FloodFillPaths, GameInstSet, GameTiles, GameView, util, TileMap, RVOWorld, game_actions,
    ui_minimap, menu_start from require "core"

-------------------------------------------------------------------------------
-- Other requires
-------------------------------------------------------------------------------

import ui_ingame_scroll, ui_ingame_select from require "core.ui"
import ui_sidebar from require "core"

import camera, util_draw from require "core"

json = require 'json'
modules = require 'core.data'
user_io = require 'user_io'
res = require 'resources'
serialization = require 'core.serialization'

-------------------------------------------------------------------------------
-- Set up the camera & viewport
-------------------------------------------------------------------------------
setup_camera = (V) ->
    w,h = V.map.tilemap_width, V.map.tilemap_height
    tw, th = V.map.tile_width, V.map.tile_height

    cx, cy = w * tw / 2, h * th / 2
    assert(not V.camera and not V.viewport, "Double call to setup_view!")
    V.camera = with MOAICamera2D.new()
        \setLoc(cx,cy)
    V.viewport = with MOAIViewport.new()
        \setSize(V.cameraw - ui_sidebar.SIDEBAR_WIDTH, V.camerah)
        \setScale(V.cameraw - ui_sidebar.SIDEBAR_WIDTH, -V.camerah)

-------------------------------------------------------------------------------
-- Set up the layers for the map
-------------------------------------------------------------------------------
setup_tile_layers = (V) ->
    -- Map and tile dimensions
    w,h = V.map.tilemap_width, V.map.tilemap_height
    tw, th = V.map.tile_width, V.map.tile_height

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
        _set_xy(x, y, V.map.tilemap\get({x,y}).content)

    layer = V.add_layer()

    pretty("Props", props)
    -- Add all the different textures to the layer
    for p in *props do layer\insertProp(p)

setup_fov_layer = (V) ->
    w,h = V.map.tilemap_width, V.map.tilemap_height
    tw, th = V.map.tile_width, V.map.tile_height
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
    V.ui_layer = V.add_layer MOAICamera2D.new(), with MOAIViewport.new()
        \setOffset(-1, 1)
        \setSize(V.cameraw, V.camerah)
        \setScale(V.cameraw, -V.camerah)

    -- Helpers for layer management
    V.add_ui_prop = (prop) -> V.ui_layer\insertProp(prop)
    V.remove_ui_prop = (prop) -> V.ui_layer\removeProp(prop)
    V.add_object_prop = (prop) -> V.object_layer\insertProp(prop)
    V.remove_object_prop = (prop) -> V.object_layer\removeProp(prop)

-------------------------------------------------------------------------------
-- Create a map view
-------------------------------------------------------------------------------

create_map_view = (map, cameraw, camerah) ->
    V = {gamestate: map.gamestate, :map, :cameraw, :camerah}

    -- The MOAI layers to accumulate
    V.layers = {}
    -- The UI objects that run each step
    V.ui_components = {}

    -- Create and add a layer, sorted by priority (the default sort mode):
    V.add_layer = (camera = V.camera, viewport = V.viewport) -> 
        layer = with MOAILayer2D.new()
            \setCamera(camera) -- All layers use the same camera
            \setViewport(viewport) -- All layers use the same viewport
        append(V.layers, layer)
        return layer

    map_logic = (require 'core.map_logic')

    setup_camera(V)
    setup_tile_layers(V)
    setup_overlay_layers(V)

    V.draw = () ->
        map_logic.draw(V)

    script_prop = (require 'core.util_draw').setup_script_prop(V.object_layer, V.draw, V.map.pix_width, V.map.pix_height, 999999)

    -- Note: uses script_prop above
    V.pre_draw = () ->
        map_logic.pre_draw(V)

    -- Setup function
    V.start = () -> 
         -- Begin rendering the MOAI layers
        for layer in *V.layers
           MOAISim.pushRenderPass(layer)

        map_logic.start(V)

    V.stop = () ->
        -- Cease rendering the MOAI layers
        for layer in *V.layers
            MOAISim.removeRenderPass(layer)

    V.clear = () ->
        for layer in *V.layers
            layer\clear()

    V.sidebar = ui_sidebar.sidebar_create(V)
    append V.ui_components, ui_ingame_scroll V
    append V.ui_components, ui_ingame_select V
    append V.ui_components, () -> V.sidebar\predraw()

    return V

-------------------------------------------------------------------------------
-- Create a menu view
-------------------------------------------------------------------------------

create_menu_view = (G, w,h, continue_callback) ->
    -- We 'cheat' with our menu map view, just point to same object
    V = {is_menu: true}
    V.map = V
    V.ui_layer = with MOAILayer2D.new()
        \setViewport with MOAIViewport.new()
            \setSize(w,h)
            \setScale(w,-h)

    V.step = () -> nil

    menu_style = with MOAITextStyle.new()
        \setColor 1,1,0 -- Yellow
        \setFont (res.get_font 'Gudea-Regular.ttf')
        \setSize 29

    client_starting = false
    server_starting = false

    net_send = (type) ->
        G.net_handler\send_message {:type}
    net_recv = (type) ->
        if G.gametype == 'server' 
            G.net_handler\unqueue_message_all(type)
        else
            G.net_handler\unqueue_message(type)

    V.pre_draw = () ->
        util_draw.reset_draw_cache()
        menu_start.draw_setup(V.ui_layer, w, h)
        info = "There are #{#G.players} players."
        if G.gametype == 'client'
            info ..= "\nWaiting for the server..."
        else 
            info ..= "\nPress ENTER to continue."

        -- At the beginning, there is a rather complicated handshake:
        -- Server sends ServerRequestStartGame, sets up action state
        --  -> Client receives ServerRequestStartGame, sends ClientAckStartGame, sets up action state
        --   -> Server receives ClientAckStartGame from _all_ clients, sends ServerConfirmStartGame, starts the game
        --    -> Client receives ServerConfirmStartGame, starts the game
        --
        -- Note though this handshake is completely contained within this block, and 
        -- this guarantees that everyone is set up ready to receive game actions!

        util_draw.put_text(V.ui_layer, menu_style, info, 0, 0, 0.5, 0.5, "center")

        if client_starting
            if net_recv("ServerConfirmStartGame")
                continue_callback()
        elseif server_starting
            if net_recv("ClientAckStartGame")
                net_send("ServerConfirmStartGame")
                continue_callback()
        elseif G.gametype == 'server' and (user_io.key_pressed("K_ENTER") or user_io.key_pressed("K_SPACE"))
            server_starting = true
            game_actions.setup_action_state(G)
            net_send("ServerRequestStartGame")
        elseif G.gametype == 'client' and net_recv("ServerRequestStartGame")
            client_starting = true
            game_actions.setup_action_state(G)
            net_send("ClientAckStartGame")
        elseif G.gametype == 'single_player'
            game_actions.setup_action_state(G)
            continue_callback()

    V.handle_io = () -> nil

    -- Setup function
    V.start = () -> MOAISim.pushRenderPass(V.ui_layer)
    V.stop = () -> 
        V.ui_layer\clear()
        MOAISim.removeRenderPass(V.ui_layer)

    return V

return {:create_menu_view, :create_map_view}