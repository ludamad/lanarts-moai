import Display, InstanceBox, InstanceLine, Sprite, TextLabel, TextInputBox from require "ui"
res = require 'resources'
import mouse_left_pressed from require 'user_io'

DEFAULT_FONT = res.get_bmfont('Liberation-Mono-12.fnt')
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

make_text_label = (text, font_size = 20, color = Display.COL_WHITE) ->
    TextLabel.create font: MENU_FONT, :font_size, :text, :color

back_and_continue_options_create = (on_back_click = do_nothing, on_start_click = do_nothing, next_text = "Next") ->
    font = DEFAULT_FONT
    options = InstanceLine.create( { dx: 200 } )

    -- associate each label with a handler
    -- we make use of the ability to have objects as keys
    components = {
        {make_text_label("Back"), on_back_click}
        {make_text_label(next_text), on_start_click}
    }

    map = {}
    for {obj, handler} in *components
        map[obj] = handler
        options\add_instance(obj)

    options.step = (x, y) => -- Makeshift inheritance
        InstanceLine.step(@, x,y)
        for obj, obj_x, obj_y in @instances(x,y) do
            click_handler = map[obj]

            mouse_is_over = obj\mouse_over(obj_x, obj_y)
            obj.color = mouse_is_over and Display.COL_GOLD or Display.COL_WHITE

            if mouse_is_over and mouse_left_pressed() then click_handler()

    return options

return {:DEFAULT_FONT, :MENU_FONT, :text_label_create, :text_button_create, :back_and_continue_options_create, :make_text_label}