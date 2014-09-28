import Display from require "ui"

PLAYER_COLORS = {
    Display.COL_PALE_RED
    Display.COL_PALE_GREEN
    Display.COL_MAGENTA
    Display.COL_CYAN
    Display.COL_MEDIUM_PURPLE
}

setup_player_state = (G) ->
	G.next_player_id = 1
    G.players = {}
    G.local_player_id = nil

    -- Generally only used by the server:
    G.add_new_player = (name, is_controlled, peer=nil) ->
        assert(G.gametype ~= 'client', "Should not be called by a client!")
        for p in *G.players do assert(p.peer ~= peer, "Attempting to assign two player IDs to the same peer (or server)!")
        -- Peer is remembered for servers
        append G.players, {id_player: G.next_player_id, player_name: name, :is_controlled, :peer, color: PLAYER_COLORS[G.next_player_id % #PLAYER_COLORS + 1]}
        if is_controlled
            assert(G.local_player_id == nil)
            G.local_player_id = G.next_player_id
        G.next_player_id += 1

    G.peer_player_id = (peer) ->
    	for player in *G.players
    		if player.peer == peer
    			return player.id_player
    	return nil

    G.local_player = () -> 
        for L in *G.maps do for player in *L.player_list
            if G.is_local_player(player)
                return player

    G.is_local_player = (obj) ->
        player = G.players[obj.id_player]
        return player.is_controlled

    G.player_name = (obj) ->
        player = G.players[obj.id_player]
        return player.player_name

return {:setup_player_state}