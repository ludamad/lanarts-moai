-- Used to implement logic in Display.moon

moai_resource_cache = (constructor, remover = nil) ->
    cached = {}
    used = {}
    -- Optional
    side_data = {}
    return {
        get: (data = nil) ->
            local resource
            if #cached > 0
                resource = cached[#cached]
                cached[#cached] = nil
            else
                resource = constructor()
            append used, resource
            -- Associated data
            if data then append side_data, data
            return resource
        clear: () ->
            for i=1,#used
                append cached, used[i]
                if remover then
                    remover(used[i], side_data[i])
            table.clear(used)
            table.clear(side_data)
    }

blend_mode_initer = (cons) -> () ->
    return with cons()
        \setBlendMode(MOAIProp2D.GL_SRC_ALPHA, MOAIProp2D.GL_ONE_MINUS_SRC_ALPHA)

-- Used to cache MOAI objects to avoid excessive allocations during drawing
MOAI_TEXTBOX_CACHE = moai_resource_cache((blend_mode_initer MOAITextBox.new), (prop, layer) -> layer\removeProp(prop))
MOAI_QUAD_CACHE = moai_resource_cache(MOAIGfxQuad2D.new)
MOAI_PROP_CACHE = moai_resource_cache((blend_mode_initer MOAIProp2D.new), (prop, layer) -> layer\removeProp(prop))

MOAI_CACHES = {MOAI_TEXTBOX_CACHE, MOAI_QUAD_CACHE, MOAI_PROP_CACHE}

-- Use at beginning of drawing
reset_draw_cache = () ->
    for cache in *MOAI_CACHES
        cache.clear()

 -- Textbox pseudo-method
 -- Hack to fit textbox based on its contents
textbox_fit_text = (text, x, y, align_x = 0, align_y = 0) =>
    -- Arbitrarily big
    BIG = 1000
    @setRect(x, y, x + BIG, y + BIG)
    @setString(text)

    @setAlignment MOAITextBox.LEFT_JUSTIFY, MOAITextBox.LEFT_JUSTIFY
    x1, y1, x2, y2 = @getStringBounds(1,#text)
    w,h = (x2 - x1), (y2 - y1)
    a1x,a2x = align_x, 1 - align_x
    a1y,a2y = align_y, 1 - align_y
    @setRect(math.floor(x - w*a1x), math.floor(y - h*a1x), math.ceil(x + w*a2x), math.ceil(y + h*a2y))

put_text = (layer, style, textString, x, y, align_x = 0, align_y = 0, text_alignment = "left") ->
    assert(textString ~= nil, "textString == nil in draw_text!")
    textbox = MOAI_TEXTBOX_CACHE.get(layer)
    textbox\setStyle(style)
    textbox\setPriority(0) -- Set to default
    textbox\setColor(1,1,1,1) -- Set to default
    textbox_fit_text(textbox, textString, x, y, align_x, align_y)
    if text_alignment == "left"
        textbox\setAlignment MOAITextBox.LEFT_JUSTIFY
    elseif text_alignment == "right"
        textbox\setAlignment MOAITextBox.RIGHT_JUSTIFY
    elseif text_alignment == "center"
        textbox\setAlignment MOAITextBox.CENTER_JUSTIFY

    layer\insertProp(textbox)
    return textbox

put_text_center = (layer, style, textString, x, y) -> put_text(layer, style, textString, x, y, 0.5, 0.5, "center")
put_text_right = (layer, style, textString, x, y) -> put_text(layer, style, textString, x, y, 1, 1, "right")

get_quad = () -> MOAI_QUAD_CACHE.get()

put_prop = (layer) -> 
    assert(layer)
    prop = MOAI_PROP_CACHE.get(layer)
    layer\insertProp(prop)
    return prop

put_image = (layer, tex, x, y, priority = 0) ->
    texw, texh = tex\getSize()
    return with put_prop(layer)
        \setLoc x, y
        \setDeck with get_quad()
            \setTexture tex
            -- Center tile on origin:
            \setRect -texw/2, texh/2, 
                texw/2, -texh/2
        \setPriority priority

shift_origin = (bbox, origin) ->
    {x1,y1,x2,y2} = bbox
    w,h = (x2-x1), (y2-y1)
    {ox, oy} = origin
    return {(x1 - w*ox), (y1 - h*ox), (x2 - w*ox), (y2 - h*ox)}

return {:put_text, :put_image, :put_text_center, :put_text_right,  :get_quad, :put_prop, :textbox_fit_text, :reset_draw_cache, :shift_origin}
