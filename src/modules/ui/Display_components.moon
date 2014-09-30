-- A simplified model of drawing to the screen.
-- Since we only have one view, we happily use globals to model it.
-- 
-- As a simplification, there are four layers:
--     - Background layer, for tiles
--  - Object layer, for moving game objects
--  - Foreground layer, for fog of war
--  - Interface layer, for drawing interface components
--
-- Generally, the background and foreground layer are drawn with a single MOAIGrid each
-- The object layer is drawn mostly with MOAIProp's created using the put_ API
-- The interface layer has no camera, unlike the other layers.

import ErrorReporting from require "system"

--------------------------------------------------------------------------------
-- Private members
--------------------------------------------------------------------------------

game_camera = MOAICamera2D.new()
game_viewport = MOAIViewport.new()

game_bg_layer, game_obj_layer, game_fg_layer1, game_fg_layer2 = MOAILayer2D.new(), MOAILayer2D.new(), MOAILayer2D.new(), MOAILayer2D.new()
game_layers = {game_bg_layer, game_obj_layer, game_fg_layer1, game_fg_layer2}

for game_layer in *game_layers
    game_layer\setCamera(game_camera) -- All game layers use the same camera
    game_layer\setViewport(game_viewport) -- All game layers use the same viewport

ui_viewport = MOAIViewport.new()
ui_layer = with MOAILayer2D.new()
    \setViewport(ui_viewport)

all_layers = {game_bg_layer, game_obj_layer, game_fg_layer1, game_fg_layer2, ui_layer}

-- Track if display_setup has been called yet
_DISPLAY_INITIALIZED = false

--------------------------------------------------------------------------------
-- Public members
--------------------------------------------------------------------------------

_size = assert(_SETTINGS.window_size, "Window size not given!")

display_size = () ->
    return _size[1], _size[2]

display_clear = () ->
    for layer in *all_layers
        layer\clear()

import PRIORITY_INTERFACE, PRIORITY_CURSOR from require '@Display_constants'

display_add_draw_func = (draw_func, layer = ui_layer, priority = PRIORITY_INTERFACE, x = 0, y = 0, w = _size[1], h = _size[2]) ->
    -- Step until the draw loop returns false
    script_prop = with MOAIProp2D.new()
        \setDeck with MOAIScriptDeck.new()
            \setDrawCallback ErrorReporting.wrap(draw_func)
            \setRect x,y,w,h
        \setPriority priority 
        \setBlendMode(MOAIProp2D.GL_SRC_ALPHA, MOAIProp2D.GL_ONE_MINUS_SRC_ALPHA)
    layer\insertProp script_prop
    return script_prop

configure_cursor_display = () ->
    SetLanartsShowCursor (not _SETTINGS.use_cursor_sprite)
    if not _SETTINGS.use_cursor_sprite
        return
    -- Setup the custom cursor callback
    cursor_spr, mouse_xy = nil, nil
    cursor_func = () ->
        mouse_xy or= require("user_io").mouse_xy
        mx, my = mouse_xy()
        cursor_spr or= require("core.data").get_sprite("cursor")
        cursor_spr\draw(mx, my,1,1,0.1,0.1)
    display_add_draw_func cursor_func, ui_layer, PRIORITY_CURSOR

-- TODO See about resizing the window
-- display_setup takes x1,y1,x2,y2 as coordinates for which the playing area consists of
display_setup = (x=0, y=0, w = _size[1], h = _size[2]) ->

    game_camera\setLoc(x, y)
    with game_viewport
        \setSize(w, h)
        \setScale(w, h)

    if not _DISPLAY_INITIALIZED
        logI "Display.display_setup: Initial setup"
        SetLanartsOpenWindowFullscreenMode _SETTINGS.fullscreen
        MOAISim.openWindow "Lanarts", _size[1], _size[2]
        gl_set_vsync(false)
        with ui_viewport
            \setOffset(-1, 1)
            \setSize(_size[1], _size[2])
            \setScale(_size[1], -_size[2])
        for layer in *all_layers
            MOAISim.pushRenderPass(layer)
        _DISPLAY_INITIALIZED = true
    else
        logI "Display.display_setup: Clearing display"
        display_clear()
    configure_cursor_display()

return {
    :game_camera, :game_viewport, :ui_viewport
    :game_bg_layer, :game_obj_layer, :game_fg_layer1, :game_fg_layer2, :ui_layer
    :display_add_draw_func
    :display_clear, :display_size, :display_setup
}
