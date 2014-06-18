user_io = require "user_io"
modules = require "game.modules"

-------------------------------------------------------------------------------
-- Game setup
-------------------------------------------------------------------------------

_G._SETTINGS = require "settings"

{w, h} = _SETTINGS.window_size

main = () ->
	-- (require 'core.network.session').main()
	MOAISim.openWindow "Lanarts", w,h

	rng = (require 'mtwist').create(1)--os.time())
	core = modules.load "core"
	model = modules.get_level("start").generator(rng)
    level = require 'game.level'
	C = level.create(rng, model, w, h)
	thread = C.start()

main()