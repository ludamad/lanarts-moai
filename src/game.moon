w, h = 800,600

if MOAIEnvironment.osBrand == "Android" or MOAIEnvironment.osBrand == "iOS" 
   w, h = 320,480  

MOAISim.openWindow("Lanarts", w,h)

layer = with MOAILayer2D.new()
    \setViewport with MOAIViewport.new()
        \setSize( w,h)
        \setScale( w,h)

MOAISim.pushRenderPass(layer)

charcodes = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 .,/;!?()&/-'

font = with MOAIFont.new()
    \loadFromTTF('resources/LiberationMono-Regular.ttf', charcodes, 120, 72)

setup_game = () ->
    import TextEditBox from require "interface"
    text = with MOAITextBox.new()
        \setString('Hello world')
        \setFont(font)
        \setTextSize(64,32)
        \setYFlip(true)
        \setRect(-w/4,-h/4,w/4,h/4)
        \setAlignment(MOAITextBox.CENTER_JUSTIFY, MOAITextBox.CENTER_JUSTIFY)
    layer\insertProp(text)

    TextEditBox.create() 

--if MOAIInputMgr.device.keyboard
--    MOAIInputMgr.device.keyboard\setCallback (key,down) ->
--        if down then
--            text\setString(tostring key)

setup_game()

inspect()

