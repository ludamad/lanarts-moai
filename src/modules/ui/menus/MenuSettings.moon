import Display, InstanceBox, InstanceLine, Sprite, TextLabel, TextInputBox from require "ui"
import DEFAULT_FONT, MENU_FONT, text_label_create, text_button_create from require "@menus.util_menu"
import ErrorReporting from require 'system'
user_io = require 'user_io'
res = require 'resources'

SETTINGS_BOX_MAX_CHARS = 18
SETTINGS_BOX_SIZE = {180, 34}

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

label_button_create = (params, color_formula, on_click) ->
    sprite = Sprite.create(params.sprite, { color: Display.COL_WHITE })
    label = TextLabel.create font: params.font, font_size: (params.font_size or 12), text: params.text

    params.size = params.size or label.size

    label_button = InstanceBox.create( params )

    label_button\add_instance( sprite, Display.CENTER_TOP )
    label_button\add_instance( label, Display.CENTER_TOP, {0, params.size[2] - params.font_size}) -- Offset to near the bottom

    label_button.step = (x, y) => -- Makeshift inheritance
        InstanceBox.step(self, x, y)

        if @mouse_over(x,y) and user_io.mouse_left_pressed() 
            on_click(@, x, y)

        color = color_formula(@, x, y)
        sprite.color = color
        label.color = (color == Display.COL_WHITE) and TEXT_COLOR or color

    return label_button

class_choice_buttons_create = () ->
    x_padding, y_padding = 32, 16
    font = MENU_FONT
    font_size = 24

    buttons = { 
        { "Mage", "menu/class-icons/wizard.png"},
        { "Fighter", "menu/class-icons/fighter.png"},
        { "Archer", "menu/class-icons/archer.png"}
    }

    button_size = { 96, 96 + y_padding + font_size }
    button_row = InstanceLine.create( { dx: button_size[1] + x_padding } )

    button_row.step = (x, y) =>
        InstanceLine.step(self, x, y)

        -- Allow choosing a class by using left/right arrows or tab
        if user_io.key_pressed(user_io.K_LEFT)
            _SETTINGS.class_type = ( _SETTINGS.class_type - 1 ) % #buttons
        elseif user_io.key_pressed(user_io.K_RIGHT) or user_io.key_pressed(user_io.K_TAB) 
            _SETTINGS.class_type = ( _SETTINGS.class_type + 1 ) % #buttons

    for i = 1, #buttons
        button = buttons[i]

        button_row\add_instance label_button_create { 
                size: button_size,
                font: font,
                font_size: font_size,
                text: button[1],
                sprite: res.get_texture(button[2]) 
            },
            (x, y) => -- color_formula
                if _SETTINGS.class_type == i-1 then
                    return Display.COL_GOLD
                else 
                    return @mouse_over(x,y) and Display.COL_PALE_YELLOW or Display.COL_WHITE,
            (x, y) => -- on_click
                _SETTINGS.class_type = i-1

    return button_row

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

make_text_label = (text) ->
    TextLabel.create font: DEFAULT_FONT, font_size: 12, :text

choose_class_message_create = () ->
    label = make_text_label "Choose your Class!"

    label.step = (x, y) => -- Makeshift inheritance
        TextLabel.step(@, x, y)
        @set_color()

    label.set_color = () =>
        @color = _SETTINGS.class_type == -1 and Display.COL_PALE_RED or Display.COL_INVISIBLE

    label\set_color() -- Ensure correct starting color

    return label

back_and_continue_options_create = (on_back_click, on_start_click) ->
    font = DEFAULT_FONT
    options = InstanceLine.create( { dx: 200 } )

    -- associate each label with a handler
    -- we make use of the ability to have objects as keys
    components = {
        [ make_text_label "Back"  ]: on_back_click or do_nothing
        [ make_text_label "Start" ]: on_start_click or do_nothing
    }

    for obj, handler in pairs(components)
        options\add_instance(obj)

    options.step = (x, y) => -- Makeshift inheritance
        InstanceLine.step(@, x,y)
        for obj, obj_x, obj_y in @instances(x,y) do
            click_handler = components[obj]

            mouse_is_over = obj\mouse_over(obj_x, obj_y)
            obj.color = mouse_is_over and Display.COL_GOLD or TEXT_COLOR

            if mouse_is_over and user_io.mouse_left_pressed() then click_handler()

    return options

menu_content_settings = (on_back_click, on_start_click) ->
    return with InstanceBox.create size: _SETTINGS.window_size
        \add_instance class_choice_buttons_create(), 
            Display.CENTER_TOP, { 0, 50 } --Down 50 pixels

        \add_instance center_setting_fields_create(),
            {0.50, 0.70}

        \add_instance back_and_continue_options_create(on_back_click, on_start_click), 
            Display.CENTER_BOTTOM, { 0, -20 } --Up 20 pixels

        \add_instance choose_class_message_create(), 
            Display.CENTER_BOTTOM, { 0, -50 } -- Up 50 pixels

    return fields


menu_settings = (controller, on_back_click, on_start_click) ->
    -- Clear the previous layout
    Display.display_setup()
    box_menu = menu_content_settings(on_back_click, on_start_click)
    Display.display_add_draw_func () ->
        ErrorReporting.wrap(() -> box_menu\draw(0,0))()

    while controller\is_active()
        box_menu\step(0,0)
        coroutine.yield()

return {start: menu_settings}