user_io = require "user_io"
modules = require "game.modules"
mtwist = require 'mtwist'

-------------------------------------------------------------------------------
-- Game setup
-------------------------------------------------------------------------------

_G._SETTINGS = require "settings"

{w, h} = _SETTINGS.window_size

-- Global RNG for view randomness
_G._RNG = mtwist.create(os.time())

main = () ->
	MOAISim.setStep(1 / _SETTINGS.frames_per_second)
	-- (require 'core.network.session').main()
	MOAISim.openWindow "Lanarts", w,h
    gl_set_vsync(false)

	rng = mtwist.create(1)--os.time())
	core = modules.load "core"
	tilemap = modules.get_level("start").generator(rng)

    glevel = require 'game.level'

    G = glevel.create_game_state(w, h)
    L = glevel.create_level_state(G, rng, tilemap)
    V = glevel.create_level_view(L, w, h)

    G.set_level_view(V)

	thread = G.start()

main()
