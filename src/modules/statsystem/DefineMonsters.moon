import monster_define from require "statsystem"

monster_define {
  name: "Giant Rat"
  monster_kind: "animal"
  description: "A giant, aggressive vermin."
  appear_message: "A hostile large rat approaches!"
  defeat_message: "Blood splatters as the large rat is destroyed."

  radius: 10

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
  name: "Storm Elemental"
  monster_kind: "elemental"
  description: ""
  appear_message: ""
  defeat_message: ""

  radius: 15

  level: 1
  move_speed: 2
  hp: 10, hp_regen: 0.001
  uses_projectile: true
  power: 0, damage: 5
  cooldown: 1.00
  delay: 1.00
  chase_distances: {100,150}
}
