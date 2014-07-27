import Display, InstanceBox, InstanceLine, Sprite, TextLabel, TextInputBox from require "ui"
import DEFAULT_FONT, MENU_FONT, text_label_create, text_button_create, back_and_continue_options_create, make_text_label
    from require "@menus.util_menu_common"
import ErrorReporting from require 'system'
import data from require 'core'
import ClassType from require 'stats'

user_io = require 'user_io'
res = require 'resources'

SETTINGS_BOX_MAX_CHARS = 18
SETTINGS_BOX_SIZE = {200, 34}

TEXT_COLOR = {255/255, 250/255, 240/255}
CONFIG_MENU_SIZE = {640, 480}

-- Adds common settings for text field functions that take size, font & max_chars
settings_text_field_params = (params) ->
    params = params or {}
    params.size = params.size or SETTINGS_BOX_SIZE
    params.font = params.font or DEFAULT_FONT
    params.max_chars = params.max_chars or SETTINGS_BOX_MAX_CHARS
    return params

is_valid_ip_string = (text) ->
    if text == "localhost" then return true

    parts = text\split(".")

    -- Valid IP string has 4 components, eg 1.2.3.4
    if #parts ~= 4 then return false

    -- Assert all components are numbers <= 255
    for part in values(parts)
        number = tonumber(part)
        if number == nil then return false
        if number < 0 or number > 255 then return false

    return true

host_IP_field_create = () ->
    params = settings_text_field_params {
        label_text: "Server IP:"
        default_text: _SETTINGS.server_ip
        input_callbacks: { -- Field validating & updating 
            update: () => -- Update host IP based on contents
                _SETTINGS.server_ip = @text
            valid_string: is_valid_ip_string
        }
    }
    return text_field_create(params)

connection_port_field_create = () ->
    params = settings_text_field_params {
        label_text: "Connection Port:"
        default_text: _SETTINGS.server_port
        input_callbacks: { -- Field validating & updating 
            update: () => -- Update connection port based on contents
                _SETTINGS.server_port = tonumber(@text)
            valid_string: tonumber
        }
    }
    return text_field_create(params)

connection_toggle_create = () ->

    client_option_image = res.get_texture("menu/client_icon.png")
    server_option_image = res.get_texture("menu/server_icon.png")
    single_player_option_image = res.get_texture("menu/single_player_icon.png")

    toggle = { 
        size: SETTINGS_BOX_SIZE,
        font: DEFAULT_FONT
    }

    toggle.step = (x, y) =>
        -- Toggle the connection type
        if user_io.mouse_left_pressed() and mouse_over({x,y}, self.size) then
            NEXT_TOGGLE = {["client"]: "server", ["server"]: "single_player", ["single_player"]: "client"}
            _SETTINGS.gametype = NEXT_TOGGLE[_SETTINGS.gametype]

    toggle.draw = (x, y) =>
        -- Draw the connection type
        local text, color, box_color, sprite

        if _SETTINGS.gametype == "client" then
            text = "Connect to a game"
            color = Display.COL_MUTED_GREEN
            sprite = client_option_image
        elseif _SETTINGS.gametype == "server" then
            text = "Host a game"
            color = Display.COL_PALE_RED
            sprite = server_option_image
        else -- _SETTINGS.gametype == "single_player"
            text = "Single-player"
            color = Display.COL_BABY_BLUE
            sprite = single_player_option_image

        {w,h} = @size
        spr_w, spr_h = sprite\getSize()
        Display.drawTexture texture: sprite, x: x, y: y+h/2, :color, origin_y: 0.5
        Display.drawText font: @font, font_size: 12, :text, x: x+8+spr_h, y: y+h/2, :color, origin_y: 0.5

        box_color = mouse_over({x,y}, self.size) and Display.COL_GOLD or color
        Display.drawRect(bbox_create({x,y}, @size), box_color)

    return toggle

respawn_toggle_create = () ->
    toggle = {
        size: SETTINGS_BOX_SIZE,
        font: DEFAULT_FONT,
    }

    respawn = res.get_texture("menu/respawn_setting.png")
    hardcore = res.get_texture("menu/hardcore_setting.png")

    toggle.step = (x, y) =>
        -- Toggle the connection type
        if user_io.mouse_left_pressed() and mouse_over({x, y}, self.size)
            _SETTINGS.regen_on_death = not _SETTINGS.regen_on_death

    toggle.draw = (x, y) =>
        sprite = _SETTINGS.regen_on_death and respawn or hardcore

        w, h = unpack(@size)

        text = _SETTINGS.regen_on_death and "Respawn on Death" or "Hardcore (No respawn!)"
        text_color = _SETTINGS.regen_on_death and TEXT_COLOR or Display.COL_LIGHT_RED
        sprite_color = _SETTINGS.regen_on_death and TEXT_COLOR or Display.COL_LIGHT_RED
        box_color = sprite_color

        if mouse_over({x, y}, self.size) 
            box_color = Display.COL_GOLD

        spr_w, spr_h = sprite\getSize()
        Display.drawTexture texture: sprite, x: x, y: y+h/2, color: sprite_color, origin_y: 0.5
        Display.drawText font: @font, font_size: 12, :text, x: x+8+spr_h, y: y+h/2, color: text_color, origin_y: 0.5
        Display.drawRect(bbox_create({x,y}, @size), box_color)

    return toggle

