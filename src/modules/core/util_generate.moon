import TileMap from require 'core'

random_square_spawn_object = (L, spawner) ->
	sqr = TileMap.find_random_square {
		map: L.tilemap
		rng: L.rng
		selector: matches_none: {TileMap.FLAG_SOLID, TileMap.FLAG_HAS_OBJECT}
		operator: add: TileMap.FLAG_HAS_OBJECT
	}

	{px, py} = sqr

	spawner(px, py)

return {:random_square_spawn_object}