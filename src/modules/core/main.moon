user_io = require "user_io"
modules = require "modules"
mtwist = require 'mtwist'
util = require 'core.util'

import object_types from require 'core'

-------------------------------------------------------------------------------
-- Game setup
-------------------------------------------------------------------------------

_G._SETTINGS = require "settings"

{w, h} = _SETTINGS.window_size

-- Global RNG for view randomness
_G._RNG = mtwist.create(os.time())

_spawn_players = (G, L) ->
    import random_square_spawn_object from require '@util_generate'

    for i=1,#G.players
        random_square_spawn_object L, (px, py) ->
            object_types.Player.create L, {
                x: px*32+16
                y: py*32+16
                radius: 10
                solid: true
                id_player: i
                speed: 4
            }

main = () ->

	MOAISim.setStep(1 / _SETTINGS.frames_per_second)
	-- (require 'core.network.session').main()
	MOAISim.openWindow "Lanarts", w,h
    gl_set_vsync(false)

	-- (require 'mainmenu.Menus').start_menu_show()

	rng = mtwist.create(1)--os.time())
	require '@define_data'

    glevel = require 'core.level'

    G = glevel.create_game_state()

    _start_game = () ->
		tilemap = modules.get_level("start").generator(G, rng)

	    L = glevel.create_level_state(G, rng, tilemap)
	    _spawn_players(G, L)
	    V = glevel.create_level_view(L, w, h)

	    G.change_view(V)

	if G.gametype == 'server' or G.gametype == 'single_player'
		G.add_new_player(_SETTINGS.player_name, true)
    G.change_view(glevel.create_menu_view(G, w,h, _start_game))

	thread = G.start()

main()
