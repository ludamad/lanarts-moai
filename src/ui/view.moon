-------------------------------------------------------------------------------
-- Create a menu view
-------------------------------------------------------------------------------

create_view = (G, w,h, pre_draw, draw) ->
    -- We 'cheat' with our menu 'map' attribute, just point to same object
    V = {is_menu: true}
    V.map = V
    -- Display.ui_layer = with MOAILayer2D.new()
    --     \setViewport with MOAIViewport.new()
    --         \setSize(w,h)
    --         \setScale(w,-h)

    V.step = () -> nil

    V.pre_draw = 

    V.handle_io = () -> nil

    -- Setup function
    V.start = () -> MOAISim.pushRenderPass(Display.ui_layer)
    V.stop = () -> 
        Display.ui_layer\clear()
        MOAISim.removeRenderPass(Display.ui_layer)

    return V