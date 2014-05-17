local texture_cache = {}

local function get_sprite_quad(fname, w, h)
    local texture = texture_cache[fname]

    if not texture then  
        texture = MOAITexture.new()
        texture:load(fname)
        texture_cache[fname] = texture
    end

    local quad = MOAIGfxQuad2D.new()

    quad:setTexture(texture)
    quad:setRect(-w/2, -h/2, w/2, h/2)

    return quad
end

local function get_sprite_prop(fname, w, h)
    local prop = MOAIProp2D.new()
    prop:setDeck(get_sprite_quad(fname, w, h))
    return prop
end

return {
    SpriteProp = {
        create = get_sprite_prop
    }
}
