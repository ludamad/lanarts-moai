-- By default, tiles are 32x32

gen = require 'generate'
objects = require 'game.objects'
import mapgen from require "lanarts"

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

spawn_player = (rng, model) ->
	sqr = mapgen.find_random_square {
		map: model
		rng: rng
		selector: matches_none: {mapgen.FLAG_SOLID, mapgen.FLAG_HAS_OBJECT}
		operator: add: mapgen.FLAG_HAS_OBJECT
	}

	{px, py} = sqr

	player = objects.Player.create{
		x: px*32
		y: py*32
		radius: 10
		solid: true
	}

	model.instances\add(player, sqr)

leveldef.define {
	name: "start" 
	generator: (rng) ->
		model = gen.generate_test_model(rng)
		for i=1,10
			spawn_player(rng, model)
		return model
}