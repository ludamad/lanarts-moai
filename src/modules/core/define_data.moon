-- By default, tiles are 32x32

gen = require '@generate'
import TileMap from require "core"

logI("Loading tiles")

with tiledef file: 'floor.png', solid: false
    .define name: 'undefined', from: {1,1}, to: {2,1}
    .define name: 'grey_floor', from: {3,1}, to: {11,1}

with tiledef file: 'wall.png', solid: true
    .define name: 'dungeon_wall', from: {1,1}, to: {32, 1}

with spritedef file: 'feat.png', size: {32,32}, tiled: true
    .define name: 'door_closed', from: {3, 2}
    .define name: 'door_open',   from: {10, 2}    
    .define name: 'shop',        from: {11,6}, to: {21,6}

logI("Loading player components")

with spritedef file: 'player-animated.png', size: {32,32}, tiled: true, kind: 'animation'
    .define name: 'sr-human', from: {1, 1}, to: {4, 1}
    .define name: 'sr-undead', from: {1, 2}, to: {4, 2}
    .define name: 'sr-orc', from: {1, 3}, to: {4, 3}
    .define name: 'sr-centaur', from: {1, 4}, to: {4, 4}

with spritedef file: 'player-feet.png', size: {32,32}, tiled: true, kind: 'animation'
    .define name: 'sb-gold-blue', from: {1, 1}, to: {4, 1}
    .define name: 'sb-hoof', from: {1, 2}, to: {4, 2}
    .define name: 'sb-mesh', from: {1, 3}, to: {4, 3}
    .define name: 'sb-silver', from: {1, 4}, to: {4, 4}
    .define name: 'sb-gold-blue', from: {1, 5}, to: {4, 5}
    .define name: 'sb-red', from: {1, 6}, to: {4, 6}
    .define name: 'sb-grey', from: {5, 6}, to: {8, 6}
    .define name: 'sb-brown', from: {13, 1}, to: {16, 1}

with spritedef file: 'crawl-sarmour.png', size: {32,32}, tiled: true, kind: 'animation'
    .define name: 'sa-archer', from: {12, 6}
    .define name: 'sa-spiky', from: {1, 2}
    .define name: 'sa-chainshirt', from: {4, 2}
    .define name: 'sa-gold', from: {4, 3}
    .define name: 'sa-death', from: {11, 9}
    .define name: 'sa-leather', from: {6,6}
    .define name: 'sa-robe', from: {6,8}
    .define name: 'sa-studded-leather', from: {6,6}

with spritedef file: 'crawl-legs.png', size: {32,32}, tiled: true, kind: 'animation'
    .define name: 'sl-gray-pants', from: {5, 2}
    .define name: 'sl-green-shorts', from: {8, 2}
    .define name: 'sl-green-skirt', from: {10, 3}
    .define name: 'sl-white-pants', from: {9, 2}
    .define name: 'sl-red-yellow', from: {11, 2}
    .define name: 'sl-blue-hang', from: {4, 1}
    .define name: 'sl-armour-short', from: {8, 3}

