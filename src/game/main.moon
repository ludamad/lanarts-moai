user_io = require "user_io"
modules = require "game.modules"

-------------------------------------------------------------------------------
-- Game setup
-------------------------------------------------------------------------------

w, h = 800,600

MOAISim.openWindow "Lanarts", w,h

main = () ->
	rng = (require 'mtwist').create(os.time())
	core = modules.load "core"
	model = modules.get_level("start").generator(rng)
    level = require 'game.level'
	C = level.create(rng, model, w, h)
	C.start()
    --if user_io.key_pressed("K_ESCAPE")
	--	C.stop()

main()