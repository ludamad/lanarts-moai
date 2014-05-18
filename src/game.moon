-------------------------------------------------------------------------------
-- Game state class
-------------------------------------------------------------------------------

import map from require "."

Game = newtype()

Game.init = (layer) =>
    @map = map.create("test")
Game.step = () =>
    @map\step()
Game.draw = () =>
    @map\draw()

-------------------------------------------------------------------------------
-- Game setup
-------------------------------------------------------------------------------

charcodes = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 .,/;!?()&/-'

font = with MOAIFont.new()
    \loadFromTTF('resources/LiberationMono-Regular.ttf', charcodes, 120, 72)

setup_game = (w, h) ->
    MOAISim.openWindow("Lanarts", w,h)
    
    layer = with MOAILayer2D.new()
        \setViewport with MOAIViewport.new()
            \setSize( w,h)
            \setScale( w,h)
    
    MOAISim.pushRenderPass(layer)

    init_script_deck = (draw_func) ->
        layer\insertProp with MOAIProp2D.new()
                \setDeck with MOAIScriptDeck.new()
                    \setDrawCallback(draw_func)

    import TextEditBox from require "interface"
    import ErrorReporting from require "system"

    text = with MOAITextBox.new()
        \setFont(font)
        \setTextSize(64,32)
        \setYFlip(true)
        \setRect(-w/4,-h/4,w/4,h/4)
        \setAlignment(MOAITextBox.CENTER_JUSTIFY, MOAITextBox.CENTER_JUSTIFY)
    edit_box = TextEditBox.create(text, "Hello World!")

    if MOAIInputMgr.device.keyboard
        MOAIInputMgr.device.keyboard\setCallback (key,down) ->
        	ErrorReporting.report () ->
            	if down then
                	edit_box\_onHandleKeyDown key: key

    layer\insertProp(text)

    game = Game.create(layer)

    init_script_deck () -> 
        game\step() 
        game\draw() 

w, h = 800,600

if MOAIEnvironment.osBrand == "Android" or MOAIEnvironment.osBrand == "iOS" 
   w, h = 320,480  

setup_game(w, h)

--inspect()

