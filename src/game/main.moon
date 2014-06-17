user_io = require "user_io"
modules = require "game.modules"

-------------------------------------------------------------------------------
-- Game setup
-------------------------------------------------------------------------------

_G._SETTINGS = require "settings"

{w, h} = _SETTINGS.window_size

MOAISim.openWindow "Lanarts", w,h

main = () ->
	rng = (require 'mtwist').create(os.time())
	core = modules.load "core"
	model = modules.get_level("start").generator(rng)
    level = require 'game.level'
	C = level.create(rng, model, w, h)
	thread = C.start()

main()