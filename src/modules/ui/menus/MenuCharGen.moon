import Display, InstanceBox, InstanceLine, Sprite, TextLabel, TextInputBox from require "ui"
import DEFAULT_FONT, MENU_FONT, text_label_create, text_button_create, back_and_continue_options_create, make_text_label
    from require "@menus.util_menu_common"
statsystem = require "statsystem"
import ErrorReporting from require 'system'
import data from require 'core'

user_io = require 'user_io'
res = require 'resources'

TEXT_COLOR = {255/255, 250/255, 240/255}

-- 'Global' class choice variables
_CLASS_CHOICE = "Knight"
_CLASS_ARGS = nil
_RACE_CHOICE = "Human"
_MAGE_MAGIC_SKILL = "fire_mastery"
_WEAPON_SKILL = "piercing_weapons"
_STAT_OBJECT = nil

update_stat_object = () ->
    if _CLASS_CHOICE ~= nil
        race = statsystem.races[_RACE_CHOICE]
        -- Note: We pass 'false' to indicate the PlayerStatContext has no proper GameObject associated with it.
        stats = statsystem.PlayerStatContext.create(false, _SETTINGS.player_name, _RACE_CHOICE)
        race.stat_race_adjustments(stats)
        statsystem.classes[_CLASS_CHOICE].stat_class_adjustments(_CLASS_ARGS, stats)
        stats\calculate()
        _STAT_OBJECT = stats

local class_choice_buttons_create
do -- Defines class_choice_buttons_create, hides related functions
  -- 'Private'
  weapon_choice_toggle_create = (root_update, include_bows = false) ->
    toggle = {
        size: {300,32},
        font: DEFAULT_FONT,
    }

    skill_left_toggle = {
        ["piercing_weapons"]: "slashing_weapons"
        ["slashing_weapons"]: "blunt_weapons"
        ["blunt_weapons"]: "piercing_weapons"
    }
    if include_bows
        -- Include ranged weapons in the toggle options:
        skill_left_toggle["blunt_weapons"] = "ranged_weapons"
        skill_left_toggle["ranged_weapons"] = "piercing_weapons"

    skill_right_toggle = table.value_key_invert(skill_left_toggle)

    -- Calculated on any change of skill choice
    -- Initialize
    sprite = data.get_sprite('skicon-'.._WEAPON_SKILL)
    text = statsystem.SKILL_ATTRIBUTE_NAMES[_WEAPON_SKILL]
    text_color = TEXT_COLOR

    toggle.step = (x, y) =>
        -- Toggle the connection type
        if user_io.mouse_left_pressed() and mouse_over({x, y}, @size)
            _WEAPON_SKILL = skill_left_toggle[_WEAPON_SKILL]
        elseif user_io.mouse_right_pressed() and mouse_over({x, y}, @size)
            _WEAPON_SKILL = skill_right_toggle[_WEAPON_SKILL]
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
            text: "Weapon Style:"
        }
        Display.drawText font: @font, font_size: 12, :text, x: x+8+spr_h, y: y+h/2, color: text_color, origin_y: 0.5
        Display.drawRect(bbox_create({x,y}, @size), box_color)

    return toggle

  -- 'Private'
  mage_choice_toggle_create = (root_update) ->
    toggle = {
        size: {300,32},
        font: DEFAULT_FONT,
    }

    skill_left_toggle = {
        ["fire_mastery"]: "water_mastery", ["water_mastery"]: "death_mastery", 
        ["death_mastery"]: "life_mastery", ["life_mastery"]: "curses", ["curses"]: "enchantments"
        ["enchantments"]: "force_spells", ["force_spells"]: "earth_mastery", ["earth_mastery"]: "air_mastery", ["air_mastery"]: "fire_mastery"
    }
    skill_right_toggle = table.value_key_invert(skill_left_toggle)

    -- Calculated on any change of skill choice
    sprite = data.get_sprite('skicon-' .. _MAGE_MAGIC_SKILL\lower())
    text = _STAT_OBJECT.class_name .. ' (' .. statsystem.SKILL_ATTRIBUTE_NAMES[_MAGE_MAGIC_SKILL] .. ' Focus)'
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
  -- 'Private'
  label_button_create = (params, color_formula, on_click) ->
    sprite = Sprite.create(params.sprite, { color: Display.COL_WHITE })
    label = TextLabel.create font: params.font, font_size: (params.font_size or 12), text: params.text

    params.size = params.size or label.size

    label_button = InstanceBox.create( params )

    label_button\add_instance( sprite, Display.CENTER_TOP )
    label_button\add_instance( label, Display.CENTER_TOP, {0, params.size[2] - params.font_size}) -- Offset to near the bottom

    label_button.step = (x, y) => -- Makeshift inheritance
        InstanceBox.step(@, x, y)

        if @mouse_over(x,y) and user_io.mouse_left_pressed() 
            on_click(@, x, y)

        color = color_formula(@, x, y)
        sprite.color = color
        label.color = (color == Display.COL_WHITE) and TEXT_COLOR or color

    return label_button

  -- 'Exported'
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

    container = InstanceBox.create size: {640, 214}
    -- Respond to a change in class choice:
    update = () ->
        container\clear()

        container\add_instance button_row, Display.CENTER_TOP
        if _CLASS_CHOICE == "Mage"
            _CLASS_ARGS = {magic_skill: _MAGE_MAGIC_SKILL, weapon_skill: _WEAPON_SKILL}
            update_stat_object()
            container\add_instance mage_choice_toggle_create(update), Display.CENTER_BOTTOM
            -- Unlike with the Knight (for which it would make little sense), we allow choosing ranged_weapons as a weapon style for mages.
            container\add_instance weapon_choice_toggle_create(update, true), Display.CENTER_BOTTOM, {0, 60}
        elseif _CLASS_CHOICE == "Knight"
            _CLASS_ARGS = {weapon_skill: _WEAPON_SKILL}
            update_stat_object()
            container\add_instance weapon_choice_toggle_create(update), Display.CENTER_BOTTOM
        elseif _CLASS_CHOICE == "Archer"
            update_stat_object()

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

        text = if _STAT_OBJECT == nil then "" else  _STAT_OBJECT.class_name .. ":  " .. statsystem.classes[_CLASS_CHOICE].description(_CLASS_ARGS)
        {w,h} = @size
        Display.drawText {
            font: DEFAULT_FONT, :text, font_size: 14
            x: x + w/2,  y: y + h + 18, color: Display.COL_WHITE, origin: Display.CENTER_BOTTOM
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


local race_toggle_create
do -- Defines race_toggle_create, hides related functions

  -- 'Exported'
  race_toggle_create = () ->
    toggle = {
        size: {400,128},
        font: DEFAULT_FONT,
    }

    race_left_toggle = {
        Undead: "Human", Human: "Orc", Orc: "Undead"
    }
    race_right_toggle = table.value_key_invert(race_left_toggle)

    local sprite, text, text_color
    update = () ->
        -- Calculated on any change of race choice
        sprite = data.get_sprite('sr-' .. _RACE_CHOICE\lower())
        text = _RACE_CHOICE .. ":\n" ..statsystem.races[_RACE_CHOICE].description
        text_color = TEXT_COLOR
        update_stat_object()

    toggle.step = (x, y) =>
        -- Toggle the connection type
        if user_io.mouse_left_pressed() and mouse_over({x, y}, @size)
            _RACE_CHOICE = race_left_toggle[_RACE_CHOICE]
        elseif user_io.mouse_right_pressed() and mouse_over({x, y}, @size)
            _RACE_CHOICE = race_left_toggle[_RACE_CHOICE]
        update()

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
            text: "Race Choice: " .. _RACE_CHOICE
        }
        Display.drawText font: @font, font_size: 12, :text, x: x+8+spr_h, y: y+h/2, color: text_color, origin_y: 0.5, max_width: w - 48
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

