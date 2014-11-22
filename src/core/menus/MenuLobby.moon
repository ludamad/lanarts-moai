import Display, InstanceBox, InstanceLine, Sprite, TextLabel, TextInputBox from require "ui"
import MENU_FONT, text_label_create, text_button_create from require "@menus.util_menu_common"

import DEFAULT_FONT, MENU_FONT, text_label_create, text_button_create, back_and_continue_options_create, make_text_label
        from require "@menus.util_menu_common"

import Lobby, Tasks from require "networking"

SETTINGS_BOX_MAX_CHARS = 18
SETTINGS_BOX_SIZE = {180, 34}

ENTRY_SIZE = {350, 40}
ENTRY_SPACING = 45
PLAYER_LIST_MAX_CHARS = 50

session_info = {
    username: nil,
    sessionId: nil
}

login_if_needed = () ->
    if session_info.username ~= _SETTINGS.username
        credentials = Lobby.guest_login(_SETTINGS.username)
        session_info.username = _SETTINGS.username
        session_info.sessionId = credentials.sessionId

--join_game_task_create = (entry_data) ->
--    tasks.create(function()
--            login_if_needed()
--            pretty_print( Lobby.join_game(session_info.username, session_info.sessionId, entry_data.id) )
--    end)
--end

-- A component that starts by displaying a loading animation until 'replace' is called
loading_box_create = (size) ->
    obj = InstanceBox.create {:size}

    loading_anim = Sprite.animation_create("loading_64x64.png", alpha: 0.25, size: {64,64}, frame_speed: 0.1)
    obj\add_instance(loading_anim, Display.CENTER_TOP, {0,50})
    -- Called when component has loaded
    contents = loading_anim
    obj.replace = (newcontents, origin) =>
        if contents then @remove(contents) 
        contents = newcontents
        @add_instance(newcontents, origin)
    return obj

-- For reference, this is how the received table looks
--sample_lobby_entry = { 
--    host = "ludamad",
--    creationTime = 1010010,
--    id = "51b002b8e1382367f2000003",
--    players = {
--        "ciribot",
--       "ludamad",
--    }
--}

local game_entry_draw
game_entry_create = (entry_number, entry_data) ->
    obj = {}
    obj.entry_data = entry_data
    obj.size = ENTRY_SIZE

    obj.step = (xy) =>
        bbox = bbox_create(xy, @size)
        -- if bbox_left_clicked(bbox) then
        --         join_game_task_create(obj.entry_data)
        --         print("Entry " .. entry_number .. " was clicked.")

    obj.draw = (xy) =>
        game_entry_draw(entry_number, @entry_data, bbox_create(xy, @size))
    return obj

-- Recreated every time the game set changes
game_entry_list_create = (entries) ->
    obj = InstanceLine.create( {dx: 0, dy: ENTRY_SPACING, per_row: 1} )
    for i=1,#entries
        obj\add_instance(game_entry_create(i, entries[i]))

    if #entries == 0
        return TextLabel.create font: MENU_FONT, text: "No Open Games Currently!\nConnected to #{_SETTINGS.lobby_server_url}"
    return obj

draw_in_box = (font, bbox, origin, offset, ...) ->
    string = ""
    for {col, text} in *{...}
        string ..= Display.colorEscapeCode(col)
        string ..= text
    {x, y} = origin_aligned(bbox, {0,0}, offset)
    Display.drawText(font, text, x, y)

player_list_string = (player_list, max_chars) ->
    str = (", ")\join(player_list)
    if #str > max_chars - 3
        str = str\sub(1, max_chars - 3) .. "..." 
    return str

game_entry_draw = (number, entry, bbox) ->
    game_number_color = vector_interpolate(COL_YELLOW, COL_DARK_GRAY, (number-1) / 10)
    draw_in_box MENU_FONT, bbox, Display.LEFT_CENTER, {-14,0}, 
        {game_number_color, number}
    draw_in_box DEFAULT_FONT, bbox, Display.LEFT_TOP, {0,18}, 
        {COL_WHITE, "Host: "}, 
        {COL_PALE_RED, entry.host}
    draw_in_box DEFAULT_FONT, bbox, Display.LEFT_TOP, {0,3}, 
        {COL_WHITE, "Players: "}, 
        {COL_MUTED_GREEN, player_list_string(entry.players, PLAYER_LIST_MAX_CHARS)}

    -- XXX: Find out why this returns nil on windows
    date = os.date("%I:%M%p", entry.creationTime)
    if date ~= nil then
        draw_in_box(DEFAULT_FONT, bbox, Display.RIGHT_TOP, {-5,20}, {COL_LIGHT_GRAY, date } )

    Display.drawRect( bbox_mouse_over(bbox) and COL_WHITE or COL_GRAY, bbox, 1 )

UPDATE_FREQUENCY = 5000 -- milliseconds
game_list_updater_create = (game_list) ->
    return coroutine.create () ->
        timer = nil
        while true
            while timer and timer\get_milliseconds() < UPDATE_FREQUENCY 
                coroutine.yield()
            timer = timer_create()
            response = Lobby.query_game_list()
            if response then
                game_list\replace( game_entry_list_create(response.gameList), Display.LEFT_TOP, {0,0} )

menu_lobby_start = (controller, on_back_click = do_nothing, on_game_click = do_nothing) ->
    -- Clear the previous layout
    Display.display_setup()

    -- Create the pieces
    menu = InstanceBox.create {size: vector_min({Display.display_size()}, {800, 600})}
    spr_title_trans = Sprite.image_create("LANARTS-transparent.png", alpha: 0.5)
    spr_title = Sprite.image_create("LANARTS.png")
    open_games = TextLabel.create font: MENU_FONT, text: "Open Games"
    game_list = loading_box_create({350, 400})
    menu\add_instance(game_list, Display.LEFT_TOP, {20, 200})

    {w, h} = menu.size
    right_side = InstanceBox.create size: {w/2, h}

    -- name_field = TextInputBox.create { 
    --     label_text: "Your name: ", size: SETTINGS_BOX_SIZE, font: small_font, max_chars: SETTINGS_BOX_MAX_CHARS
    -- }
    -- right_side\add_instance name_field, Display.CENTER, {0, -13}

    back_button = text_button_create {
        text: "Back" 
        on_click: on_back_click
        font: MENU_FONT
    }

    -- Create the layout
    with menu
        \add_instance spr_title_trans, Display.CENTER_TOP, {-10,30}
        \add_instance spr_title, Display.CENTER_TOP, {0,20}
        \add_instance right_side, Display.RIGHT_CENTER
        \add_instance open_games, Display.LEFT_TOP, {20,175}

    updatef = game_list_updater_create(game_list)
    Display.display_add_draw_func () ->
        menu\draw(0,0)
        coroutine.resume(updatef)

    while controller\is_active()
        menu\step(0,0)
        coroutine.yield()

return {start: menu_lobby_start}
