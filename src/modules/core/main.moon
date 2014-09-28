-- Define data loading functions
logI("Loading core.data")
require "@data"

-- Must load data early because it can be referenced in files
logI("Starting loading core.define_data")
require '@define_data'
logI("Finished loading core.define_data")

user_io = require "user_io"
modules = require "core.data"
mtwist = require 'mtwist'
tablediff = require 'tablediff'
util = require 'core.util'

statsystem = require "statsystem"
import map_object_types, game_state, map_state, map_view from require 'core'

import Display from require "ui"
import MenuMain, MenuSettings, MenuCharGen from require "ui.menus"

import thread_create from require 'core.util'

-------------------------------------------------------------------------------
-- Game setup
-------------------------------------------------------------------------------

{w, h} = _SETTINGS.window_size

-- Global RNG for view randomness
_G._RNG = mtwist.create(os.time())

_spawn_players = (G, M, stat_components) ->
    import random_square_spawn_object from require '@util_generate'

    for i=1,#G.players
        random_square_spawn_object M, (px, py) ->
            map_object_types.Player.create M, {
                name: G.players[i].player_name
                x: px*32+16
                y: py*32+16
                radius: 10
                race: statsystem.races[stat_components.race]
                class: statsystem.classes[stat_components.class]
                class_args: stat_components.class_args
                solid: true
                id_player: i
                speed: 6
            }

-- For the seed, try to mix CPU time and wall-clock time without overlapping the bits.
-- Also, scale os.clock values as they can be small decimal values.
make_local_seed = () -> math.floor(os.time() * (2^12) + os.clock() * (2^6))

shutdown_hook = (G) -> () ->
    logI "shutdown_hook called"
    if G.net_handler
        G.net_handler\disconnect()

pregame_setup_and_join_screen = (controller, continue_callback) ->
    logI("pregame_setup_and_join_screen")

    res = require "resources"
    game_actions = require "@game_actions"

    G = game_state.create_game_state()
    SetLanartsShutdownHook shutdown_hook(G)

    if G.gametype == 'server' or G.gametype == 'single_player'
        G.add_new_player(_SETTINGS.player_name, true)

    -- Are we in single player? Don't bother the player with this screen
    if G.gametype == 'single_player'
        logI("create_menu_view: single player detected")

        game_actions.setup_action_state(G)
        -- We use the local seed as the server, or during single-player.
        -- If we are a client, we use the seed provided by the server during the handshake.
        G.initialize_rng(make_local_seed())
        continue_callback(G)
        return

    -- Grab the required fonts & sprites
    logo = res.get_texture 'LANARTS.png'
    logo_back = res.get_texture 'LANARTS-transparent.png'
    font = res.get_font 'Gudea-Regular.ttf'

    -- Clear the previous display functions & objects
    Display.display_setup()
    w,h = Display.display_size()

    client_starting = false
    server_starting = false

    net_send = (type, data = nil) ->
        G.net_handler\send_message {:type, :data}
    net_recv = (type) -> G.net_handler\check_message_all(type)
    -- Set global synchronization-test function
    _G.logS = (label, data) ->
        payload = MOAIJsonParser.encode data
        msg_identifier = "DebugSync(#{label})"
        net_send msg_identifier, payload
        while true
            if G.net_handler\check_message("Restart", false) or G.net_handler\check_message("ByeBye", false)
                break
            msgs = net_recv msg_identifier
            if msgs
                for msg in *msgs
                    if payload ~= msg.data
                        diff = tablediff.diff(MOAIJsonParser.decode(payload), MOAIJsonParser.decode(msg.data))
                        print "While comparing '#{label}' ..."
                        print "Synchronization failure! Diff was:"
                        pretty_print diff
                        error("Exiting due to sync failure...")
                break
            G.net_handler\poll(1)

    -- At the beginning, there is a somewhat involved handshake:
    -- Server sends ServerRequestStartGame, sets up action state
    --  -> Client receives ServerRequestStartGame, sends ClientAckStartGame, sets up action state
    --   -> Server receives ClientAckStartGame from _all_ clients, sends ServerConfirmStartGame, starts the game
    --    -> Client receives ServerConfirmStartGame, starts the game
    --
    -- Benefits: This handshake is completely defined within this block, and 
    -- guarantees that everyone is set up ready to receive game actions!
    Display.display_add_draw_func () ->
        G.net_handler\poll()
        info = "There are #{#G.players} players."
        if G.gametype == 'client'
            info ..= "\nWaiting for the server..."
        else 
            info ..= "\nPress ENTER to continue."

        Display.drawTextCenter(font, info, w/2, h/2, Display.COL_YELLOW, 29)

        if client_starting
            msgs = net_recv("ServerConfirmStartGame")
            if msgs
                assert #msgs == 1
                G.initialize_rng(msgs[1].data)
                logI("pregame_setup_and_join_screen: Client gets seed", msgs[1].data)
                continue_callback(G)
        elseif server_starting
            if net_recv("ClientAckStartGame")
                -- Create a local seed, and share it with the clients:
                local_seed = make_local_seed()
                net_send("ServerConfirmStartGame", local_seed)
                logI("pregame_setup_and_join_screen: Server sends seed", local_seed)
                G.initialize_rng(local_seed)
                continue_callback(G)
        elseif G.gametype == 'server' and (user_io.key_pressed("K_ENTER") or user_io.key_pressed("K_SPACE"))
            server_starting = true
            game_actions.setup_action_state(G)
            net_send("ServerRequestStartGame")
        elseif G.gametype == 'client' and net_recv("ServerRequestStartGame")
            client_starting = true
            game_actions.setup_action_state(G)
            net_send("ClientAckStartGame")

    -- Step until our handshake in the above function has completed.
    while controller\is_active()
        coroutine.yield()

