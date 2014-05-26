-------------------------------------------------------------------------------
-- Game state class
-------------------------------------------------------------------------------

import Map from require "levels"

import TextEditBox from require "interface"
import ErrorReporting from require "system"
import BuildingObject from require "objects"

-------------------------------------------------------------------------------
-- Game setup
-------------------------------------------------------------------------------

charcodes = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 .,/;!?()&/-'

font = with MOAIFont.new()
    \loadFromTTF('resources/LiberationMono-Regular.ttf', charcodes, 120, 72)

setup_game = (w, h) ->
    w, h = 800,600
    if MOAIEnvironment.osBrand == "Android" or MOAIEnvironment.osBrand == "iOS" 
       w, h = 320,480  

    MOAISim.openWindow("Lanarts", w,h)

    map = with Map.create()
        \add_obj BuildingObject.create(32, 32)
        -- Set up this map for drawing:
        \register with MOAIViewport.new()
            \setSize(w,h)
            \setScale(w,h)

	with MOAIThread.new()
		\run () ->
			while true
				coroutine.yield()
				map\step()

setup_game()

--inspect()

