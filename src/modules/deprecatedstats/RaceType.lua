-- Usage: 'RaceType.define { ... attributes ... }', 'RaceType.lookup(<name or ID>)'
local S = require "@Schemas"
local ResourceTypes = require "@ResourceTypes"

local RaceType = ResourceTypes.type_create(
    S.enforce_function_create {
        name = S.STRING,
        description = S.STRING,
        traits = S.defaulted(S.TABLE, {}),
        on_create = S.FUNCTION
    }
)

return RaceType