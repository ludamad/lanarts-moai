import Display, InstanceBox, Sprite from require "ui"

import thread_create from require 'core.util'

menu_main = (on_start_click, on_join_click, on_load_click, on_score_click) -> thread_create () -> profile () ->
    -- Clear the previous layout
    Display.display_setup()

    -- Create the pieces
    box_menu = InstanceBox.create size: {Display.display_size()}
    spr_title_trans = Sprite.image_create("LANARTS-transparent.png", alpha: 0.5)
    spr_title = Sprite.image_create("LANARTS.png")

    -- Create the layout
    with box_menu
        \add_instance spr_title_trans, Display.CENTER_TOP, {-10,30}
        \add_instance spr_title, Display.CENTER_TOP, {0,20}

    Display.display_add_draw_func () ->
        box_menu\draw(0,0)
    while true
        coroutine.yield()

return {:menu_main}
