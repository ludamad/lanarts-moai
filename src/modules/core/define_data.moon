-- By default, tiles are 32x32

gen = require '@generate'
import TileMap from require "core"

with tiledef file: 'floor.png', solid: false
    .define name: 'undefined', from: {1,1}, to: {2,1}
    .define name: 'grey_floor', from: {3,1}, to: {11,1}

with tiledef file: 'wall.png', solid: true
    .define name: 'dungeon_wall', from: {1,1}, to: {32, 1}

with spritedef file: 'feat.png', size: {32,32}, tiled: true
    .define name: 'door_closed', from: {3, 2}
    .define name: 'door_open',   from: {10, 2}    
    .define name: 'shop',        from: {11,6}, to: {21,6}

with spritedef file: 'player-animated.png', size: {32,32}, tiled: true, kind: 'animation'
    .define name: 'player-human', from: {1, 1}, to: {4, 1}

with spritedef file: 'player-feet.png', size: {32,32}, tiled: true, kind: 'animation'
    .define name: 'sb-boots', from: {1, 1}, to: {4, 1}

with spritedef file: 'crawl-sarmour.png', size: {32,32}, tiled: true, kind: 'animation'
    .define name: 'sa-archer', from: {12, 6}
    .define name: 'sa-spiky', from: {1, 2}
    .define name: 'sa-gold', from: {4, 3}
    .define name: 'sa-death', from: {11, 9}

with spritedef file: 'crawl-legs.png', size: {32,32}, tiled: true, kind: 'animation'
    .define name: 'sl-green-shorts', from: {8, 2}
    .define name: 'sl-green-skirt', from: {10, 3}
    .define name: 'sl-white-pants', from: {9, 2}
    .define name: 'sl-red-yellow', from: {11, 2}
    .define name: 'sl-blue-hang', from: {4, 1}
    .define name: 'sl-armour-short', from: {8, 3}

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

with spritedef file: 'crawl-weapons-ranged.png', size: {32,32}, tiled: true
    .define name: 'Arrow', from: {1, 1}, to: {2, 1}
    .define name: 'Blowgun', from: {3, 1}
    .define name: 'Runed Blowgun', from: {4, 1}
    .define name: 'Crossbow', from: {5, 1}, to: {7,1}
    .define name: 'Bolt', from: {9, 1}, to: {10,1}
    .define name: 'Long Bow', from: {12, 1}, to: {2,2}
    .define name: 'Needle', from: {3, 2}, to: {6,2}
    .define name: 'Bow', from: {8, 1}, to: {10,2}
    .define name: 'Silver Arrow', from: {11, 2}, to: {12,2}

with spritedef file: 'crawl-armour.png', size: {32,32}
    .define name: 'Chainshirt', from: {9, 1}, to: {11, 1}

with spritedef file: 'crawl-armour-headgear.png', size: {32,32}
    .define name: 'Horned Helmet', from: {8, 1}

with spritedef file: 'crawl-potions.png', size: {32,32}
    .define name: 'PotionBase', from: {3, 1}, to: {4, 9}
    .define name: 'Health Potion', from: {12, 2}

-- with spritedef file: 'crawl-weapons-ranged.png', size: {32,32}, tiled: true, kind: 'variant'

mapdef.define {
	name: "start" 
	generator: (G, rng) ->
		model = gen.generate_empty_model(rng)
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

} do require(vpath)

require "stats.races.DefineRaces"
