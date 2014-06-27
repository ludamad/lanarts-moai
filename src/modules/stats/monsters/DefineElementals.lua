local Apts = require "@stats.AptitudeTypes"
local Mons = require "@monsters.MonsterDefineUtils" 
local monster_define = Mons.monster_define 

monster_define {
    name = "Cloud Elemental",
    monster_race = Mons.AIR_ELEMENTAL,
    description = ".",

    sprite_size = {32, 32},
    
    appear_message = "A cloud elemental floats onto the scene.",
    defeat_message = "The cloud elemental dissolves.",

    challenge_rating = 1.5,
    radius = 12,

    movement_speed = 1,
    hp = 45, hp_regen = 0.02,

    range = 150,

    created_projectile = {
        sprite = "sprites/storm_bolt.png",
        aptitude_types = {Apts.AIR, Apts.MAGIC, Apts.FORCE},
        effectiveness = 1, damage = 10,
        speed = 4, delay = 1
    }
}