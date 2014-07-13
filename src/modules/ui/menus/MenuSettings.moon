import Display, InstanceBox, InstanceLine, Sprite, TextLabel, TextInputBox from require "ui"
import MENU_FONT, text_label_create, text_button_create from require "@menus.util_menu"

menu_content_settings = (on_back_click, on_start_click) ->
    return with InstanceBox.create size: {640, 480}
        \add_instance 

    -- fields:add_instance( 
    --     class_choice_buttons_create(), 
    --     Display.CENTER_TOP, --[[Down 50 pixels]] { 0, 50 } )

    -- fields:add_instance( 
    --     center_setting_fields_create(), 
    --     {0.50, 0.70} )

    -- fields:add_instance( 
    --     back_and_continue_options_create(on_back_click, on_start_click), 
    --     Display.CENTER_BOTTOM, --[[Up 20 pixels]] { 0, -20 } )

    -- fields:add_instance( 
    --     choose_class_message_create(), 
    --     Display.CENTER_BOTTOM, --[[Up 50 pixels]] { 0, -50 }  )

    -- return fields


menu_settings = (controller, on_back_click, on_start_click) ->
    -- Clear the previous layout
    Display.display_setup()

    -- Create the pieces
    box_menu = InstanceBox.create size: {Display.display_size()}
    spr_title_trans = Sprite.image_create("LANARTS-transparent.png", alpha: 0.5)
    spr_title = Sprite.image_create("LANARTS.png")
    -- input_name = TextInputBox.create(MENU_FONT, {})

    Display.display_add_draw_func () ->
        box_menu\draw(0,0)

    -- Create the layout
    with box_menu
      \add_instance spr_title_trans, Display.CENTER_TOP, {-10,30}
      \add_instance spr_title, Display.CENTER_TOP, {0,20}

    while controller\is_active()
        box_menu\step(0,0)
        coroutine.yield()

return {start: menu_settings}