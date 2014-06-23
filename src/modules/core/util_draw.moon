resources = require 'resources'

setup_script_prop = (layer, draw_func) ->
    {w,h} = _SETTINGS.window_size
    -- Step until the draw loop returns false
    _step_loop = () ->
        if draw_func() == false
            V.stop()

    script_prop =with MOAIProp2D.new()
        \setDeck with MOAIScriptDeck.new()
            \setDrawCallback _step_loop
            \setRect 0,0,w,h
    layer\insertProp script_prop
    return script_prop

setup_draw_loop = (draw_func) ->
    V = {}
    {w,h} = _SETTINGS.window_size

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

-- Used to pool textbox objects for 'immediate' drawing
TEXTBOXS_CACHED = {}
TEXTBOXS_USED = {}

draw_text = (layer, style, textString, x, y) ->
    assert(textString ~= nil, "textString == nil in draw_text!")
    local textbox
    if #TEXTBOXS_CACHED > 0
        textbox = TEXTBOXS_CACHED[#TEXTBOXS_CACHED]
        TEXTBOXS_CACHED[#TEXTBOXS_CACHED] = nil
    else
        print "NEW?"
        textbox = MOAITextBox.new()

    with textbox
        \setStyle(style)
        \setAlignment(MOAITextBox.CENTER_JUSTIFY,MOAITextBox.CENTER_JUSTIFY)
        \setRect(-1000,-1000,1000,1000)
        \setLoc(x, y)
        \setString(textString)

    append TEXTBOXS_USED, {textbox, layer}
    layer\insertProp(textbox)

-- Use at beginning of drawing
reset_draw_cache = () ->
    for {used, layer} in *TEXTBOXS_USED
        append TEXTBOXS_CACHED, used
        layer\removeProp(used)
    table.clear(TEXTBOXS_USED)

return {:setup_script_prop, :setup_draw_loop, :draw_text, :reset_draw_cache}