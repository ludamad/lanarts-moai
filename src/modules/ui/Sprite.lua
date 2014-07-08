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
    options.image_sublocation = (options.image_sublocation or {0,0,1,1})
end

--- Convenience function for if the mouse is over the 
-- bounding box (rectangular area) of the sprite
function Sprite:mouse_over(xy)
    return mouse_over(xy, self.size, self.options.origin)
end

--- Step function, increases the sprite frame counter
function Sprite:step(x, y)
    self.options.frame = self.options.frame + 1
end

--- Forwards options and position to drawable object
function Sprite:draw(x, y)
    MOAIGfxDevice.setPenColor(1,1,1,1)
    local w,h = unpack(self.size)
    local ux1,uy1,ux2,uy2 = unpack(self.options.image_sublocation)
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
