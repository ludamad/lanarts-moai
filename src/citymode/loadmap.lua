
-- Setup up layers from a Tiled description.
-- Returns a table with the components, with a function
-- to set up and one to tear-down the layers.

load_tiled_json = (path, vieww, viewh) ->
    map = parse_tiled_json path 

    C = {} -- The components

    cx, cy = map.tile_width * map.iso_height / 2, map.tile_height * map.iso_width / 2
    C.camera = with MOAICamera2D.new()
        \setLoc(-cx, cy)
    C.viewport = with MOAIViewport.new()
        \setSize(vieww, viewh)
        \setScale(vieww, -viewh)

    -- Create a conversion map from Tiled GID to deck
    gidmap = {}

    -- Create a map of objects to base construction off of
    for tset in *map.tile_sets

        -- Texture for tile image
        texture = get_texture(tset.path)

        -- Width and height of texture
        w, h = tset.image_width,tset.image_height
        -- Width and height in tiles
        tilew, tileh = tset.tile_width,tset.tile_height
        -- Width and height of each individual tile
        tw, th = (w / tilew), (h / tileh)

        -- Counter for each ID
        gid = tset.first_id

        for y=1,th 
            for x=1,tw 
                x1, x2 = (x-1) * 1 / tw, (x) * 1 / tw
                y1, y2 = (y-1) * 1 / th, (y) * 1 / th
                quad = with MOAIGfxQuad2D.new()
                    \setTexture texture
                    -- Center tile on origin:
                    \setUVQuad x1, y1, 
                        x2, y1, 
                        x2, y2,
                        x1, y2
                    \setRect -tilew/2, tileh/2, 
                        tilew/2, -tileh/2

                assert(gidmap[gid] == nil, "Tile GID overlap, logic error!")
                gidmap[gid] = quad
                gid = gid + 1

    -- Function to convert a tile location to a real location
    C.tile_xy_to_real = (x, y) -> 
        return (x - y - .5)*map.iso_width, (x + y - .5)*map.iso_height

    -- Function to convert a real location to a tile location
    -- Returns 'nil' if not possible
    C.real_xy_to_tile = (rx, ry) -> 
        -- Solve the inverse function of above
        x_sub_y = rx / map.iso_width + .5
        x_plus_y = ry / map.iso_height + .5
        x, y = 
        return (x - y - .5)*map.iso_width, (x + y - .5)*map.iso_height

    --
    C.real_xy_snap = (rx, ry) -> 

    -- The MOAI layers to accumulate
    C.layers = {}

    -- Create the MOAI layers from the Tiled layers
    for lay in *map.layers
        w, h = lay.width, lay.height
        dx, dy = lay.x, lay.y

        layer = with MOAILayer2D.new()
            \setCamera(C.camera) -- All layers use the same camera
            \setViewport(C.viewport) -- All layers use the same viewport
            \setSortMode(MOAILayer.SORT_Y_ASCENDING)

        for y=1,h
            for x=1,w
                i = (y-1) * w + x
                gid = lay.data[i]
                if gid > 0 -- Is something here?
                    -- Create the prop
                    layer\insertProp with MOAIProp2D.new()
                        \setDeck(gidmap[gid])
                        \setLoc(C.tile_xy_to_real(x, y))

        append C.layers, layer

    -- Add the UI layer, which is sorted by priority (the default sort mode):
    C.ui_layer = with MOAILayer2D.new()
            \setCamera(C.camera) -- All layers use the same camera
            \setViewport(C.viewport) -- All layers use the same viewport

    append C.layers, C.ui_layer

    -- Setup function
    C.setup = () -> 
        -- Run a MOAIThread for scrolling by mouse
        text_box = with MOAITextBox.new()
            \setFont( font )
            \setTextSize( 24 )
            \setString( "" )
            \setRect(-128,-128,128,128)
            \setAlignment( MOAITextBox.CENTER_JUSTIFY, MOAITextBox.CENTER_JUSTIFY )

        C.ui_layer\insertProp(text_box)
        MOAIThread.new()\run () ->
           mX,mY = user_io.mouse_xy()
           dragging = false
           while true
               coroutine.yield()
               -- Handle dragging for scroll:
               if user_io.mouse_right_pressed()
                   dragging = true
               if user_io.mouse_right_released()
                   dragging = false
               if dragging and user_io.mouse_right_down() 
                   newMX,newMY = user_io.mouse_xy()
                   prevX, prevY = C.camera\getLoc()
                   C.camera\setLoc(prevX + (mX - newMX), prevY + (mY - newMY))

               mX,mY = user_io.mouse_xy()
               cX, cY = C.camera\getLoc()
               cX -= vieww/2
               cY -= viewh/2

               text_box\setString((mX+cY) .. ", " .. (mY+cY))
               text_box\setLoc((mX+cX), (mY+cY))
               text_box\setColor(1,1,0,1)

         -- Begin rendering the MOAI layers
        for layer in *C.layers
           MOAISim.pushRenderPass(layer)

    -- Tear-down function
    C.teardown = () -> 
        -- Cease rendering the MOAI layers
        for layer in *C.layers
            MOAISim.removeRenderPass(layer)

    return C


