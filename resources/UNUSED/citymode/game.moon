import Map from require "levels"

import load_tiled_json from require "loadmap"

user_io = require "user_io"

-------------------------------------------------------------------------------
-- Game setup
-------------------------------------------------------------------------------

w, h = 800,600

if MOAIEnvironment.osBrand == "Android" or MOAIEnvironment.osBrand == "iOS" 
   w, h = 320,480  

MOAISim.openWindow "Citymode", w,h

-- The components of the map
C = load_tiled_json "iso-test.json", w, h
-- Push the layers for rendering
C.start()

if user_io.key_pressed("K_ESCAPE")
    C.stop()

