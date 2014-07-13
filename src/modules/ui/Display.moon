-- The main display module. See the components for the available methods.

Module = {}

-- TODO: Remove dependency on C++ code here
table.merge Module, require "lanarts.draw"

-- Import extra components
table.merge Module, require '@Display_drawcache'
table.merge Module, require '@Display_constants'
table.merge Module, require '@Display_components'
table.merge Module, require '@Display_camera'
table.merge Module, require '@Display_drawutil'

return Module