-- Define data loading functions
require "@data"

-- Must load data early because it can be referenced in files
require '@define_data'

user_io = require "user_io"
modules = require "core.data"
mtwist = require 'mtwist'
util = require 'core.util'

import RaceType, ClassType from require "stats"
import map_object_types, game_state, map_state, map_view from require 'core'

-------------------------------------------------------------------------------
-- Game setup
-------------------------------------------------------------------------------

{w, h} = _SETTINGS.window_size

-- -- Global RNG for view randomness
-- _G._RNG = mtwist.create(os.time())

-- _spawn_players = (G, M) ->
--     import random_square_spawn_object from require '@util_generate'

--     for i=1,#G.players
--         random_square_spawn_object M, (px, py) ->
--             map_object_types.Player.create M, {
--                 name: G.players[i].player_name
--                 x: px*32+16
--                 y: py*32+16
--                 radius: 10
--                 race: RaceType.lookup "Orc"
--                 class: ClassType.lookup "Knight"
--                 solid: true
--                 id_player: i
--                 speed: 4
--             }

-- _spawn_monsters = (G, M) ->
--     import random_square_spawn_object from require '@util_generate'

--     for i=1,10
--         random_square_spawn_object M, (px, py) ->
--             map_object_types.NPC.create M, {
--                 x: px*32+16
--                 y: py*32+16
--                 type: "Giant Rat"
--                 radius: 10
--                 solid: true
--                 id_player: i
--                 speed: 4
--             }

-- main = () ->
-- 	MOAISim.setStep(1 / _SETTINGS.frames_per_second)
-- 	-- (require 'core.network.session').main()
-- 	MOAISim.openWindow "Lanarts", w,h
--     gl_set_vsync(false)

-- 	rng = mtwist.create(2)--os.time())

--     G = game_state.create_game_state()

--     if G.gametype == 'server' or G.gametype == 'single_player'
--         G.add_new_player(_SETTINGS.player_name, true)

--     _start_game = () ->
--         log("game start called")
-- 		tilemap = modules.get_map("start").generator(G, rng)

-- 	    M = map_state.create_map_state(G, 1, rng, tilemap)
--         append G.maps, M

--         -- Set the current map as a global variable:
--         _G._MAP = M
--         map_state.map_set(M)
-- 	    _spawn_players(G, M)
--         _spawn_monsters(G, M)
-- 	    V = map_view.create_map_view(M, w, h)

-- 	    G.change_view(V)

--     G.change_view(map_view.create_menu_view(G, w,h, _start_game))

-- 	thread = G.start()

import Display from require "ui"
import MenuMain, MenuSettings, MenuCharGen from require "ui.menus"

import thread_create from require 'core.util'

-- Navigates between levels and menus
SceneController = with newtype()
    .init = () =>
        @_is_active = true
        -- Closure to call next
        @_next = false
    .set_next = (next) =>
        assert @_is_active, "Can't queue twice!"
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
    MOAISim.setStep(1 / _SETTINGS.frames_per_second)
    Display.display_setup()
    SC = SceneController.create()

    -- Helpers for creating button navigation logic
    nextf = (f) -> (-> SC\set_next(f))

    io_thread = thread_create () -> while true 
        coroutine.yield()
        -- Ensure that we only consider keys for a single step in the key query methods
        user_io.clear_keys_for_step()

    -- The main thread performing the menu/game traversal
    main_thread = thread_create () ->
        -- Foward declare the 'transitions'
        local mmain, msettings, mchargen
        -- Set up the 'transitions' between the menus -- functions that initiate the menu
        mmain = nextf () ->     MenuMain.start(SC, msettings, do_nothing, do_nothing) 
        msettings = nextf () -> MenuSettings.start(SC, mmain, mchargen)
        mchargen = nextf () ->  MenuCharGen.start(SC, msettings, do_nothing)
        -- Set up first menu
    	mmain()
        -- Loop through the menu state machine (SceneController)
        -- For these purposes, the game itself is considered a 'menu'
        while true
           -- Should yield:
    	   SC\perform_next()

    -- Start the threads that perform the real work
    main_thread.start()
    -- Clear the io state as the last action
    io_thread.start()

main()
