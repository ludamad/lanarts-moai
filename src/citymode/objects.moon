import Map from require "levels"

import TextEditBox from require "interface"
import ErrorReporting from require "system"
import get_texture, get_json from require "resources"
import ui_ingame_scroll, ui_ingame_select from require "ui"

-------------------------------------------------------------------------------
-- Game model components
-------------------------------------------------------------------------------

-- C: The MOAI components, see load_tiled_json
load_game_model = (C) ->
    -- Assumption: The first layer holds our terrain
    -- and it is named 'Terrain'.
    terrain = C.map.layers[1]
    assert(terrain.name == "Terrain", "First layer is not named 'Terrain'!")

    

return { :load_game_model }
