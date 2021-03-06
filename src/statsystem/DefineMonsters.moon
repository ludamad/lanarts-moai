import monster_define from require "statsystem"

monster_define {
  name: "Giant Rat"
  monster_kind: "animal"
  description: "A giant, aggressive vermin."
  appear_message: "A hostile large rat approaches!"
  defeat_message: "Blood splatters as the large rat is destroyed."

  radius: 8

  level: 1
  move_speed: 6
  hp: 30, hp_regen: 0.001
  power: 0, damage: 12
  multiplier: 1 -- Don't compensate for cooldown
  cooldown: 2.00
  delay: 2.00
  chase_distances: {100,150}
}

monster_define {
  name: "Cloud Elemental"
  monster_kind: "elemental"
  description: ""
  appear_message: ""
  defeat_message: ""

  radius: 14

  level: 1
  move_speed: 4
  hp: 10, hp_regen: 0.001
  -- Fires a projectile shot:
  uses_projectile: true
  projectile_radius: 8
  projectile_speed: 5.5
  attack_sprite: 'projectile-cloud'
  power: 4, damage: 20
  multiplier: 1 -- Don't compensate for cooldown
  cooldown: 1.70
  delay: 0
  range: 50
  chase_distances: {200,300, 32}
}

monster_define {
  name: "Chicken"
  monster_kind: "animal"
  description: ""
  appear_message: ""
  defeat_message: ""

  radius: 10

  level: 1
  move_speed: 7
  hp: 8, hp_regen: 0.001
  power: 0, damage: 9
  multiplier: 1 -- Don't compensate for cooldown
  cooldown: 2.0
  delay: 1.5
  chase_distances: {100, 150}
}

monster_define {
    name: "Turtle"
    monster_kind: "animal"
    description: ""
    appear_message: ""
    defeat_message: ""
    
    radius: 8
    
    level: 1 
    move_speed: 2
    hp: 50, hp_regen: 0.001
    power: 0, damage: 3
    multiplier: 1
    cooldown: 2.0
    delay: 3
    chase_distances: {200, 300}
}

monster_define {
    name: "Spriggan"
    monster_kind: "fairy"
    description: ""
    appear_message: ""
    defeat_message: ""
    
    radius: 10
    
    level: 1
    move_speed: 5
    hp: 20, hp_regen: 0.001
    power: 0, damage: 10
    multiplier: 1 
    cooldown: 1.5
    delay: 1.5
    chase_distances: {100,300}
}