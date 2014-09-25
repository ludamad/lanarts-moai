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
                speed: 4
            }

_spawn_monsters = (G, M) ->
    import random_square_spawn_object from require '@util_generate'

    for i=1,100
        random_square_spawn_object M, (px, py) ->
            map_object_types.NPC.create M, {
                x: px*32+16
                y: py*32+16
                type: "Giant Rat"
                radius: 10
                solid: true
                id_player: i
                speed: 4
            }

view_game = (stat_components, on_death) ->
    logI "main::view_game"
    Display.display_setup()
	MOAISim.setStep(1 / _SETTINGS.frames_per_second)

	rng = mtwist.create(os.time() * 999 + os.clock())

    G = game_state.create_game_state()

    if G.gametype == 'server' or G.gametype == 'single_player'
        G.add_new_player(_SETTINGS.player_name, true)

    _start_game = () ->
        logI("game start called")
		tilemap = modules.get_map("start").generator(G, rng)

	    M = map_state.create_map_state(G, 1, rng, tilemap)
        tilemap\generate_objects(M)
        append G.maps, M

        -- Set the current map as a global variable:
        _G._MAP = M

        logI("Map created")
        map_state.map_set(M)
	    _spawn_players(G, M, stat_components)
        _spawn_monsters(G, M)
        logI("players & monsters spawned")
	    V = map_view.create_map_view(M, w, h)

        logI("changing to game view")
	    G.change_view(V)

    G.change_view(map_view.create_menu_view(G, w,h, _start_game))

    -- Start the game
    G.start(on_death)

-- Navigates between levels and menus
SceneController = with newtype()
    .init = () =>
        @_is_active = true
        -- Closure to call next
        @_next = false
    .set_next = (next) =>
        assert @_is_active, "Can't queue twice!"
        assert type(next) == 'function'
        @_is_active = false
        @_next = next
    .perform_next = () =>
    	next = @_next
    	@_next = false
    	@_is_active = true
    	next()
    .is_active = () => 
    	return @_is_active

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
        local mmain, msettings, mchargen, mviewgame
        -- Set up the 'transitions' between the menus -- functions that initiate the menu
        mmain = nextf ()     -> MenuMain.start(SC, msettings, do_nothing, do_nothing) 
        msettings = nextf () -> MenuSettings.start(SC, mmain, mchargen)
        mchargen = nextf ()  -> MenuCharGen.start(SC, msettings, mviewgame)
        mviewgame = nextf (stat_components) -> 
            view_game(stat_components, mchargen)
            mviewgame(stat_components)
        -- Set up first menu
        if os.getenv("TEST_ARCHER")
            mviewgame {class: "Archer", race: "Human", class_args: {}}
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
