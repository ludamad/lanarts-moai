import TileMap from require 'core'

DEFAULT_SELECTOR = {matches_none: {TileMap.FLAG_SOLID, TileMap.FLAG_HAS_OBJECT}}
random_square_spawn_object = (L, spawner, selector = DEFAULT_SELECTOR) ->
	sqr = TileMap.find_random_square {
		map: L.tilemap
		rng: L.rng
		:selector
		operator: add: TileMap.FLAG_HAS_OBJECT
	}
	if not sqr
		return false
	{px, py} = sqr

	spawner(px, py)
	return true

return {:random_square_spawn_object}