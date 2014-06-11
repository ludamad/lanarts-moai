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
	base = modules.load "base"
    level = require 'game.level'
	C = level.create()
	C.start()
    --if user_io.key_pressed("K_ESCAPE")
	--	C.stop()

main()