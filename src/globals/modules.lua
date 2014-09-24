local wrapped_require = require

local MNAME_TO_ENVIRONMENT = {}
local VPATH_TO_ENVIRONMENT = {}

-- Wrap each loader with a function environment injector
for i,loader in ipairs(package.loaders) do
    package.loaders[i] = function(vpath)
        local module_func = loader(vpath)
        -- Was it an error?
        if module_func == nil or type(module_func) == 'string' then 
            return module_func
        end
        -- Did we load the module?
        local fenv = VPATH_TO_ENVIRONMENT[vpath]
        if fenv and debug.getinfo(module_func, "S").source ~= "=[C]" then
            -- If a C function was not loaded, inject our environment
            setfenv(module_func, fenv)
        end
        return module_func
    end
end

local ROOT_REQUIRER = setmetatable({}, {
    __index = function (self, k)
        return require(k)
    end
})

-- We could achieve the same effect with a loader for 'require'
-- but we want to avoid caching modules with similar relative paths.
function require(vpath, fenv)
    -- Return a special object for '', to allow root imports via indexing:
    if vpath == '' then 
        return ROOT_REQUIRER
    end
    local caller_fenv = getfenv(2)
    local called_mname = rawget(caller_fenv, "__MODULE") 

    --- Special character handling ---
    local first_chr = vpath:sub(1,1)
    local vpath_rest = vpath:sub(2, #vpath)
    if first_chr == '@' then
        -- This is a module-local import. The name of the current module replaces '@'.
        if called_mname then 
            vpath = called_mname .. '.' .. vpath_rest
        else
            error("Error: 'require' needs module name for '" .. debug.getinfo(2, "S").source .. "', not provided!")
        end
    end

    --- Function environment and module name fiddling ---
    local mname = fenv and rawget(fenv, "__MODULE")
    -- Was the module name not discernable?
    if not mname then
        -- Grab first part of path
        mname = vpath:split("%.")[1]
    end
    -- Lookup if cache if not given
    fenv = fenv or MNAME_TO_ENVIRONMENT[mname] 
    -- Was the function environment not given?
    if not fenv then        
        -- Store in cache
        fenv = setmetatable({__MODULE = mname},{
            -- Chain to the 'parent' function environment
            __index = caller_fenv._G
        })
    end
    MNAME_TO_ENVIRONMENT[mname] = fenv 

    VPATH_TO_ENVIRONMENT[vpath] = fenv

    local function loader() return wrapped_require(vpath) end
    setfenv(loader, fenv)
    return loader()
end