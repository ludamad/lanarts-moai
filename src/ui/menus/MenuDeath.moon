import Display, InstanceBox, InstanceLine, TextLabel, Sprite from require 'ui'

res = require "resources"
user_io = require "user_io"

death_screen_create = () ->
    box = InstanceBox.create size: {Display.display_size()}
    sprite = Sprite.image_create("death_screen.png")

    box\add_instance(sprite, Display.CENTER)

    offset_y = math.ceil(sprite.size[2]/2)
    font = res.get_font "MateSC-Regular.ttf"
    add_label = (text, color, xy, font_size = 21) ->
        box\add_instance TextLabel.create({:text, :color, :font, :font_size}), Display.CENTER, xy
    add_label "You Have Died!", Display.COL_PALE_RED, {0, (-40 - offset_y) }

    if _SETTINGS.regen_on_death
        add_label "Press enter to respawn.", Display.COL_LIGHT_GRAY, {0, (20 + offset_y)}
    else
        add_label "Hardcore death is permanent!", Display.COL_RED, {0, (-20 + offset_y)}
        add_label "Thanks for playing.", Display.COL_LIGHT_GRAY,  {0, (20 + offset_y)}
        add_label "-ludamad", Display.COL_PALE_YELLOW, {100, (45 + offset_y)}, 12

    black_box_alpha = 1.0
    box.draw = (x, y) => --Makeshift inheritance
        InstanceBox.draw(@, x, y)
        black_box_alpha = math.max(0, black_box_alpha - 0.05)
        w, h = Display.display_size()
        Display.fillRect(0,0,w,h, {0,0,0, black_box_alpha})

    return box

menu_death = (controller, on_continue) ->
    Display.display_setup()
    menu = death_screen_create()
    Display.display_add_draw_func () -> menu\draw(0,0)

    while controller\is_active()
        coroutine.yield()
        menu\step(0,0)
        if user_io.key_pressed "K_ENTER"
            on_continue()

return {start: menu_death}