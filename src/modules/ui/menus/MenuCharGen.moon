import Display, InstanceBox, InstanceLine, Sprite, TextLabel, TextInputBox from require "ui"
import DEFAULT_FONT, MENU_FONT, text_label_create, text_button_create, back_and_continue_options_create, make_text_label
    from require "@menus.util_menu_common"
import ErrorReporting from require 'system'
import data from require 'core'
import ClassType from require 'stats'

user_io = require 'user_io'
res = require 'resources'

-- 'Global' class choice variables
_CLASS_CHOICE = ""
_MAGE_MAGIC_SKILL = "Fire"
_KNIGHT_WEAPON_SKILL = "Piercing"
_CLASS_OBJECT = nil

class_choice_buttons_create = () ->
    x_padding, y_padding = 32, 16
    font = MENU_FONT
    font_size = 24

    buttons = { 
        { "Mage", "menu/class-icons/wizard.png"}
        { "Knight", "menu/class-icons/fighter.png"}
        { "Archer", "menu/class-icons/archer.png"}
    }
    class_right_toggle = {Mage: "Knight", Knight: "Archer", Archer: "Mage"}
    class_left_toggle = table.value_key_invert(class_right_toggle)

    button_size = { 96, 96 + y_padding + font_size }
    button_row = InstanceLine.create {dx: button_size[1] + x_padding}

    container = InstanceBox.create size: {640, 210}
    -- Respond to a change in class choice:
    update = () ->
        container\clear()

        container\add_instance button_row, Display.CENTER_TOP
        if _CLASS_CHOICE == "Mage"
            container\add_instance mage_choice_toggle_create(update), Display.CENTER_BOTTOM
            _CLASS_OBJECT = ClassType.lookup("Mage")\on_create magic_skill: _MAGE_MAGIC_SKILL, weapon_skill: "Slashing Weapons"
        elseif _CLASS_CHOICE == "Knight"
            container\add_instance knight_choice_toggle_create(update), Display.CENTER_BOTTOM
            _CLASS_OBJECT = ClassType.lookup("Knight")\on_create weapon_skill: _KNIGHT_WEAPON_SKILL
        elseif _CLASS_CHOICE == "Archer"
            _CLASS_OBJECT = ClassType.lookup("Archer")\on_create {}

    button_row.step = (x, y) =>
        InstanceLine.step(@, x, y)

        -- Allow choosing a class by using left/right arrows or tab
        if user_io.key_pressed(user_io.K_LEFT)
            _CLASS_CHOICE = class_left_toggle[_CLASS_CHOICE] or "Mage"
            update()
        elseif user_io.key_pressed(user_io.K_RIGHT) or user_io.key_pressed(user_io.K_TAB) 
            _CLASS_CHOICE = class_right_toggle[_CLASS_CHOICE] or "Mage"
            update()
    button_row.draw = (x,y) =>
        InstanceLine.draw(@, x,y)

        text = if _CLASS_OBJECT == nil then "" else  _CLASS_OBJECT.name .. ":  " .. _CLASS_OBJECT.description
        {w,h} = @size
        Display.drawText {
            :font, :text, font_size: 14
            x: x + w/2,  y: y + h + 8, color: Display.COL_GOLD, origin: Display.CENTER_TOP
        }

    for i = 1, #buttons
        {class_name, sprite} = buttons[i]

        button_row\add_instance label_button_create { 
                size: button_size
                font: font
                font_size: font_size
                text: class_name
                sprite: res.get_texture(sprite)
            },
            (x, y) => -- color_formula
                if _CLASS_CHOICE == class_name then
                    return Display.COL_GOLD
                else 
                    return @mouse_over(x,y) and Display.COL_PALE_YELLOW or Display.COL_WHITE,
            (x, y) => -- on_click
                _CLASS_CHOICE = class_name 
                update()

    -- Return surrounding box, with additional class choices
    update()
    return container

