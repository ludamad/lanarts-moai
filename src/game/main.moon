user_io = require "user_io"
modules = require "game.modules"

-------------------------------------------------------------------------------
-- Game setup
-------------------------------------------------------------------------------

w, h = 800,600

MOAISim.openWindow "Lanarts", w,h

-- The components of the map
--C = load_tiled_json "lanarts-test.json", w, h
-- Push the layers for rendering
--C.start()

main = () ->
	rng = (require 'mtwist').create(os.time())
	base = modules.load "base"
	model = modules.get_level("start").generator(rng)
    level = require 'game.level'
	C = level.create(rng, model, w, h)
	C.start()
    --if user_io.key_pressed("K_ESCAPE")
	--	C.stop()

main()