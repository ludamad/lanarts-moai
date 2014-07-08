-- The main display module. See the components for the available methods.

Module = nilprotect {}

-- Import extra components
table.merge Module, require '@Display_drawcache'
table.merge Module, require '@Display_constants'
table.merge Module, require '@Display_components'
table.merge Module, require '@Display_camera'

return Module