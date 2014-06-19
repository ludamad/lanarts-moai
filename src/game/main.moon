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
	-- (require 'core.network.session').main()
	MOAISim.openWindow "Lanarts", w,h

	rng = mtwist.create(1)--os.time())
	core = modules.load "core"
	tilemap = modules.get_level("start").generator(rng)

    glevel = require 'game.level'
    level = glevel.create_level_state(rng, tilemap)
    G = glevel.create_game_state(level, w, h)
	thread = G.start()

main()