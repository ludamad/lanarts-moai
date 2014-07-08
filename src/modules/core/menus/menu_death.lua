local Display = import "core.Display"

local InstanceBox = import "ui.InstanceBox"
local InstanceLine = import "ui.InstanceLine"
local TextLabel = import "ui.TextLabel"
local Sprite = import "ui.Sprite"

local user_io = import "@user_io"

local death_screen_font = "MateSC-Regular.ttf"

local function death_screen_create()
    local box = InstanceBox.create( { size = Display.display_size} )
    local sprite = Sprite.image_create(path_resolve "death_screen.png")

    box:add_instance(
        sprite,
        Display.CENTER
    )

    box:add_instance(
         TextLabel.create( font_cached_load(death_screen_font, 20), {color=COL_PALE_RED}, "You Have Died!"),
         Display.CENTER,
         {0, (-40 - sprite.size[2]/2) }
    )

    if settings.regen_on_death then
        box:add_instance(
             TextLabel.create( font_cached_load(death_screen_font, 20), {color=COL_LIGHT_GRAY}, "Press enter to respawn."),
             Display.CENTER,
             {0, (20 + sprite.size[2]/2) }
        )
    else
        box:add_instance(
             TextLabel.create( font_cached_load(death_screen_font, 12), {color=COL_RED}, "Hardcore death is permanent!"),
             Display.CENTER,
             {0, (-20 - sprite.size[2]/2) }
        )
        box:add_instance(
             TextLabel.create( font_cached_load(death_screen_font, 20), {color=COL_LIGHT_GRAY}, "Thanks for playing."),
             Display.CENTER,
             {0, (20 + sprite.size[2]/2) }
        )
        box:add_instance(
             TextLabel.create( font_cached_load(settings.menu_font, 12), {color=COL_PALE_YELLOW}, "-ludamad"),
             Display.CENTER,
             {100, (45 + sprite.size[2]/2) }
        )
    end

    local black_box_alpha = 1.0
    function box:draw(xy) --Makeshift inheritance
        InstanceBox.draw(self, xy)
        black_box_alpha = math.max(0, black_box_alpha - 0.05)
        Display.draw_rectangle(
            with_alpha(COL_BLACK, black_box_alpha), 
            bbox_create( {0,0}, Display.display_size )
        ) 
    end

    return box
end

local function death_screen_show(...)
    local screen = death_screen_create(...)

    screen:step(0,0)
    screen:draw(0,0)
end

-- Submodule
return {
    show = death_screen_show
}