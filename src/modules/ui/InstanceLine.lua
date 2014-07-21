-- Organizes instances into rows & columns

local InstanceGroup = require "ui.InstanceGroup"

--- A layout consisting of objects placed on one or multiple lines.
-- Each object can be placed with an optional offset.
-- Objects that are stored should have 'step' and 'draw' methods that take a position, as well as a 'size' member.
-- @usage For example, InstanceLine.create( {dx = 32} ) or InstanceLine.create( {dx = 32, per_row = 3, dy = 32} )
local InstanceLine = newtype()

--- Initializes a new InstanceLine. Takes an argument table.
-- params.force_size overrides the size the layout is considered. Otherwise it is dynamic.
-- params.dx is manditory, specifying spacing of elements on the line.
-- params.per_row & params.dy must be passed together or not at all, and specify how to arrange elements into a grid.
-- @usage For example, InstanceLine.create( {dx = 32} ) or InstanceLine.create( {dx = 32, per_row = 3, dy = 32} )
function InstanceLine:init(params)
    assert( params.dx or (params.per_row == 1),
        "InstanceLine.create expects a 'dx' member to indicate spacing of elements.")

    assert( (params.per_row and params.dy) or (not params.per_row and not params.dy),
        "InstanceLine.create expects 'per_row' and 'dy' to be passed together, or not at all.")

    self._instances = InstanceGroup.create()

    self.position = {0, 0}
    self.size =  params.force_size or {0, 0}

    self.dx = params.dx or 0
    self.dy = --[[Optional]] params.dy or 0

    self.force_size = --[[Optional]] params.force_size or false
    self.per_row = --[[Optional]] params.per_row or false
end

--- Removes the contained object 'obj'
function InstanceLine:remove(obj)
    self._instances:remove(obj)
end

--- Removes all contained objects.
function InstanceLine:clear()
    self._instances:clear()
    self.position = {0, 0}

    if not self.force_size then
        self.size = {0,0}
    end
end

--- Calls step on all contained objects.
function InstanceLine:step(x, y) 
    assert(x and y)
    self._instances:step(x, y)
end

--- Calls draw on all contained objects.
function InstanceLine:draw(x, y)
    self._instances:draw(x, y)
    DEBUG_BOX_DRAW(self, x, y)
end

--- Moves to the next location, as if an instance were added.
function InstanceLine:skip_location()
    local nx, ny = unpack(self.position)

    nx = nx + 1

    if self.per_row and nx >= self.per_row then
        self.position[1] = 0
        self.position[2] = ny + 1
    else
        self.position[1] = nx
    end
end

--- Return an iterable that iterates over all objects and their positions.
-- @param xy <i>optional, default {0,0}</i>
-- @usage for obj, xy in instance_line:instances({100,100}) do ... end
function InstanceLine:instances(x, y)
    return self._instances:instances(x, y)
end

--- Add an object to the current line, starting a new one if per_row was passed and has been exceeded.
-- @param offset <i>optional, default {0,0}</i> a position offset for the object.
function InstanceLine:add_instance(obj, --[[Optional]] offset)

    local x, y = unpack(offset or {0,0})
    local row, col = unpack(self.position)
    local subx, suby = row * self.dx, col * self.dy

    self._instances:add_instance( obj, {x + subx, y + suby} )

    if not self.force_size then
        self.size[1] = math.max(self.size[1], subx + obj.size[1] )
        self.size[2] = math.max(self.size[2], suby + obj.size[2] )
    end

    self:skip_location()
end

function InstanceLine:ipairs()
    return self._instances:ipairs()
end

function InstanceLine:align(origin)
    local ox, oy = origin[1],origin[2]
    local w,h = self.size[1], self.dy
    for _, obj in self:ipairs() do
        local objw, objh = unpack(obj[1].size)
        obj[2] = obj[2] + ox * (w - objw)
        obj[3] = obj[3] + oy * (h - objh)
    end
end

--- Whether the mouse is within the InstanceLine.
function InstanceLine:mouse_over(x, y)
    return mouse_over({x, y}, self.size)
end

--- A simple string representation for debugging purposes.
function InstanceLine:__tostring()
    return "[InstanceLine " .. toaddress(self) .. "]"
end

return InstanceLine
