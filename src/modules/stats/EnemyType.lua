-- Usage: 'MonsterType.define { ... attributes ... }', 'MonsterType.lookup(<name or ID>)'

local Stats = require "@Stats"
local Item = require "@Item"
local Schemas = require "@Schemas"
local ResourceTypes = require "@ResourceTypes"

local MonsterType = ResourceTypes.type_create(
    Schemas.enforce_function_create {
        name = Schemas.STRING,
        description = Schemas.STRING,
        -- TODO sprites, radius, appear message, defeat message
        traits = Schemas.TABLE,
        on_prerequisite = Schemas.FUNCTION_OR_NIL
    }
)

return MonsterType