with spritedef file: 'crawl-avatar-head.png', size: {32,32}, tiled: true
    .define name: 'sh-art-dragonhelm', from: {1, 1}
    .define name: 'sh-bandana-ybrown', from: {2, 1}
    .define name: 'sh-band-blue', from: {3, 1}
    .define name: 'sh-band-magenta', from: {4, 1}
    .define name: 'sh-band-red', from: {5, 1}
    .define name: 'sh-band-white', from: {6, 1}
    .define name: 'sh-band-yellow', from: {7, 1}
    .define name: 'sh-bear', from: {8, 1}
    .define name: 'sh-black-horn2', from: {9, 1}
    .define name: 'sh-black-horn', from: {10, 1}
    .define name: 'sh-blue-horn_gold', from: {11, 1}
    .define name: 'sh-brown-gold', from: {12, 1}
    .define name: 'sh-cap-black1', from: {1, 1}
    .define name: 'sh-cap-blue', from: {1, 2}
    .define name: 'sh-chain', from: {2, 2}
    .define name: 'sh-cheek-red', from: {3, 1}
    .define name: 'sh-clown1', from: {4, 1}
    .define name: 'sh-clown2', from: {5, 1}
    .define name: 'sh-cone-blue', from: {6, 1}
    .define name: 'sh-cone-red', from: {7, 1}
    .define name: 'sh-crown-gold1', from: {8, 1}
    .define name: 'sh-crown-gold2', from: {9, 1}
    .define name: 'sh-crown-gold3', from: {10, 1}
    .define name: 'sh-dyrovepreva', from: {11, 1}
    .define name: 'sh-feather-blue', from: {12, 1}
    .define name: 'sh-feather-green', from: {1, 2}
    .define name: 'sh-feather-red', from: {2, 2}
    .define name: 'sh-feather-white', from: {3, 2}
    .define name: 'sh-feather-yellow', from: {4, 2}
    .define name: 'sh-fhelm-gray3', from: {5, 2}
    .define name: 'sh-fhelm-horn2', from: {6, 2}
    .define name: 'sh-fhelm-horn_yellow', from: {7, 2}
    .define name: 'sh-full-black', from: {8, 2}
    .define name: 'sh-full-gold', from: {9, 2}
    .define name: 'sh-gandalf', from: {10, 2}
    .define name: 'sh-hat-black', from: {11, 2}
    .define name: 'sh-healer', from: {12, 2}
    .define name: 'sh-helm-gimli', from: {1, 3}
    .define name: 'sh-helm-green', from: {2, 3}
    .define name: 'sh-helm-plume', from: {3, 3}
    .define name: 'sh-helm-red', from: {4, 3}
    .define name: 'sh-hood-black2', from: {5, 3}
    .define name: 'sh-hood-cyan', from: {6, 3}
    .define name: 'sh-hood-gray', from: {7, 3}
    .define name: 'sh-hood-green2', from: {8, 3}
    .define name: 'sh-hood-green', from: {9, 3}
    .define name: 'sh-hood-orange', from: {10, 3}
    .define name: 'sh-hood-red2', from: {11, 3}
    .define name: 'sh-hood-red', from: {12, 3}
    .define name: 'sh-hood-white2', from: {1, 4}
    .define name: 'sh-hood-white', from: {2, 4}
    .define name: 'sh-hood-ybrown', from: {3, 4}
    .define name: 'sh-horned', from: {4, 4}
    .define name: 'sh-horn-evil', from: {5, 4}
    -- TODO fix locations
    .define name: 'sh-horn-gray', from: {7, 5}
    .define name: 'sh-horns1', from: {7, 4}
    .define name: 'sh-horns2', from: {8, 4}
    .define name: 'sh-horns3', from: {9, 4}
    .define name: 'sh-iron1', from: {10, 4}
    .define name: 'sh-iron2', from: {11, 4}
    .define name: 'sh-iron3', from: {12, 4}
    .define name: 'sh-iron-red', from: {1, 5}
    .define name: 'sh-isildur', from: {2, 5}
    .define name: 'sh-mummy', from: {3, 5}
    .define name: 'sh-ninja-black', from: {4, 5}
    .define name: 'sh-straw', from: {5, 5}
    .define name: 'sh-taiso-blue', from: {6, 5}
    .define name: 'sh-taiso-magenta', from: {7, 5}
    .define name: 'sh-taiso-red', from: {8, 5}
    .define name: 'sh-taiso-white', from: {9, 5}
    .define name: 'sh-taiso-yellow', from: {10, 5}
    .define name: 'sh-turban-brown', from: {11, 5}
    .define name: 'sh-turban-purple', from: {12, 5}
    .define name: 'sh-turban-white', from: {1, 6}
    .define name: 'sh-viking-brown1', from: {2, 6}
    .define name: 'sh-viking-brown2', from: {3, 6}
    .define name: 'sh-viking-gold', from: {4, 6}
    .define name: 'sh-wizard-blackgold', from: {5, 6}
    .define name: 'sh-wizard-blackred', from: {6, 6}
    .define name: 'sh-wizard-bluegreen', from: {7, 6}
    .define name: 'sh-wizard-blue', from: {8, 6}
    .define name: 'sh-wizard-brown', from: {9, 6}
    .define name: 'sh-wizard-darkgreen', from: {10, 6}
    .define name: 'sh-wizard-lightgreen', from: {11, 6}
    .define name: 'sh-wizard-purple', from: {12, 6}
    .define name: 'sh-wizard-red', from: {1, 7}
    .define name: 'sh-wizard-white', from: {2, 7}
    .define name: 'sh-yellow-wing', from: {3, 7}

