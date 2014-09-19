local timer = timer_create()

-- Import all content definition submodules.
local CONTENT_PATTERN = "Define*"

local function require_all(subpackage)
    local content = find_submodules(subpackage, --[[Recursive]] true, CONTENT_PATTERN)
    for c in values(content) do
        if c ~= "unstable.DefineAll" then
            -- Don't recursively require!
            require(c)
        end
    end
end

-- Import stats folder first, has fundamental components:
require_all("unstable.stats")
require_all("unstable")

print("** Loading elapsed time: " .. timer:get_milliseconds() .. "ms")