knight_choice_toggle_create = (root_update) ->
    toggle = {
        size: {300,32},
        font: DEFAULT_FONT,
    }

    skill_left_toggle = {
        Piercing: "Slashing", Slashing: "Blunt", Blunt: "Piercing"
    }
    skill_right_toggle = table.value_key_invert(skill_left_toggle)

    -- Calculated on any change of skill choice
    -- Initialize
    sprite = data.get_sprite('skicon-' .. _MAGE_MAGIC_SKILL\lower())
    text = _KNIGHT_WEAPON_SKILL
    text_color = TEXT_COLOR

    toggle.step = (x, y) =>
        -- Toggle the connection type
        if user_io.mouse_left_pressed() and mouse_over({x, y}, @size)
            _KNIGHT_WEAPON_SKILL = skill_left_toggle[_KNIGHT_WEAPON_SKILL]
        elseif user_io.mouse_right_pressed() and mouse_over({x, y}, @size)
            _KNIGHT_WEAPON_SKILL = skill_right_toggle[_KNIGHT_WEAPON_SKILL]
        root_update()

    toggle.draw = (x, y) =>
        w, h = unpack(@size)

        box_color = Display.COL_WHITE
        if mouse_over({x, y}, @size) 
            box_color = Display.COL_GOLD

        spr_w, spr_h = sprite.w, sprite.h
        sprite\draw(x, y+h/2, 1, 1, 0, 0.5)
        Display.drawText {
            font: @font
            color: Display.COL_GOLD, origin: Display.LEFT_BOTTOM 
            x: x, y: y - 5
            text: "Knight Fighting Focus:"
        }
        Display.drawText font: @font, font_size: 12, :text, x: x+8+spr_h, y: y+h/2, color: text_color, origin_y: 0.5
        Display.drawRect(bbox_create({x,y}, @size), box_color)

    return toggle

mage_choice_toggle_create = (root_update) ->
    toggle = {
        size: {300,32},
        font: DEFAULT_FONT,
    }

    skill_left_toggle = {
        Fire: "Water", Water: "Dark", Dark: "Light", Light: "Curses", Curses: "Enchantments"
        Enchantments: "Force", Force: "Earth", Earth: "Air", Air: "Fire"
    }
    skill_right_toggle = table.value_key_invert(skill_left_toggle)

    -- Calculated on any change of skill choice
    sprite = data.get_sprite('skicon-' .. _MAGE_MAGIC_SKILL\lower())
    text = _CLASS_OBJECT.name .. ' (' .. _MAGE_MAGIC_SKILL .. ' Focus)'
    text_color = TEXT_COLOR

    toggle.step = (x, y) =>
        -- Toggle the connection type
        if user_io.mouse_left_pressed() and mouse_over({x, y}, @size)
            _MAGE_MAGIC_SKILL = skill_left_toggle[_MAGE_MAGIC_SKILL]
        elseif user_io.mouse_right_pressed() and mouse_over({x, y}, @size)
            _MAGE_MAGIC_SKILL = skill_right_toggle[_MAGE_MAGIC_SKILL]
        root_update()

    toggle.draw = (x, y) =>
        w, h = unpack(@size)

        box_color = Display.COL_WHITE
        if mouse_over({x, y}, @size) 
            box_color = Display.COL_GOLD

        spr_w, spr_h = sprite.w, sprite.h
        sprite\draw(x, y+h/2, 1, 1, 0, 0.5)
        Display.drawText {
            font: @font
            color: Display.COL_GOLD, origin: Display.LEFT_BOTTOM 
            x: x, y: y - 5
            text: "Mage Path:"
        }
        Display.drawText font: @font, font_size: 12, :text, x: x+8+spr_h, y: y+h/2, color: text_color, origin_y: 0.5
        Display.drawRect(bbox_create({x,y}, @size), box_color)

    return toggle

choose_class_message_create = () ->
    label = make_text_label "Choose your Class!"

    label.step = (x, y) => -- Makeshift inheritance
        TextLabel.step(@, x, y)
        @set_color()

    label.set_color = () =>
        @color = if _CLASS_CHOICE == "" then Display.COL_PALE_RED else Display.COL_INVISIBLE

    label\set_color() -- Ensure correct starting color

    return label

menu_chargen_content = () ->
    return with InstanceBox.create size: _SETTINGS.window_size
        \add_instance class_choice_buttons_create(), 
            Display.CENTER_TOP, { 0, 50 } --Down 50 pixels

        \add_instance choose_class_message_create(), 
            Display.CENTER_BOTTOM, { 0, -50 } -- Up 50 pixels

        \add_instance back_and_continue_options_create(on_back_click, on_start_click), 
            Display.CENTER_BOTTOM, { 0, -20 } --Up 20 pixels

menu_chargen = (controller, on_back_click, on_start_click) ->
    -- Clear the previous layout
    Display.display_setup()
    box_menu = menu_settings_content(on_back_click, on_start_click)
    Display.display_add_draw_func () ->
        ErrorReporting.wrap(() -> box_menu\draw(0,0))()

    while controller\is_active()
        box_menu\step(0,0)
        coroutine.yield()

return {start: menu_chargen}