with spritedef file: 'crawl-gloves.png', size: {32,32}, tiled: true
    .define name: 'sg-claws', from: {1, 1}
    .define name: 'sg-red-gloves', from: {2, 1}

with spritedef file: 'crawl-hand1.png', size: {32,32}, tiled: true
    .define name: 'sw-blue-bow', from: {8, 2}
    .define name: 'sw-red-bow', from: {9, 2}
    .define name: 'sw-long-bow', from: {10, 2}
    .define name: 'sw-brown-bow', from: {11, 2}
    .define name: 'sw-mace1', from: {10, 5}
    .define name: 'sw-mace2', from: {11, 5}
    .define name: 'sw-axe', from: {10, 6}
    .define name: 'sw-hand-axe', from: {8, 1}
    .define name: 'sw-glaive', from: {11, 6}
    .define name: 'sw-sword1', from: {8, 7}
    .define name: 'sw-sword2', from: {9, 7}
    .define name: 'sw-tall-axe1', from: {10, 7}
    .define name: 'sw-tall-axe2', from: {11, 7}
    .define name: 'sw-dagger', from: {9, 8}

with spritedef file: 'crawl-hand2.png', size: {32,32}, tiled: true
    .define name: 'ss-small-shield', from: {1, 7}

with spritedef file: 'monsters.png', size: {32,32}, tiled: true
    .define name: 'Big Bat', from: {1, 1}
    .define name: 'Chicken', from: {2, 1}
    .define name: 'Big Frog', from: {3, 1}
    .define name: 'Giant Rat', from: {4, 1}
    .define name: 'Horse', from: {5, 1}
    .define name: 'Wolf', from: {6, 1}
    .define name: 'Lavafish', from: {7, 1}
    .define name: 'Hedgehog', from: {8, 1}
    .define name: 'Sheep', from: {9, 1}
    .define name: 'Big Spider', from: {10, 1}
    .define name: 'Enchanted Chicken', from: {11, 1}

with spritedef file: 'cloud-projectile.png', size: {32,32}, tiled: true, kind: 'animation'
    .define name: 'Storm Cloud', from: {1,1}

with spritedef file: 'status_icon.png', size: {32,32}, tiled: true
    .define name: 'stat-haste', from: {1, 1}
    .define name: 'stat-slow', from: {2, 1}
    .define name: 'stat-speed', from: {3, 1}
    .define name: 'stat-rest', from: {4, 1}

with spritedef file: 'crawl-weapons.png', size: {32,32}, tiled: true
    .define name: 'Hand Axe', from: {9, 5}
    .define name: 'Dagger', from: {12, 2}

with spritedef file: 'crawl-weapons-ranged.png', size: {32,32}, tiled: true
    .define name: 'Arrow', from: {1, 1}, to: {2, 1}
    .define name: 'Blowgun', from: {3, 1}
    .define name: 'Runed Blowgun', from: {4, 1}
    .define name: 'Crossbow', from: {5, 1}, to: {7,1}
    .define name: 'Bolt', from: {9, 1}, to: {10,1}
    .define name: 'Long Bow', from: {12, 1}, to: {2,2}
    .define name: 'Needle', from: {3, 2}, to: {6,2}
    .define name: 'Short Bow', from: {8, 1}, to: {10,2}
    .define name: 'Silver Arrow', from: {11, 2}, to: {12,2}

-- On-battle-field projectile sprites
with spritedef file: 'arrow-projectile.png', size: {32,32}, tiled: true
    .define name: "proj-arrow", from: {1,1}, to: {8,1}

