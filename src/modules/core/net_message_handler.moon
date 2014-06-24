-------------------------------------------------------------------------------
-- Message sending
-------------------------------------------------------------------------------

_broadcast_player_list = (G) ->
    -- Inform all players about the player list:
    for peer in *G.connection.peers do
        -- Recreate the player list, as the receiving peer (client player) would view it:
        list = {}
        for p in *G.players
            append list, {player_name: p.player_name, id_player: p.id_player, is_controlled: (peer == p.peer)}
        G.message_send {type: "PlayerList", list: list}, peer

-------------------------------------------------------------------------------
-- Generic message handling
-------------------------------------------------------------------------------

_client_handlers = {
    PlayerList: (G, msg) ->
        -- Trust the server to send all the data:
        table.clear(G.players)
        -- Rebuild the player list:
        for p in *msg.list
            append G.players, {id_player: p.id_player, player_name: p.player_name, is_controlled: p.is_controlled}
        pretty_print(G.players)
}

_client_handle_message = (G, event) ->
    status, msg = json.parse(event.data)
    if not status then error(msg)
    print('client_handle_msg', event.data)
    handler = _client_handlers[msg.type]
    if handler ~= nil
        handler(G, msg)
    else -- Allow ad-hoc handling:
        append G.network_message_queue, msg

_server_handlers = {
    JoinRequest: (G, msg) ->
        if G.accepting_connections
            G.add_new_player msg.name, false, msg.peer -- Not controlled
            _broadcast_player_list(G)
}

_server_handle_message = (G, event) ->
    status, msg = json.parse(event.data)
    if not status then error(msg)
    -- Remember the peer for determining message sender
    msg.peer = event.peer
    print('server_handle_msg', event.data)
    handler = _server_handlers[msg.type]
    if handler ~= nil
        handler(G, msg)
    else -- Allow ad-hoc handling:
        append G.network_message_queue, msg

-------------------------------------------------------------------------------
-- Game action handling
-------------------------------------------------------------------------------

_handle_game_actions = (G, event) ->
    buff\clear()
    buff\write_raw(event.data)
    n = buff\read_int()
    actions = {}
    for i=1,n
        append actions, game_actions.GameAction(buff)
    for action in *actions
        if G.gamestate == 'server' and G.peer_player_id(event.peer) ~= action.id_player
            error("Player #{G.peer_player_id(event.peer)} trying to send actions for player #{action.id_player}!")
        G.queue_action(action)

_handle_receive_event = (G, event) ->
    -- Message stream
    if event.channel == 0
        _handle_game_actions(G, event)
    if event.channel == 1
        -- Normal message
        if G.gametype == 'server'
            _server_handle_message G, event
        else 
            _client_handle_message G, event


    N.unqueue_message = (type) ->
        -- TODO: Prevent simple attacks where memory is hogged up by unexpected messages
        for msg in *N.network_message_queue
            if msg.type == type
                table.remove_occurrences N.network_message_queue, msg
                return msg
        return nil


return {}