
-- Keeps track of instances + relative positions
-- Tries to store & resolve relative positions in a somewhat efficient manner

--- A layout utility that stores relative positions of objects.
-- Each object can be placed with an origin, as well as an optional offset.
-- Objects that are stored should have 'step' and 'draw' methods that take a position.
-- @usage InstanceGroup.create()
local InstanceGroup = newtype()

--- Initializes a new instance group. 
-- @usage InstanceGroup.create()
function InstanceGroup:init()
    self._instances = {}
end

--- Add an object to this container.
-- @param xy the origin to align against, eg Display.LEFT_TOP, Display.RIGHT_BOTTOM.
function InstanceGroup:add_instance(obj, xy )
    self._instances[#self._instances + 1] = { obj, xy[1], xy[2] }
end

--- Calls step on all contained objects.
function InstanceGroup:step(x, y)
    for _, instance in ipairs(self._instances) do
        local obj, obj_x, obj_y = unpack(instance)
        obj:step(obj_x + x, obj_y + y)
    end
end

--- Return an iterable that iterates over all objects and their positions.
-- @param xy <i>optional, default {0,0}</i>
-- @usage for obj, x, y in instance_group:instances({100,100}) do ... end
function InstanceGroup:instances(x, y)
    x, y = x or 0, y or 0

    local arr,idx = self._instances,1

    -- Iterate the values in a fairly future-proof way, via a helper closure
    return function() 
        local val = arr[idx]

        if val == nil then
            return nil 
        end

        idx = idx + 1
        local obj, obj_x, obj_y = unpack(val)
        return obj, x + obj_x, y + obj_y
    end
end

--- Removes the contained object 'obj'.
function InstanceGroup:remove(obj)
    local insts = self._instances

    for i = 1, #insts do
        if insts[i][1] == obj then
            table.remove(insts, i)
            return true
        end
    end

    return false
end

--- Removes all contained objects.
function InstanceGroup:clear(--[[Optional]] recursive)
    if recursive then

    end
    self._instances = {}
end

--- Calls draw on all contained objects.
function InstanceGroup:draw(x, y)
    for _, instance in ipairs(self._instances) do
        local obj, obj_x, obj_y = unpack(instance)
        obj:draw(obj_x + x, obj_y + y)
    end
end

--- A simple string representation for debugging purposes.
function InstanceGroup:__tostring()
    return "[InstanceGroup " .. toaddress(self) .. "]"
end
return InstanceGroup
