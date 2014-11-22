local resources = require "resources"

--- Stores state associated with a drawable object.
-- This state can be mutated by accessing the object's
-- 'options' object.
local Sprite = newtype()

---  Create and load an image from a filename and an options table
-- The options table specifies the in-image location and the origin,
-- as well as drawing parameters such as color.
function Sprite.image_create(filename, options)
    return Sprite.create( resources.get_texture(filename), options )
end

function Sprite.animation_create(filename, options)
    texture = resources.get_texture(filename)
    local sw,sh = texture:getSize()
    local w,h = options.size[1], options.size[2]
    if not options.frames then
        options.frames= {}
        for y=0,sh/h-1 do
            for x=0,sw/w-1 do
                local x1,y1,x2,y2= (x * w)/sw, (y * h)/sh, ((x+1) * w)/sw, ((y+1) * h)/sh
                append(options.frames, {x1,y1,x2,y2})
            end
        end
    end
    options.animated = true
    return Sprite.create( resources.get_texture(filename), options )
end

---  Wrap a drawable object as an instance with state
-- 
-- The drawable object needs a 'draw' method that takes 
-- an objects object, and a position.
--
-- The options table specifies the frame and the origin, as well as
-- drawing parameters such as color.
function Sprite:init(sprite, options)
    options = options or {}
    self.sprite = sprite
    self.options = options
    self.size = options.size or {sprite:getSize()} 
    options.alpha = (options.alpha or 1)
    if self.options.animated then
        self.frame = 1
    else
        options.image_sublocation = (options.image_sublocation or {0,0,1,1})
    end
end

--- Convenience function for if the mouse is over the 
-- bounding box (rectangular area) of the sprite
function Sprite:mouse_over(xy)
    return mouse_over(xy, self.size, self.options.origin)
end

--- Step function, increases the sprite frame counter
function Sprite:step(x, y)
    if self.options.animated then
        self.frame = (self.frame + self.options.frame_speed or 1)
    end
end

--- Forwards options and position to drawable object
function Sprite:draw(x, y)
    MOAIGfxDevice.setPenColor(1,1,1,1)
    local w,h = unpack(self.size)
    local sublocation = self.options.image_sublocation
    if self.options.animated then
        assert(not sublocation)
        frame = (math.floor(self.frame)-1) % #self.options.frames + 1
        sublocation = self.options.frames[frame]
    end
    local ux1,uy1,ux2,uy2 = unpack(sublocation)
    MOAIDraw.drawTexture(self.sprite, x, y, x + w, y + h, ux1,uy1,ux2,uy2, self.options.alpha)
end

-- Set the alpha in the sprites options. Note if options are shared, may have 
-- unintended consequences.
function Sprite:set_alpha(alpha) 
    self.options.alpha = alpha
end

function Sprite:__tostring()
    return "[Sprite " .. toaddress(self) .. "]" 
end

return Sprite
