modules = require "core.data"
T =  modules.get_tilelist_id

import random_square_spawn_object from require '@util_generate'
import map_object_types from require 'core'



spawn_rats = (n_rats) -> (M) ->
    for i=1,n_rats
        random_square_spawn_object M, (px, py) ->
            map_object_types.NPC.create M, {
                x: px*32+16
                y: py*32+16
                type: "Giant Rat"
                radius: 10
                solid: true
                id_player: i
                speed: 6
            }

return {
	SMALL: (rng) -> {
		size: {35, 35}
		number_polygons: rng\random(3,8)
		outer_points: 20
		floor1: T('grey_floor')
		floor2: T('reddish_grey_floor')
		wall1: T('dungeon_wall')
		wall2: T('crypt_wall')
		rect_room_num_range: {1,4}
		rect_room_size_range: {3,8}
		n_statues: 3
		n_shops: 1
		n_stairs_down: 3
		n_stairs_up: 0
		room_radius: () ->
			r = 2
        	for j=1,rng\random(0,2) do r += rng\randomf(0, 1)
        	return r
        generate_objects: spawn_rats(1)
	}

	MEDIUM: (rng) -> {
		size: {80,80}
		number_polygons: rng\random(10,32)
		outer_points: 20
		floor1: T('grey_floor')
		floor2: T('reddish_grey_floor')
		wall1: T('dungeon_wall')
		wall2: T('crypt_wall')
		rect_room_num_range: {5,10}
		rect_room_size_range: {3,20}
		n_statues: 10
		n_shops: 2
		n_stairs_down: 3
		n_stairs_up: 3
		generate_objects: spawn_rats(rng\random(5,8))

	}
}