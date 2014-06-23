local util_draw = require "core.util_draw"

local InstanceBox = require "ui.InstanceBox"
local Sprite = require "ui.Sprite"
local TextLabel = require "ui.TextLabel"

local Display = require "lanarts.draw"

local GameSettingsMenu = require "@menus.GameSettingsMenu"
local LobbyMenu = require "@menus.LobbyMenu"
local PregameMenu = require "@menus.PregameMenu"
local ScoresMenu = require "@menus.ScoresMenu"

-- local Tasks = require "networking.Tasks"
local user_io = require "user_io"
    
-- START SCREEN -- 
local text_button_params = {
    font = font_cached_load(_SETTINGS.menu_font, 20),
    color = {255, 250, 240},
    hover_color = COL_RED,
    click_box_padding = 5
}

local function start_menu_create(on_start_click, on_join_click, on_load_click, on_score_click)
    local menu = InstanceBox.create( { size = _SETTINGS.window_size } )
    local transparent_sprite =  Sprite.image_create(path_resolve "LANARTS-transparent.png")
    transparent_sprite.options.color= {255, 255, 255, 50}
    menu:add_instance(transparent_sprite, Display.CENTER_TOP, {-15, 45})

    menu:add_instance(
        Sprite.image_create(path_resolve "LANARTS.png"),
        Display.CENTER_TOP,
        --[[Down 10 pixels]]
        {0, 30}
    )

    local y_position = 70 -- Start down 70 pixels
    menu:add_instance(
        text_button_create("Start or Join a Game", on_start_click, text_button_params),
        Display.CENTER,
        {0, y_position}
    )
    y_position = y_position + 50

--    menu:add_instance(
--        text_button_create("Browse Hosted Games", on_join_click, text_button_params),
--        Display.CENTER,
--        {0, y_position}
--    )
--    y_position = y_position + 50

    if file_exists("saves/savefile.save") then
        menu:add_instance(
            text_button_create("Continue Game", on_load_click, text_button_params),
            Display.CENTER,
            {0, y_position}
        )
        y_position = y_position + 50
    end

    menu:add_instance(
        text_button_create("Highscores", on_score_click, text_button_params),
        Display.CENTER,
        {0, y_position}
    )
    y_position = y_position + 50

    function menu:step(xy) -- Makeshift inheritance
       InstanceBox.step(self, xy)
       if user_io.key_pressed('K_N') then
            on_start_click()
       elseif user_io.key_pressed('K_S') then
            on_score_click()
       end 
    end

    return menu
end


-- MAIN --

DEBUG_LAYOUTS = false

local menu_state = { exit_game = false }

local exit_menu -- forward declare
local setup_start_menu -- forward declare
local setup_settings_menu -- forward declare
local setup_pregame_menu -- forward declare
local setup_scores_menu -- forward declare
local setup_lobby_menu -- forward declare

function exit_menu(exit_game)
    -- Signals event loop that menu is finished
    menu_state.menu = nil
    menu_state.back = nil
    menu_state.continue = nil
    menu_state.exit_game = exit_game
end

function setup_start_menu()
    menu_state.menu = InstanceBox.create( { size = _SETTINGS.window_size } )

    menu_state.back = function() 
        exit_menu(--[[Quit game]] true) 
    end    

    local function on_load_click()
--        game_loop.loop_control.startup_function = function()
--            if file_exists("saves/savefile.save") then
--                GameState.load("saves/savefile.save")
--            end
--        end
	_SETTINGS.connection_type = Network.NONE
        exit_menu()
    end

    if file_exists("saves/savefile.save") then
        menu_state.continue = on_load_click
    else 
        menu_state.continue = setup_settings_menu
    end

    menu_state.menu:add_instance(
        start_menu_create( --[[New Game Button]] setup_settings_menu, --[[Join Game Button]] setup_lobby_menu, 
            --[[Load Game Button]] on_load_click, --[[Highscores Button]] setup_scores_menu),
        Display.CENTER
    )
end

function setup_settings_menu()
    menu_state.menu = InstanceBox.create( { size = _SETTINGS.window_size } )
    
    menu_state.back = setup_start_menu
    menu_state.continue = function ()
        if _SETTINGS.class_type ~= -1 then
            exit_menu()
        end
    end

    menu_state.menu:add_instance(
        GameSettingsMenu.create( --[[Back Button]] menu_state.back, --[[Start Game Button]] menu_state.continue), 
        Display.CENTER
    )
end

function setup_pregame_menu()
    menu_state.menu = InstanceBox.create( { size = _SETTINGS.window_size } )

    menu_state.back =  function() 
        exit_menu(--[[Quit game]] true) 
    end
    menu_state.continue = exit_menu
    menu_state.menu:add_instance(
        PregameMenu.create( --[[Start Game Button]] menu_state.continue ),
        Display.CENTER
    )
end

function setup_scores_menu()
    menu_state.menu = InstanceBox.create( { size = _SETTINGS.window_size } )
    menu_state.back = setup_start_menu
    menu_state.continue = nil
    menu_state.menu:add_instance(
        ScoresMenu.create( --[[Back Button]] menu_state.back ),
        Display.CENTER
    )
end

function setup_lobby_menu()
    menu_state.menu = InstanceBox.create( { size = _SETTINGS.window_size } )
    menu_state.back = setup_start_menu
    menu_state.continue = nil
    menu_state.menu:add_instance(
        LobbyMenu.create( --[[Back Button]] menu_state.back ),
        Display.CENTER
    )
end

local function menu_loop(should_poll)
    local exit_game = false
    local loop = util_draw.setup_draw_loop(function()
        if user_io.key_pressed("K_F9") then
            -- note, globals are usually protected against being changed
            -- but a bypass is allowed for cases where it must be done
            setglobal("DEBUG_LAYOUTS", not DEBUG_LAYOUTS) -- flip on/off
        end

        if should_poll then
            Network.connections_poll()
        end

        menu_state.menu:step( {0, 0} )

        if user_io.key_pressed("K_ESCAPE") and menu_state.back then
            menu_state.back()
        elseif user_io.key_pressed("K_ENTER") and menu_state.continue then
            menu_state.continue()
        end

        if not menu_state.menu then -- because we have moved on 
            return not menu_state.exit_game
        end

        menu_state.menu:draw( {0, 0} )
        -- Tasks.run_all()
    end)
    loop.start()

    return exit_game -- Has user has quit the game?
end

-- Submodule
return {
    start_menu_show = function()
        setup_start_menu()

        return menu_loop(--[[Do not poll connections]] false)
    end
    , pregame_menu_show = function()
        setup_pregame_menu()

        return menu_loop(--[[Poll connections]] true)
    end
}