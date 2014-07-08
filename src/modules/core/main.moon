-- Must load settings early because it can be referenced in files
_G._SETTINGS = require "settings"

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
import MainMenu from require "ui.menus"

import thread_create from require 'core.util'

main = () ->
    MOAISim.setStep(1 / _SETTINGS.frames_per_second)
    Display.display_setup()
    thread = thread_create () -> profile () ->
        MainMenu.menu_main(do_nothing, do_nothing, do_nothing, do_nothing)
    thread.start()

main()
