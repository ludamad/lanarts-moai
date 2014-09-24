-- UI components that run on separate 'threads'.

import thread_create from require 'core.util'
import get_texture, get_json, get_resource_path, get_font from require "resources"
import Display from require "ui"
user_io = require "user_io"
ErrorReporting = require "system.ErrorReporting"

-- Draw various debugging components?
SHOW_DEBUG = true

-------------------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------------------

create_text = (layer) ->
    text = with MOAITextBox.new()
        \setFont(get_font 'LiberationMono-Regular.ttf')
        \setTextSize( 12 )
        \setString( "" )
        \setRect(-128,-128,128,128)
        \setAlignment( MOAITextBox.CENTER_JUSTIFY, MOAITextBox.CENTER_JUSTIFY )
    layer\insertProp(text)
    return text

real_mouse_xy = (V) ->
    mX, mY = user_io.mouse_xy()
    cX, cY = V.camera\getLoc()
    return mX + cX - V.cameraw/2, mY + cY - V.camerah/2

tile_mouse_xy = (V) ->
    rX, rY = real_mouse_xy(V)
    return V.map.real_xy_to_tile(rX, rY)
 
 -- Textbox pseudo-method
 -- Hack to fit textbox based on its contents
textbox_fit_text = (x, y, text, align_x = 0, align_y = 0) =>
    -- Arbitrarily big
    BIG = 1000
    @setAlignment(MOAITextBox.LEFT_JUSTIFY, MOAITextBox.LEFT_JUSTIFY)
    @setRect(x, y, x + BIG, y + BIG)
    @setString(text)

    x1, y1, x2, y2 = @getStringBounds(1,#text)
    w,h = (x2 - x1), (y2 - y1)
    a1x,a2x = align_x, 1 - align_x
    a1y,a2y = align_y, 1 - align_y
    @setRect(math.floor(x - w*a1x), math.floor(y - h*a1x), math.ceil(x + w*a2x), math.ceil(y + h*a2y))

-------------------------------------------------------------------------------
-- UI Components
-------------------------------------------------------------------------------

-- V: The map view
ui_ingame_scroll = (V) -> 
    -- First, create components
    text_box = with create_text(V.ui_layer)
        \setColor(1,1,0,1)

    if SHOW_DEBUG 
        V.ui_layer\insertProp(text_box)

    mX,mY = user_io.mouse_xy()
    dragging = false
    dragging_on_minimap = false

    return () ->

        -- Handle dragging for scroll:
        if user_io.mouse_right_pressed()
            dragging = true
            dragging_on_minimap = V.sidebar.minimap\mouse_over()
        if user_io.mouse_right_released()
            dragging = false
        if dragging and user_io.mouse_right_down() 
            if dragging_on_minimap
                newMX,newMY = user_io.mouse_xy()
                print(newMX - mX, newMY - mY)
                speed = 128
                Display.camera_move_delta((mX - newMX) * speed, (mY - newMY) * speed, speed)
            else -- Dragging on map
                newMX,newMY = user_io.mouse_xy()
                prevX, prevY = V.camera\getLoc()
                V.camera\setLoc(prevX + (mX - newMX), prevY + (mY - newMY))

        -- Update last mouse-recorded mouse position:
        mX,mY = user_io.mouse_xy()

        G = V.gamestate
        -- Show coordinates, if SHOW_DEBUG is true
        if SHOW_DEBUG
            rX,rY = real_mouse_xy(V)
            tX,tY = tile_mouse_xy(V)
            -- Handle nils
            tX,tY = tX or "-", tY or "-"
            text = rX .. ", " .. rY .. " => " .. tX .. ", " .. tY .. "\nFPS: " .. MOAISim.getPerformance()
            text ..= "\nCurrent frame: #{G.step_number}"
            text ..= "\nLast forked frame: #{G.fork_step_number}"
            for i=1,#G.players
                is_local = G.players[i].is_controlled
                if is_local
                    text ..= "\nPlayer #{i}: Local player"
                else
                    next_queued_action = V.gamestate.seek_action(i)
                    best_queued_action = V.gamestate.bseek_action(i)
                    queued = if next_queued_action ~= nil then next_queued_action.step_number else G.fork_step_number
                    bqueued = if best_queued_action ~= nil then best_queued_action.step_number else G.fork_step_number
                    text ..= "\nPlayer #{i}: #{queued} CURRENT #{G.step_number - queued} and #{G.step_number - bqueued} BEHIND"
            if G.net_handler and type(G.net_handler.last_acknowledged_frame) == "number"
                text ..= "\nLAST ACK #{G.net_handler.last_acknowledged_frame}"
            if G.net_handler and type(G.net_handler.last_acknowledged_frame) == "table"
                for k,v in pairs(G.net_handler.last_acknowledged_frame)
                    id = G.peer_player_id(k)
                    text ..= "\nLAST ACK for player #{id}: #{v}"


            textbox_fit_text(text_box, 0, 0, text)

-- Runs a MOAIThread for selecting squares
-- V: The map components, from load_tiled_json
ui_ingame_select = (V) ->

    texture = (get_texture "highlight32x32.png")
    tilew, tileh = texture\getSize()
    select_prop = with MOAIProp2D.new()
        \setBlendMode(MOAIProp.GL_SRC_ALPHA, MOAIProp.GL_ONE_MINUS_SRC_ALPHA)
        \setColor(1,1,1,0.1)
        \setDeck with MOAIGfxQuad2D.new()
            \setTexture(texture)
            -- Center tile on origin:
            \setRect -tilew/2, tileh/2, 
                tilew/2, -tileh/2

    V.ui_layer\insertProp(select_prop)

    return () ->
        -- Get the mouse position
        tX,tY = tile_mouse_xy(V)
        if tX and tY
            sX,sY = V.map.tile_xy_to_real(tX, tY)
            -- Ad-hoc adjustments
            sX,sY = sX + 0, sY + 0 
            -- Set the location
            select_prop\setLoc(sX, sY)

return { :ui_ingame_scroll, :ui_ingame_select }
