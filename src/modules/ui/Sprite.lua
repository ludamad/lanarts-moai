local resources = require "resources"

--- Stores state associated with a drawable object.
-- This state can be mutated by accessing the object's
-- 'options' object.
local Sprite = newtype()

---  Create and load an image from a filename and an options table
-- The options table specifies the frame and the origin, as well as
-- drawing parameters such as color.
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
    self.sprite = sprite
    self.options = options or {}
    if self.options.frame == nil then
       self.options.frame = 1
    end
end

--- Getter for the sprite's size
function Sprite.get:size()
    return {self.sprite:getSize()}
end

--- Convenience function for if the mouse is over the 
-- bounding box (rectangular area) of the sprite
function Sprite:mouse_over(xy)
    return mouse_over(xy, self.size, self.options.origin)
end

--- Step function, increases the sprite frame counter
function Sprite:step(xy)
    self.options.frame = self.options.frame + 1
end

--- Forwards options and position to drawable object
function Sprite:draw(xy)
    local w,h = self.sprite:getSize()
    MOAIDraw.drawTexture(xy[1], xy[1] + h, xy[1] + w,  xy[2], self.sprite)
--    self.sprite:draw( self.options, xy)
end

function Sprite:__tostring()
    return "[Sprite " .. toaddress(self) .. "]" 
end

return Sprite
