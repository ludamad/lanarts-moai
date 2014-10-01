import body_armour_define, headgear_define, gloves_define, boots_define, bracers_define 
    from require "@items"

--------------------------------------------------------------------------------
--  Define Body Armours                                                       --
--------------------------------------------------------------------------------

body_armour_define {
    name: "Leather Armour"
    avatar_sprite: "sa-leather"
    description: "The armour made of fine leather."

    gold_worth: 15, difficulty: 0
}

body_armour_define {
    name: "Robe"
    avatar_sprite: "sa-robe"
    description: "A robe."

    gold_worth: 15, difficulty: 0
}

body_armour_define {
    name: "Studded Leather Armour"
    avatar_sprite: "sa-studded-leather"
    description: "The armour is made of fine, studded leather."

    gold_worth: 25, difficulty: 1
}

body_armour_define {
    name: "Chainshirt"
    avatar_sprite: "sa-chainshirt"
    description: "The shirt consists of small metal rings linked together in a mesh."

    gold_worth: 110, difficulty: 3
}

body_armour_define {
    name: "Split mail"
    description: "The armour is made of splints of metal on a leather backing."

    gold_worth: 150, difficulty: 4
}

--------------------------------------------------------------------------------
--  Define Gloves                                                             --
--------------------------------------------------------------------------------

gloves_define {
    name: "Leather Gloves"
    description: "Gloves made of leather, providing a fair bit of protection for the hands."

    gold_worth: 15, difficulty: 1
}

--------------------------------------------------------------------------------
--  Define Bracers                                                            --
--------------------------------------------------------------------------------

bracers_define {
    name: "Leather Bracers"
    description: "Simple bracers of leather. Aid in ranged combat."

    gold_worth: 15, difficulty: 1
}

--------------------------------------------------------------------------------
--  Define Headgears                                                          --
--------------------------------------------------------------------------------

headgear_define {
    name: "Leather Cap"
    description: "Hat made of leather. It provides moderate protection to the head."

    gold_worth: 15, difficulty: 1
}

headgear_define {
    name: "Wizard's Hat"
    description: "An optimized thinking cap."

    gold_worth: 35, difficulty: 2
}

headgear_define {
    name: "Horned Helmet"
    avatar_sprite: "sh-horn-gray"
    description: "A headgear with horns. It provides pretty good protection to the head."

    gold_worth: 55, difficulty: 2
}

--------------------------------------------------------------------------------
--  Define Boots's                                                            --
--------------------------------------------------------------------------------

boots_define {
    name: "Leather Boots"
    avatar_sprite: "sb-brown"
    description: "Boots made of leather. They go a long way for protecting the feat."

    gold_worth: 15, difficulty: 1
}
