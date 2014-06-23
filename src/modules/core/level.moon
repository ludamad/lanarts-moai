-------------------------------------------------------------------------------
-- Standard requires from Lanarts engine 
-------------------------------------------------------------------------------

BoolGrid, mtwist = require "BoolGrid", require "mtwist" 

import FloodFillPaths, GameInstSet, GameTiles, GameView, util, TileMap, RVOWorld
    from require "core"

-------------------------------------------------------------------------------
-- Other requires
-------------------------------------------------------------------------------

import create_thread from require 'core.util'
import ui_ingame_scroll, ui_ingame_select from require "core.ui"

import camera, networking, util_draw from require "core"

json = require 'json'
modules = require 'modules'
user_io = require 'user_io'
res = require 'resources'
serialization = require 'core.serialization'

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

create_level_state = (G, rng, tilemap) ->
    L = {gamestate: G, :rng, :tilemap }

    -- Set up level dimensions
    -- Hardcoded for now:
    L.tile_width,L.tile_height = 32,32

    {L.tilemap_width, L.tilemap_height} = L.tilemap.size
    L.pix_width, L.pix_height = (L.tile_width*L.tilemap_width), (L.tile_height*L.tilemap_height)

    -- Set up level state
    (require 'core.level_state').setup_level_state(L)

    return L

create_level_view = (level, cameraw, camerah) ->
    V = {gamestate: level.gamestate, :level, :cameraw, :camerah}

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

    level_logic = (require 'core.level_logic')

    setup_camera(V)
    setup_tile_layers(V)
    setup_overlay_layers(V)

    V.draw = () ->
        level_logic.draw(V)

    script_prop = (require 'core.util_draw').setup_script_prop(V.ui_layer, V.draw)

    -- Note: uses script_prop above
    V.pre_draw = () ->
        script_prop\setLoc(V.camera\getLoc())
        level_logic.pre_draw(V)

    -- Setup function
    V.start = () -> 
         -- Begin rendering the MOAI layers
        for layer in *V.layers
           MOAISim.pushRenderPass(layer)

        level_logic.start(V)

    V.stop = () ->
        -- Cease rendering the MOAI layers
        for layer in *V.layers
            MOAISim.removeRenderPass(layer)

    V.clear = () ->
        for layer in *V.layers
            layer\clear()

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
        G.handle_io()

create_menu_view = (G, w,h, continue_callback) ->
    -- We 'cheat' with our menu level view, just point to same object
    V = {}
    V.level = V
    V.layer = with MOAILayer2D.new()
        \setViewport with MOAIViewport.new()
            \setSize(w,h)
            \setScale(w,-h)

    V.step = () -> nil

    menu_style = with MOAITextStyle.new()
        \setColor 1,1,0 -- Yellow
        \setFont (res.get_font 'Gudea-Regular.ttf')
        \setSize 29

    V.pre_draw = () ->
        util_draw.reset_draw_cache()
        info = "There are #{#G.players} players."
        if G.gametype == 'client'
            info ..= "\nWaiting for the server..."
        else 
            info ..= "\nPress ENTER to continue."

        util_draw.draw_text(V.layer, menu_style, info)
        if G.gametype == 'server' and (user_io.key_pressed("K_ENTER") or user_io.key_pressed("K_SPACE"))
            G.message_send type: "GameStart"
            continue_callback()
        else if G.gametype == 'client' and G.handle_message_type "GameStart"
            continue_callback()

    V.handle_io = () -> nil

    -- Setup function
    V.start = () -> MOAISim.pushRenderPass(V.layer)
    V.stop = () -> 
        V.layer\clear()
        MOAISim.removeRenderPass(V.layer)

    return V

-------------------------------------------------------------------------------
-- Returns a 'components object' that holds the various parts of the 
-- level's state.
-- The 'tilemap' is created by the core.TileMap module.
-------------------------------------------------------------------------------

create_game_state = () ->
    G = {}

    G.next_player_id = 1
    G.players = {}
    -- Player actions, with associated step:
    G.player_action_queue = {}
    -- Any unhandled messages:
    G.network_message_queue = {}

    G.gametype = _SETTINGS.gametype

    require('@network_logic').setup_network_functions(G)

    -- Based on game type above, and _SETTINGS object for IP (for client) & port (for both client & server)
    G.start_connection()

    -- Generally only used by the server:
    G.add_new_player = (name, is_controlled, peer=nil) ->
        assert(G.gametype == 'server', "Should only be called by the server!")
        -- Peer is remembered for servers
        append G.players, {id_player: G.next_player_id, player_name: name, :is_controlled, :peer}
        G.next_player_id += 1

    G.is_local_player = (obj) ->
        player = G.players[obj.id_player]
        return player.is_controlled

    G.player_name = (obj) ->
        player = G.players[obj.id_player]
        return player.player_name

    G.change_view = (V) ->
        if G.level_view then
            G.level_view\stop()
        G.level_view = V
        G.level = V.level
        G.level_view.start()

    -- Setup function
    G.start = () -> 
        G.level_view.start()

        thread = main_thread(G)
        thread.start()
        return thread

    -- Tear-down function
    G.stop = () -> 
        G.level_view.stop()
        for thread in *G.threads
            thread.stop()

    -- Game step function
    G.step = () -> 
        if G.connection 
            G.connection\poll()
            for msg in *G.connection\grab_messages()
                G.handle_network_event(msg)

        G.level.step()
        G.level_view.pre_draw()

    G.handle_io = () ->
        if user_io.key_down "K_Q"
            serialization.push_state(G.level)

        if user_io.key_down "K_E"
            serialization.pop_state(G.level)

        G.level.handle_io()

    G.pre_draw = () -> G.level_view.pre_draw()

        -- print "Pre-draw took ", (MOAISim.getDeviceTime() - before) * 1000, 'ms'

    return G

return {:create_game_state, :create_level_state, :create_menu_view, :create_level_view}
