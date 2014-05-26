local res = require "resources"
local io = require "io"

--------------------------------------------------------------------------------
-- Object base. Links with MOAI. 
-- Implementation convenience. Provides several constructor styles.
--------------------------------------------------------------------------------

local ObjectBase = newtype()

-- img_name : string, image to back prop with
function ObjectBase:init_prop(img_name)
    self.prop = res.get_tiles_bg(img_name, {{1,1}, {1,1}}, 32, 32)
    self.prop:setLoc(self.x,self.y)
end

function ObjectBase:draw()
end

function ObjectBase:step()
end

function ObjectBase:register()
    self.layer:insertProp(self.prop)
end

function ObjectBase:unregister()
    self.layer:removeProp(self.prop)
end

--------------------------------------------------------------------------------
-- Building object.
--------------------------------------------------------------------------------

local BuildingObject = newtype { parent = ObjectBase }

function BuildingObject:init()
    self:init_prop("shop.png")
end

function BuildingObject:draw()
    if io.key_down then
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