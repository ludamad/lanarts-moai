local res = require "resources"
local user_io = require "user_io"

--------------------------------------------------------------------------------
-- Object base. Links with MOAI. 
-- Implementation convenience. Provides several constructor styles.
--------------------------------------------------------------------------------

local ObjectBase = newtype()

-- img_name : string, image to back prop with
function ObjectBase:init_with_prop(img_name, x, y, w, h)
    self.x, self.y = x, y
    self.prop = res.get_sprite_prop(img_name, w, h)
    self.prop:setLoc(self.x,self.y)
end

-- By default, never called.
-- Must call init_with_script_prop.
function ObjectBase:draw()
end

function ObjectBase:step()
end

function ObjectBase:register(map, layer)
    layer:insertProp(self.prop)
end

function ObjectBase:unregister(map, layer)
    layer:removeProp(self.prop)
end

--------------------------------------------------------------------------------
-- Building object.
--------------------------------------------------------------------------------

local BuildingObject = newtype { parent = ObjectBase }

function BuildingObject:init(x, y)
    assert(x and y, "Must provide x & y!")
    self:init_with_prop("shop.png", x, y, 32, 32)
end

function BuildingObject:step()
    if user_io.key_down("K_ENTER") then
        print "Down"
        self.prop:setColor(0.5, 0.5, 0.5)
    else
        print "Not down"
        self.prop:setColor(1.0, 1.0, 1.0)
    end
end

return {
    ObjectBase = ObjectBase,
    BuildingObject = BuildingObject
}