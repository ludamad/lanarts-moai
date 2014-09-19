local Apts = require "@stats.AptitudeTypes"
local ItemDefineUtils = require "@items.ItemDefineUtils"

--------------------------------------------------------------------------------
--  Define Body Armours                                                       --
--------------------------------------------------------------------------------

local body_armour_define = ItemDefineUtils.body_armour_define

body_armour_define {
    name = "Leather Armour",
    avatar_sprite = "sa-leather",
    description = "The armour made of fine leather.",
    sprite = {}, -- TODO

    gold_worth = 15, difficulty = 0,

    [Apts.MELEE] = {0,0,3,0}, 
    [Apts.PIERCING] = {0,0,1,1} 
}

body_armour_define {
    name = "Robe",
    avatar_sprite = "sa-robe",
    description = "A robe.",
    sprite = {}, -- TODO

    gold_worth = 15, difficulty = 0,

    [Apts.MELEE] = {0,0,2,0}
}

body_armour_define {
    name = "Studded Leather Armour",
    avatar_sprite = "sa-studded-leather",
    description = "The armour is made of fine, studded leather.",
    sprite = {}, -- TODO

    gold_worth = 25, difficulty = 1,

    [Apts.MELEE] = {0,0,1,1}, 
    [Apts.PIERCING] = {0,0,1,1} 
}

body_armour_define {
    name = "Chainshirt",
    avatar_sprite = "sa-chainshirt",
    description = "The shirt consists of small metal rings linked together in a mesh.",
    sprite = {}, -- TODO

    gold_worth = 110, difficulty = 3,

    [Apts.MELEE] = {0,0,-1,2}, 
    [Apts.PIERCING] = {0,0,1,1} 
}

body_armour_define {
    name = "Split mail",
    description = "The armour is made of splints of metal on a leather backing.",
    sprite = {}, -- TODO

    gold_worth = 150, difficulty = 4,

    [Apts.MELEE] = {0,0,-3,3}
}

--------------------------------------------------------------------------------
--  Define Gloves                                                             --
--------------------------------------------------------------------------------

local gloves_define = ItemDefineUtils.gloves_define

gloves_define {
    name = "Leather Gloves",
    description = "Gloves made of leather, providing a fair bit of protection for the hands.",
    sprite = {}, -- TODO

    gold_worth = 15, difficulty = 1,

    [Apts.MELEE] = {0,0,1,0}
}

--------------------------------------------------------------------------------
--  Define Bracers                                                            --
--------------------------------------------------------------------------------

local bracers_define = ItemDefineUtils.bracers_define

bracers_define {
    name = "Leather Bracers",
    description = "Simple bracers of leather. Aid in ranged combat.",
    sprite = {}, -- TODO

    gold_worth = 15, difficulty = 1,

    [Apts.RANGED] = {1,0,0,0}
}

--------------------------------------------------------------------------------
--  Define Headgears                                                          --
--------------------------------------------------------------------------------

local headgear_define = ItemDefineUtils.headgear_define

headgear_define {
    name = "Leather Cap",
    description = "Hat made of leather. It provides moderate protection to the head.",
    sprite = {}, -- TODO

    gold_worth = 15, difficulty = 1,

    [Apts.MELEE] = {0,0,1,0}
}

headgear_define {
    name = "Wizard's Hat",
    description = "An optimized thinking cap.",
    sprite = {}, -- TODO

    gold_worth = 35, difficulty = 2,

    [Apts.MAGIC] = {1,0,0,0}
}

headgear_define {
    name = "Horned Helmet",
    avatar_sprite = "sh-horn-gray",
    description = "A helmet with horns. It provides pretty good protection to the head.",
    sprite = {}, -- TODO

    gold_worth = 55, difficulty = 2,

    [Apts.MELEE] = {0,0,2,0}
}

--------------------------------------------------------------------------------
--  Define Boots's                                                            --
--------------------------------------------------------------------------------

local boots_define = ItemDefineUtils.boots_define

boots_define {
    name = "Leather Boots",
    avatar_sprite = "sb-brown",
    description = "Boots made of leather. They go a long way for protecting the feat.",
    sprite = {}, -- TODO

    gold_worth = 15, difficulty = 1,

    [Apts.MELEE] = {0,0,1,0}
}