local skill_display_box
do -- Defines skill_preview_box
  skill_display_box = () ->
    box = {size: {200,400}}
    box.step = (x, y) => nil
    box.draw = (x, y) => 
        Display.drawRect(bbox_create({x,y}, @size), Display.COL_WHITE)
        Display.drawText{x: x+3, y: y-2, origin: Display.LEFT_BOTTOM, text: "Stat Preview", font: DEFAULT_FONT, color: Display.COL_YELLOW}

        if _STAT_OBJECT == nil then return
        -- util_draw_stats.draw_stats(_STAT_OBJECT.derived, x+10, y+10, 0, 15)

    return box

menu_chargen_content = (on_back_click, on_start_click) ->
    box_race_and_class = with InstanceBox.create size: {480, 480}
        \add_instance race_toggle_create(), 
            Display.CENTER_TOP, { 0, 90 } -- Down 90 pixels
        \add_instance class_choice_buttons_create(), 
            Display.CENTER, { 0, 90 } --Down 90 pixels

    return with InstanceBox.create size: _SETTINGS.window_size
        \add_instance make_text_label("Character Creation", 32, Display.COL_WHITE),
            Display.CENTER_TOP, {-196,80}
        \add_instance box_race_and_class, Display.LEFT_CENTER
        \add_instance skill_display_box(), Display.RIGHT_CENTER, { -25, 0 } -- Left 25 pixels
        \add_instance choose_class_message_create(), 
            Display.CENTER_BOTTOM, { 0, -50 } -- Up 50 pixels
        \add_instance back_and_continue_options_create(on_back_click, on_start_click), 
            Display.CENTER_BOTTOM, { 0, -20 } --Up 20 pixels

menu_chargen = (controller, on_back_click, raw_on_start_click) ->
    -- Clear the previous layout
    Display.display_setup()
    -- Allow process the start-click callback if _STAT_OBJECT isn't nil
    on_start_click = () -> 
        if _STAT_OBJECT then 
            raw_on_start_click {class: _CLASS_CHOICE, race: _RACE_CHOICE, class_args: _CLASS_ARGS}
    box_menu = menu_chargen_content(on_back_click, on_start_click)
    Display.display_add_draw_func () ->
        ErrorReporting.wrap(() -> box_menu\draw(0,0))()

    while controller\is_active()
        box_menu\step(0,0)
        if user_io.key_pressed "K_ESCAPE"
            os.exit()
        if user_io.key_pressed "K_ENTER"
            on_start_click()
        coroutine.yield()

return {start: menu_chargen}
