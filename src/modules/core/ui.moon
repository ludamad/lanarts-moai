-- UI components that run on separate 'threads'.

import create_thread from require 'core.util'
import get_texture, get_json, get_resource_path, get_font from require "resources"
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
    return V.level.real_xy_to_tile(rX, rY)
 
-------------------------------------------------------------------------------
-- UI Components
-------------------------------------------------------------------------------

-- V: The level view
ui_ingame_scroll = (V) -> 
    -- First, create components
    text_box = with create_text(V.ui_layer)
        \setColor(1,1,0,1)

    if SHOW_DEBUG 
        V.ui_layer\insertProp(text_box)

    mX,mY = user_io.mouse_xy()
    dragging = false

    return () ->

        -- Handle dragging for scroll:
        if user_io.mouse_right_pressed()
            dragging = true
        if user_io.mouse_right_released()
            dragging = false
        if dragging and user_io.mouse_right_down() 
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
            text = rX .. ", " .. rY .. " => " .. tX .. ", " .. tY .. "\n FPS: " .. MOAISim.getPerformance()
            text ..= "\n Current frame: #{G.step_number}"
            for i=1,#V.gamestate.players
                is_local = V.gamestate.players[i].is_controlled
                if is_local
                    text ..= "\n Player #{i}: Local player"
                else
                    next_queued_action = V.gamestate.seek_action(i)
                    queued = if next_queued_action ~= nil then next_queued_action.step_number else G.fork_step_number
                    text ..= "\n Player #{i}: #{queued}"
            text_box\setString(text) 

            text_box\setLoc(rX, rY)

-- Runs a MOAIThread for selecting squares
-- V: The level components, from load_tiled_json
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
            sX,sY = V.level.tile_xy_to_real(tX, tY)
            -- Ad-hoc adjustments
            sX,sY = sX + 0, sY + 0 
            -- Set the location
            select_prop\setLoc(sX, sY)

return { :ui_ingame_scroll, :ui_ingame_select }