-- After all players have connected
-- TODO Allow for players to hot-join
start_game = (G, stat_components, on_death) ->
    logI "main::start_game"
    Display.display_setup()
    MOAISim.setStep(1 / _SETTINGS.frames_per_second)

    -- Sanity check: First random number generated should be the same for all
    logS("rng check", G.rng\randomf())

    logI("main::start_game: after clear_game_data")
    tilemap = modules.get_map("start").generator(G, G.rng, require("@generate_data").SMALL)

    M = map_state.create_map_state(G, 1, G.rng, tilemap)
    tilemap\generate_objects(M)
    append G.maps, M

    logI("main::start_game: Map created")
    map_state.map_set(M)
    _spawn_players(G, M, stat_components)
    logI("main::start_game: players & monsters spawned")
    V = map_view.create_map_view(M, w, h)

    logI("main::start_game: changing to game view")
    G.change_view(V)

    logI("main::start_game: starting game")
    -- Start the game
    G.start(on_death)

-- Navigates between levels and menus
SceneController = newtype {
    init: () =>
        @_is_active = true
        -- Closure to call next
        @_next = false
    set_next: (next) =>
        assert @_is_active, "Can't queue twice!"
        assert type(next) == 'function'
        @_is_active = false
        @_next = next
    perform_next: () =>
    	next = @_next
    	@_next = false
    	@_is_active = true
    	next()
    is_active: () => 
    	return @_is_active
}

main = () ->
    logI("Main starting")
    MOAISim.setStep(1 / _SETTINGS.frames_per_second)
    Display.display_setup()
    SC = SceneController.create()

    -- nextf:
    -- Helper for creating button navigation logic
    -- Returns a function that captures any arguments passed
    -- and queues a menu state transition that calls 'f'.
    --
    -- 'f' is expected to be a pseudo-thread -- a function that yields until
    -- it the scene controller is inactive.
    nextf = (f) -> (...) ->
        -- Capture any arguments passed
        args = {...}
        SC\set_next(() -> f(unpack(args)))

    io_thread = thread_create () -> while true 
        coroutine.yield()
        -- Ensure that we only consider keys for a single step in the key query methods
        user_io.clear_keys_for_step()

    -- The main thread performing the menu/game traversal
    main_thread = thread_create () ->
        -- Foward declare the 'transitions'
        local mmain, msettings, mchargen, mpregame, mstartgame
        -- Set up the 'transitions' between the menus -- functions that initiate the menu
        mmain = nextf ()     -> MenuMain.start(SC, msettings, do_nothing, do_nothing) 
        msettings = nextf () -> MenuSettings.start(SC, mmain, mchargen)
        mchargen = nextf ()  -> MenuCharGen.start(SC, msettings, mpregame)
        mpregame = nextf (stat_components) -> 
            pregame_setup_and_join_screen SC, (G) -> 
                logI("finished pregame_setup_and_join_screen")
                mstartgame(G, stat_components)
        mstartgame = nextf (G, stat_components) -> 
            start_game(G, stat_components, mchargen)
            G.clear_game_data()
            -- Have we restarted?
            mstartgame(G, stat_components)
        -- Set up first menu
        if os.getenv("TEST_ARCHER")
            mpregame {class: "Archer", race: "Human", class_args: {}}
        else
    	   mchargen()
        -- Loop through the menu state machine (SceneController)
        -- For these purposes, the game itself is considered a 'menu'
        while true
           -- Should yield:
    	   SC\perform_next()

    -- Start the threads that perform the real work
    main_thread.start()
    -- Clear the io state as the last action
    io_thread.start()

if os.getenv "newstats"
    (require "newstats.tests").main()
else
    main()
