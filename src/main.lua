
-------------------------------------------------------------------------------
-- Make 'require' aware of the MOAI filesystem:
-------------------------------------------------------------------------------

local BUFF_SIZE = 4096

local function require_moai_hook(vpath)
    local rpath = vpath:gsub('%.', '/') .. '.lua'
    local stream = MOAIFileStream.new()

    if not stream:open(rpath, MOAIFileStream.READ) then
        return nil
    end

    local func,err = load(
        --[[Chunks]] function() 
            -- Will terminate on empty string:
            return stream:read(BUFF_SIZE)
        end, 
        --[[Name]] vpath
    )

    if err then error(err) end

    return func
end

table.insert(package.loaders, require_moai_hook)

MOAILogMgr.setLogLevel(MOAILogMgr.LOG_NONE)
assert(MOAIFileSystem.mountVirtualDirectory("test", "test.zip"))

print("File", MOAIFileSystem.checkFileExists "test/test.lua")
require "test.test"

local w, h = 800,600
if MOAIEnvironment.osBrand == "Android" or MOAIEnvironment.osBrand == "iOS" then
   w, h = 320,480  
end

MOAISim.openWindow("Hello World", w,h)

viewport = MOAIViewport.new()
viewport:setSize( w,h)
viewport:setScale( w,h)

layer = MOAILayer2D.new()
layer:setViewport(viewport)

MOAISim.pushRenderPass(layer)

charcodes = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 .,:;!?()&/-'

font = MOAIFont.new()
font:loadFromTTF('resources/LiberationMono-Regular.ttf',chars,120,72)

text = MOAITextBox.new()
text:setString('Hello world')
text:setFont(font)
text:setTextSize(64,32)
text:setYFlip(true)
text:setRect(-w/4,-h/4,w/4,h/4)
text:setAlignment(MOAITextBox.CENTER_JUSTIFY,MOAITextBox.CENTER_JUSTIFY)

layer:insertProp(text)
