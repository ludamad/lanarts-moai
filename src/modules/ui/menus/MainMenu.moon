import Display, InstanceBox, InstanceLine, Sprite, TextLabel from require "ui"
res = require 'resources'

import thread_create from require 'core.util'

text_label_create = (args) ->
    args.font = args.font or res.get_font(_SETTINGS.menu_font)
    args.font_size = args.font_size or 20
    return TextLabel.create(args)

text_button_create = (args) ->
    label = text_label_create(args)
    -- Inherit from TextLabel using first-principles (Lua/Moonscript shines here!)
    label.draw = (x, y) =>
        TextLabel.draw(@, x, y)
    label.step = (x, y) =>
        TextLabel.step(@, x, y)
        if @mouse_over(x, y)
            @color = Display.COL_YELLOW
        else
            @color = Display.COL_WHITE

    return label

menu_main = (on_start_click, on_join_click, on_load_click, on_score_click) ->
    -- Clear the previous layout
    Display.display_setup()

    -- Create the pieces
    box_menu = InstanceBox.create size: {Display.display_size()}
    spr_title_trans = Sprite.image_create("LANARTS-transparent.png", alpha: 0.5)
    spr_title = Sprite.image_create("LANARTS.png")

    text_spacing = 30
    text_start = text_button_create text: "Start or Join a Game"

    -- Create the layout
    with box_menu
        \add_instance spr_title_trans, Display.CENTER_TOP, {-10,30}
        \add_instance spr_title, Display.CENTER_TOP, {0,20}
        \add_instance with InstanceLine.create per_row: 1, dy: text_spacing
                \add_instance text_start
                \add_instance text_start,
            Display.CENTER, {0,70}

    Display.display_add_draw_func () ->
        box_menu\draw(0,0)

    while true
        box_menu\step(0,0)
        coroutine.yield()

return {:menu_main}
