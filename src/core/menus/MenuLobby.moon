import Display, InstanceBox, InstanceLine, Sprite, TextLabel, TextInputBox from require "ui"
import MENU_FONT, text_label_create, text_button_create from require "@menus.util_menu_common"

menu_main_start = (controller, on_back_click = do_nothing, on_game_click = do_nothing) ->
    -- Clear the previous layout
    Display.display_setup()

    -- Create the pieces
    box_menu = InstanceBox.create size: {Display.display_size()}
    spr_title_trans = Sprite.image_create("LANARTS-transparent.png", alpha: 0.5)
    spr_title = Sprite.image_create("LANARTS.png")

    text_spacing = 30
    button_start = text_button_create text: "Start or Join a Game", on_click: on_start_click
    button_load = text_button_create text: "Load a Game", on_click: on_load_click
    button_score = text_button_create text: "Past Heroes", on_click: on_score_click

    -- Create the layout
    with box_menu
      \add_instance spr_title_trans, Display.CENTER_TOP, {-10,30}
      \add_instance spr_title, Display.CENTER_TOP, {0,20}
      \add_instance with (InstanceLine.create per_row: 1, dy: text_spacing)
          \add_instance button_start
          \add_instance button_load
          \add_instance button_score
          \align Display.CENTER_TOP,
        {0.5, 0.5}, {0,70}

    Display.display_add_draw_func () ->
        box_menu\draw(0,0)

    while controller\is_active()
        box_menu\step(0,0)
        coroutine.yield()

return {start: menu_main_start}
