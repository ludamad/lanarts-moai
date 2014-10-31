-- Helpers for creating mock GameState objects:

import GameState from require "@game_state"
import make_move_action from require "@game_actions"

with_mock_settings = (t) -> (f) ->
	prev = _G._SETTINGS
	_G._SETTINGS = table.clone(_G._SETTINGS)
	table.merge(_G._SETTINGS, t)
	val = f()
	_G._SETTINGS = prev
	return val

mock_gamestate = (settings) -> with_mock_settings(settings) ->
	G = GameState.create()
	G\initialize_rng(1)
	return G

mock_player_network = (server_port, n_players) ->
	assert n_players >= 1
	_SETTINGS = {}
	server = mock_gamestate {gametype: 'server', :server_port}
	server\add_new_player("TestServer5000", true)
	states = {server}
	for i=1,n_players-1 
		append states, mock_gamestate {gametype: 'client', server_ip: 'localhost', :server_port}

	return states

mock_player_network_post_connect = (states) ->
	for G in *states do G\initialize_actions()

mock_action = (G, pid, step_number) ->
	d = G.rng\randomf(-1,1)
	mock_player_obj = {id_player: pid, x: 0, y: 0}
	return make_move_action(0, mock_player_obj, step_number, d, d, false)

return {:with_mock_settings, :mock_gamestate, :mock_player_network, :mock_player_network_post_connect, :mock_action}