frame_action_repeat_toggle_create = () ->
    toggle = { 
        size: SETTINGS_BOX_SIZE,
        large_font: DEFAULT_FONT,
        font: DEFAULT_FONT,
    }

    toggle.step = (x, y) =>
        -- Toggle the connection type
        mouseover = mouse_over({x, y}, self.size)
        if user_io.mouse_left_pressed() and mouseover 
            _SETTINGS.frame_action_repeat = (_SETTINGS.frame_action_repeat + 1) % 5
        elseif user_io.mouse_right_pressed() and mouseover 
            _SETTINGS.frame_action_repeat = (_SETTINGS.frame_action_repeat - 1) % 5

    toggle.draw = (x, y) =>

        w, h = unpack(@size)
        Display.drawText {
            font: @font, font_size: 12
            text: (_SETTINGS.frame_action_repeat+1) .. 'x'
            x: x + 8,  y: y + h / 2, color: Display.COL_GREEN, origin: Display.LEFT_CENTER
        }
        Display.drawText {
            font: @font, font_size: 12
            text: "Network Skip Rate" 
            x: x + 40, y: y + h / 2, color: Display.COL_PALE_GREEN, origin: Display.LEFT_CENTER
        }
    
        box_color = mouse_over({x, y}, self.size) and Display.COL_GOLD or Display.COL_PALE_GREEN
        Display.draw_rectangle_outline(box_color, bbox_create({x, y}, self.size), 1)

    return toggle

speed_description = (frames_per_second) ->
    if frames_per_second <= 100 then
        "Very Fast"
    elseif frames_per_second <= 60 then
        "Fast"
    elseif frames_per_second <= 45 then
        "Normal"
    else
        "Slow"

speed_toggle_create = () ->
    toggle = { 
        size: SETTINGS_BOX_SIZE
        font: DEFAULT_FONT
        sprite: res.get_texture("menu/speed_setting.png")
    }

    toggle.step = (x, y) =>
        -- Toggle the connection type
        if user_io.mouse_left_pressed() and mouse_over({x, y}, self.size)
            FRAMES_TOGGLE = {[100]: 30, [30]: 45, [45]:60, [60]: 100}
            _SETTINGS.frames_per_second = FRAMES_TOGGLE[_SETTINGS.frames_per_second] or 30

    toggle.draw = (x, y) =>
        text = "Speed: " .. speed_description(_SETTINGS.frames_per_second)
   
        alpha = 1 - (_SETTINGS.frames_per_second - 100) / 100

        w, h = unpack(@size)

        spr_w, spr_h = @sprite\getSize()
        Display.drawTexture texture: @sprite, x: x, y: y+h/2, color: {1, 1, 1, alpha}, origin: Display.LEFT_CENTER
        Display.drawText font: @font, font_size: 12, :text, x: x + 8 + spr_h, y: y + h / 2, color: TEXT_COLOR, origin: Display.LEFT_CENTER
    
        box_color = mouse_over({x, y}, self.size) and Display.COL_GOLD or Display.COL_WHITE
        Display.drawRect(bbox_create({x, y}, self.size), box_color)

    return toggle

center_setting_fields_create = () ->
    fields = InstanceLine.create force_size: {500, 162}, dx: 320, dy: 64, per_row: 2

    local current_setting
    -- Adds different options depending on the connection type
    add_fields = () =>
        current_setting = _SETTINGS.gametype

        @clear()

        @add_instance( connection_toggle_create() )

        if current_setting ~= "client" or true
            @add_instance( respawn_toggle_create() )
            @add_instance( speed_toggle_create() )
            @add_instance( host_IP_field_create() )

        if current_setting == "server"
           @add_instance( frame_action_repeat_toggle_create() )

        name_field = name_field_create( settings_text_field_params() )
        @add_instance(name_field)

        if current_setting ~= "single_player"
            @add_instance( connection_port_field_create() )
    
    add_fields(fields) -- Do initial creation

    fields.step = (x, y) => -- Makeshift inheritance
        InstanceLine.step(@, x, y)
        if current_setting ~= _SETTINGS.gametype 
            add_fields(@)

    return fields

menu_settings_content = (on_back_click, on_start_click) ->
    return with InstanceBox.create size: _SETTINGS.window_size
        \add_instance make_text_label("Game Settings", 32, Display.COL_WHITE),
            {0.50, 0.15}

        \add_instance center_setting_fields_create(),
            {0.50, 0.50}, {-10,0} -- Left 10 pixels

        \add_instance back_and_continue_options_create(on_back_click, on_start_click), 
            Display.CENTER_BOTTOM, { 0, -20 } --Up 20 pixels

    return fields


menu_settings = (controller, on_back_click, on_start_click) ->
    -- Clear the previous layout
    Display.display_setup()
    box_menu = menu_settings_content(on_back_click, on_start_click)
    Display.display_add_draw_func () ->
        ErrorReporting.wrap(() -> box_menu\draw(0,0))()

    while controller\is_active()
        box_menu\step(0,0)
        coroutine.yield()

return {start: menu_settings}
