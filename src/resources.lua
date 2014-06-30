local RESOURCE_PATH = {
    "",
    "./resources/",
    "./resources/game/",
    "./resources/lanarts/",
    "./src/modules/core/",
    "./src/modules/core/resources/",
    "./src/modules/core/resources/fonts/",
    "./resources/tiled-maps/",
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

-- TODO: Temporary!
_G.path_resolve = get_resource_path

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
--        print("Loaded", ppath, "at", abs_path, "size", texture:getSize())
    end 
    return texture
end

local function reload_textures(ppath)
    local prev = texture_cache
    -- Reload all the textures
    for k,v in pairs(texture_cache) do
        -- Release 
        v:release()
        -- And reload
        texture:load(get_stream(ppath))
    end
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

local function get_base_paths() 
    return RESOURCE_PATH
end

local function set_base_paths(paths) 
    RESOURCE_PATH = assert(paths, "Cannot set resource path to nil!")
end

local font_cache = {}

local function get_font(ppath)
    local abs_path = get_resource_path(ppath)
    if font_cache[abs_path] then 
        return font_cache[abs_path] 
    end

    local charcodes = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 .,/;!?()&/-'

    local font = MOAIFont.new()
    font:load(abs_path)
    font:setFlags(0)
    font:preloadGlyphs(charcodes, 11)
    font_cache[abs_path] = font
    return font
end

local bmfont_cache = {}

local function get_bmfont(ppath)
    local abs_path = get_resource_path(ppath)
    if bmfont_cache[abs_path] then 
        return bmfont_cache[abs_path] 
    end

    local font = MOAIFont.new()
    font:loadFromBMFont(abs_path)
    
    return font
end

return {
    reload_textures = reload_textures,
    get_resource_path = get_resource_path,
    get_stream = get_stream,
    get_json = get_json,
    get_texture= get_texture,
    get_tiles_bg= get_tiles_bg,
    get_sprite_prop = get_sprite_prop,
    get_tiles_prop = get_tiles_prop,
    get_font = get_font,
    get_bmfont = get_bmfont,

    -- Resource path management, for loading modules:
    get_base_paths = get_base_paths,
    set_base_paths = set_base_paths
}
