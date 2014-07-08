local Display, InstanceBox, InstanceLine, Sprite, TextLabel
do
  local _obj_0 = require("ui")
  Display, InstanceBox, InstanceLine, Sprite, TextLabel = _obj_0.Display, _obj_0.InstanceBox, _obj_0.InstanceLine, _obj_0.Sprite, _obj_0.TextLabel
end
local res = require('resources')
local thread_create
do
  local _obj_0 = require('core.util')
  thread_create = _obj_0.thread_create
end
local text_label_create
text_label_create = function(args)
  args.font = args.font or res.get_font(_SETTINGS.menu_font)
  args.font_size = args.font_size or 20
  return TextLabel.create(args)
end
local menu_main
menu_main = function(on_start_click, on_join_click, on_load_click, on_score_click)
  Display.display_setup()
  local box_menu = InstanceBox.create({
    size = {
      Display.display_size()
    }
  })
  local spr_title_trans = Sprite.image_create("LANARTS-transparent.png", {
    alpha = 0.5
  })
  local spr_title = Sprite.image_create("LANARTS.png")
  local text_start = text_label_create({
    text = "Start or Join a Game"
  })
  do
    box_menu:add_instance(spr_title_trans, Display.CENTER_TOP, {
      -10,
      30
    })
    box_menu:add_instance(spr_title, Display.CENTER_TOP, {
      0,
      20
    })
    box_menu:add_instance((function()
      do
        local _with_0 = InstanceLine.create({
          per_row = 1,
          dy = 50
        })
        _with_0:add_instance(text_start)
        _with_0:add_instance(text_start)
        return _with_0
      end
    end)(), Display.CENTER, {
      0,
      70
    })
  end
  Display.display_add_draw_func(function()
    return box_menu:draw(0, 0)
  end)
  while true do
    box_menu:step(0, 0)
  end
end
return {
  menu_main = menu_main
}
