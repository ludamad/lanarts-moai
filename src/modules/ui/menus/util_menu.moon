import Display, InstanceBox, InstanceLine, Sprite, TextLabel, TextInputBox from require "ui"
res = require 'resources'
import mouse_left_pressed from require 'user_io'

MENU_FONT = res.get_font(_SETTINGS.menu_font)

text_label_create = (args) ->
    args.font = args.font or MENU_FONT
    args.font_size = args.font_size or 20
    -- args.origin = Display.CENTER
    return TextLabel.create(args)

text_button_create = (args) ->
    label = text_label_create(args)
    assert(args.on_click)
    -- Inherit from TextLabel using first-principles (Lua/Moonscript shines here!)
    label.draw = (x, y) =>
        if @mouse_over(x, y)
            @color = Display.COL_YELLOW
        else
            @color = Display.COL_WHITE
        TextLabel.draw(@, x, y)
    label.step = (x, y) =>
        TextLabel.step(@, x, y)
        if @mouse_over(x, y) and mouse_left_pressed()
            args.on_click()

    return label

return {:MENU_FONT, :text_label_create, :text_button_create}