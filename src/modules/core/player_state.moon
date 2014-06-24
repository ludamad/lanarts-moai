
setup_player_state = (G) ->
	G.next_player_id = 1
    G.players = {}

    -- Generally only used by the server:
    G.add_new_player = (name, is_controlled, peer=nil) ->
        assert(G.gametype ~= 'client', "Should not be called by a client!")
        -- Peer is remembered for servers
        append G.players, {id_player: G.next_player_id, player_name: name, :is_controlled, :peer}
        G.next_player_id += 1

    G.peer_player_id = (peer) ->
    	for player in *G.players
    		if player.peer == peer
    			return player.id_player
    	return nil

    G.is_local_player = (obj) ->
        player = G.players[obj.id_player]
        return player.is_controlled

    G.player_name = (obj) ->
        player = G.players[obj.id_player]
        return player.player_name

return {:setup_player_state}