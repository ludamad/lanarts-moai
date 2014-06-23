-- By default, tiles are 32x32

gen = require '@generate'
object_types = require 'core.object_types'
import TileMap from require "core"

with tiledef file: 'floor.png', solid: false
    .define name: 'undefined', from: {1,1}, to: {2,1}
    .define name: 'grey_floor', from: {3,1}, to: {11,1}

with tiledef file: 'wall.png', solid: true
    .define name: 'dungeon_wall', from: {1,1}, to: {32, 1}

with spritedef file: 'feat.png', size: {32,32}, tiled: true, kind: 'variant'
    .define name: 'door_closed', from: {3, 2}
    .define name: 'door_open',   from: {10, 2}    
    .define name: 'shop',        from: {11,6}, to: {21,6}

with spritedef file: 'player.png', size: {32,32}, tiled: true, kind: 'variant'
    .define name: 'player', from: {1, 1}

with spritedef file: 'monsters.png', size: {32,32}, tiled: true, kind: 'variant'
    .define name: 'monster', from: {1, 1}

leveldef.define {
	name: "start" 
	generator: (G, rng) ->
		model = gen.generate_empty_model(rng)
		-- for i=1,50 do spawn rng, model, 
		-- 	(px, py) -> (L) ->
		-- 		object_types.NPC.create L, {
		-- 			x: px*32+16
		-- 			y: py*32+16
		-- 			radius: 10
		-- 			solid: true
		-- 			speed: 4
		-- 		}
		return model
}
