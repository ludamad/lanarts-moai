local level_list = {}

local LevelT = typedef [[
    name : string
    w, h : int
    layout : list
]]

-- Accumulates in 'level_list'
local function Level(args)
    local layout = {}

    local w = nil 
    -- Have the layout split by row
    for line in values((args.layout):split('\n')) do
        line = line:trim()
        if line ~= "" then
            w = (w or #line)
            assert(#line == w, "Line size mismatch!")
            append(layout, line)
        end
    end

    args.w, args.h = w, #layout

    -- Create using the LevelT instance
    append(level_list, LevelT.create(args))
end

--------------------------------------------------------------------------------
-- Begin 'level' data definitions.
--------------------------------------------------------------------------------

Level {
    name = "Tutorial",
    layout = [[
    tttttttttttttttt
    ttttt----------t
    t-------www---tt
    t-----twwww--ttt
    t-------ttt-tttt
    t---------t----t
    tttttttttttttttt
]]
}

--------------------------------------------------------------------------------
-- End 'level' data definitions.
--------------------------------------------------------------------------------

return level_list