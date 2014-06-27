local ammunition_define,Traits = (require "@items.ItemDefineUtils").ammunition_define, require "@items.ItemTraits"

ammunition_define {
    name = "Arrow",
    description = "A mediocore arrow.",
    projectile_sprite = "sprites/arrow_projectile.png%32x32",
    traits = {Traits.ARROW},
    speed = 6.5
}