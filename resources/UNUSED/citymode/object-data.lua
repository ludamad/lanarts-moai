local list = {}

local ObjectT = typedef [[
    name : string
    cost : int
    text_repr : string
]]

local function Object(args)
    append(list, ObjectT.create(args))
end

--------------------------------------------------------------------------------
-- Begin 'building' data definitions.
--------------------------------------------------------------------------------

Object {
    name = "Tree",
    cost = 5,
    text_repr = "t",
}

Object {
    name = "Road",
    cost = 5,
    text_repr = ".",
}

Object {
    name = "House",
    cost = 10,
    -- Representation in ASCII output
    text_repr = "h",
}

--------------------------------------------------------------------------------
-- End 'building' data definitions.
--------------------------------------------------------------------------------

return list