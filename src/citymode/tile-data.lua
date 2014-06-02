local tilesets = {}

local function tile(name, kind, direction)
    assert(name and kind and direction, "Must exist!")
    return {name = name, kind = kind, direction = direction}
end

local G = tile("ground", "free", "none")
local T = tile("tree", "free", "none")
-- 'I don't care' value, for now
local _ = G 

--------------------------------------------------------------------------------
-- Begin tile data definitions.
--------------------------------------------------------------------------------

tilesets["placeholder-tiles.png"] = {
    {G, _, _, G, _, _, _}, -- Row 1
    {_, _, _, _, _, _, _},
    {_, _, _, _, _, _, _},
    {T, T, T, T, T, T, _},
    {T, T, T, T, T, T, _},
    {T, T, T, T, T, T, _}  -- Row 6
}

--------------------------------------------------------------------------------
-- End tile data definitions.
--------------------------------------------------------------------------------


return tilesets