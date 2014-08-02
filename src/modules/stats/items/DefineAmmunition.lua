local ammunition_define,Traits = (require "@items.ItemDefineUtils").ammunition_define, require "@items.ItemTraits"

ammunition_define {
    name = "Arrow",
    description = "A mediocore arrow.",
    projectile_sprite = "proj-arrow",
    traits = {Traits.ARROW},
    speed = 6.5
}