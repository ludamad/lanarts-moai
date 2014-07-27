import ErrorReporting from require 'system'

-- Default priority is quite large (near front)
DRAW_PRIORITY = 150
setup_script_prop = (layer, draw_func, w, h, priority = DRAW_PRIORITY) ->
    -- Step until the draw loop returns false
    script_prop = with MOAIProp2D.new()
        \setDeck with MOAIScriptDeck.new()
            \setDrawCallback draw_func
            \setRect 0,0,w,h
        \setPriority priority 
    layer\insertProp script_prop
    return script_prop

setup_draw_loop = (draw_func) ->
    V = {}
    {w,h} = _SETTINGS.window_size

    -- Ensure error reporting occurs properly
    draw_func = ErrorReporting.wrap(draw_func)
    -- Step until the draw loop returns false
	_step_loop = () ->
   		if draw_func() == false
   			V.stop()

    -- Setup function
    V.start = () -> 
    	V.layer = with MOAILayer2D.new()
            \setViewport with MOAIViewport.new()
                \setSize(w,h)
                \setScale(w,h)

        -- Begin rendering the MOAI layers
        MOAISim.pushRenderPass(V.layer)

    	V.layer\insertProp with MOAIProp2D.new()
			\setDeck with MOAIScriptDeck.new()
				\setDrawCallback _step_loop
				\setRect 0,0,w,h

    V.stop = () ->
    	V.layer\clear()
        -- Cease rendering the MOAI layers
        MOAISim.removeRenderPass(V.layer)
        V.layer = nil

    V.join = () ->
    	-- While draw loop is active:
    	while V.layer ~= nil 
    		coroutine.yield()

    return V

return {:setup_script_prop, :setup_draw_loop}
