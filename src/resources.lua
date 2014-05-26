local RESOURCE_PATH = {
    "./resources/",
    "./resources/tiled-maps",
}

-- ppath => partial path
local function get_resource_path(ppath, --[[Optional]] soft_error)
    for _,r in ipairs(RESOURCE_PATH) do
        local abs_path = MOAIFileSystem.getAbsoluteFilePath(r .. ppath)
        if MOAIFileSystem.checkFileExists(abs_path) then
            return abs_path
        end
    end
    if not soft_error then
        error("Could not find a location for resource '" .. ppath .. "'!")
    end
    return nil
end

local function get_stream(ppath, ...)
    local abs_path = get_resource_path(ppath)
    local stream = MOAIFileStream.new()
    stream:open(abs_path, ...)
    return stream
end

local texture_cache = {}

local function get_texture(ppath)
    local abs_path = get_resource_path(ppath)
    local texture = texture_cache[abs_path]
    if not texture then  
        texture = MOAITexture.new()
        texture:load(get_stream(ppath))
        texture_cache[abs_path] = texture
    end 
    return texture
end

local function get_sprite_quad(ppath, --[[Optional]] w,  --[[Optional]] h)
    local texture = get_texture(ppath)
    if not w then
        w,h = texture:getSize()
    end

    local quad = MOAIGfxQuad2D.new()
    quad:setTexture(texture)
    quad:setRect(-w/2, -h/2, w/2, h/2)

    return quad
end

local function get_json(ppath)
    local stream = get_stream(ppath)
    local data = stream:read()
    return MOAIJsonParser.decode(data)
end

local function get_sprite_prop(ppath, --[[Optional]] w, --[[Optional]] h)
    local prop = MOAIProp2D.new()
    prop:setDeck(get_sprite_quad(ppath, w, h))
    return prop
end

local function get_tiles_prop(ppath)
    local tiles = MOAITileDeck2D.new()
    local tex = get_texture(ppath)
    tiles:setTexture(tex)
    local w,h = tex:getSize()
    print(w/32,h/32)
    tiles:setSize(w/32,h/32)
    return tiles
end

local function _togrid(t)
    local grid = MOAIGrid.new()
    local cols,rows=#t[1],#t
    grid:initRectGrid(cols,rows,32,32)
    for i=1,rows do
        grid:setRow(i, unpack(t[i]))
    end
    return grid
end

local function get_tiles_bg(ppath, t, --[[Optional]] x, --[[Optional]] y)
    local prop = MOAIProp2D.new()
    prop:setDeck(get_tiles_prop(ppath))
    prop:setGrid(_togrid(t))
    prop:setLoc(x or 0, y or 0)
    return prop
end

local orig_require = _G.require -- in case it gets replaced
local require_cache = {}
local function require(ppath)
    local lpath = (ppath):gsub("%.","/") .. ".lua"
    local abs_path = get_resource_path(lpath, --[[Soft fail]] true)
    if not abs_path then
        return orig_require(ppath) -- For shared objects and such
    end
    if require_cache[ppath] then return require_cache[ppath] end 
    local res = dofile(MOAIFileSystem.getRelativePath(abs_path))
    require_cache[ppath] = res
    return res
end

return {
    get_resource_path = get_resource_path,
    get_stream = get_stream,
    get_json = get_json,
    get_texture= get_texture,
    get_tiles_bg= get_tiles_bg,
    get_sprite_prop = get_sprite_prop,
    get_tiles_prop = get_tiles_prop,
    require = require
}