with spritedef file: 'cloud-projectile.png', size: {32,32}, tiled: true
    .define name: "proj-storm_bolt", from: {1,1}, to: {4,1}

with spritedef file: 'minor-missile.png', size: {32,32}
    .define name: "proj-minor_missile", from: {1,1}, to: {8,1}

with spritedef file: 'cloud-projectile.png', size: {32,32}, tiled: true
    .define name: "proj-storm_bolt", from: {1,1}, to: {4,1}, tiled: true
    .define name: "proj-crystal_spear", from: {1,1}, to: {8,1}

-- In-inventory armour item sprites
with spritedef file: 'crawl-armour.png', size: {32,32}
    .define name: 'Chainshirt', from: {9, 1}, to: {11, 1}
    .define name: 'Leather Armour', from: {6,3}
    .define name: "Leather Boots", from: {5, 1}
    .define name: "Thick Boots", from: {6, 1}
    .define name: "Runed Boots", from: {7, 1}
    .define name: "Troll's Boots", from: {8, 1}

with spritedef file: 'crawl-armour-headgear.png', size: {32,32}
    .define name: 'Horned Helmet', from: {8, 1}
    .define name: 'Leather Cap', from: {2, 1}

with spritedef file: 'crawl-potions.png', size: {32,32}
    .define name: 'PotionBase', from: {3, 1}, to: {4, 9}
    .define name: 'Health Potion', from: {12, 2}

logI("Loading skill icons")

skill_icons = with spritedef file: 'menu/skill-icons.png', size: {32,32}
    .define name: 'skicon-melee', from: {31, 3}
    .define name: 'skicon-ranged', from: {7, 4}
    .define name: 'skicon-magic', from: {17, 4}
    .define name: 'skicon-piercing', from: {1, 4}
    .define name: 'skicon-slashing', from: {2, 4}
    .define name: 'skicon-blunt', from: {5, 4}
    .define name: 'skicon-enchantments', from: {14, 4}
    .define name: 'skicon-curses', from: {22, 4}
    .define name: 'skicon-force', from: {9, 4}
    .define name: 'skicon-summoning', from: {29, 4}
    .define name: 'skicon-armour', from: {10, 4}
    .define name: 'skicon-willpower', from: {30, 4}
    .define name: 'skicon-fortitude', from: {19, 4}
    .define name: 'skicon-self_mastery', from: {16, 4}
    .define name: 'skicon-magic_items', from: {20, 4}
    .define name: 'skicon-dark', from: {21, 4}
    .define name: 'skicon-light', from: {31, 4}
    .define name: 'skicon-fire', from: {25, 4}
    .define name: 'skicon-water', from: {26, 4}
    .define name: 'skicon-air', from: {27, 4}
    .define name: 'skicon-earth', from: {28, 4}


-- with spritedef file: 'crawl-weapons-ranged.png', size: {32,32}, tiled: true, kind: 'variant'

logI("Defining maps")

mapdef.define {
	name: "start" 
	generator: (G, rng) ->
		model = gen.generate_test_model(rng)
		-- for i=1,50 do spawn rng, model, 
		-- 	(px, py) -> (L) ->
		-- 		map_object_types.NPC.create L, {
		-- 			x: px*32+16
		-- 			y: py*32+16
		-- 			radius: 10
		-- 			solid: true
		-- 			speed: 4
		-- 		}
		return model
}

for vpath in *{
    -- Skills are used in many other definitions
    "stats.stats.DefineSkills"

    "stats.classes.DefineClasses"
    "stats.items.DefineAmmunition"
    "stats.items.DefineAmulets"
    "stats.items.DefineArmour"
    "stats.items.DefineConsumables"
    "stats.items.DefineRings"
    "stats.items.DefineWeapons"
    "stats.monsters.DefineAnimals"
    "stats.monsters.DefineElementals"
    "stats.monsters.DefineUndead"
    "stats.spells.DefineArcherSpells"
    "stats.spells.DefineBasicMissileSpells"
    "stats.spells.DefineFighterSpells"
    "stats.stats.DefineStatusTypes"
    "stats.races.DefineRaces"

} do
    logI("Loading " .. vpath)
    require(vpath)
