-- Implements the game networking state machine.
--
-- 2 channels are used:
--   channel 0 is used reliably for control messages, such as notifications and full-state sync's
--   channel 1 is used unreliably for low-latency communications, primarily for sending actions
--		When sending actions we know which was the last action received 'for sure' due to the game moving forward, so to speak.
-- 		Every time we would send data, or periodically if no data has been sent, resend all actions that have not been for-sure received.

import networking from require "core"
DataBuffer = require 'DataBuffer'
json = require 'json'

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
-- Message handling
-------------------------------------------------------------------------------

_handle_player_action = (G, action) ->
    append G.player_action_queue, action

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

_handle_receive_event = (G, event) ->
    -- Message stream
    if event.channel == 1
        -- Normal message
        if G.gametype == 'server'
            _server_handle_message G, event
        else 
            _client_handle_message G, event

setup_network_functions = (G) ->
    G.message_buffer = DataBuffer.create()

	G.start_connection = () ->
	    if G.gametype == 'server'
	        G.connection = networking.ServerConnection.create(3000, 2)
	    elseif G.gametype == 'client'
	        G.connection = networking.ClientConnection.create('localhost', 3000, 2)
        G.accepting_connections = true

    G.action_send = (action_data) ->
        -- Send an unreliable message over channel 0
        G.connection\send(action_data, 0)

    G.message_send = (obj, peer = nil) ->
        str = json.generate(obj)
        print("msg_send", str)
        -- Note: We send reliable messages over channel 1
        if peer -- Did we specify a peer? (server-only)
            peer\send(str,1)
        else -- Broadcast (if server) or send to server (if client)
            G.connection\send(str, 1)

    G.handle_message_type = (type) ->
        -- TODO: Prevent simple attacks where memory is hogged up by unexpected messages
        for msg in *G.network_message_queue
            if msg.type == type
                table.remove_occurrences G.network_message_queue, msg
                return msg
        return nil

    -- Network message handler
    G.handle_network_event = (event) ->
        -- TODO: Action stream
        if G.gametype == 'client' and event.type == 'connect'
            G.message_send {type: 'JoinRequest', name: _SETTINGS.player_name}
        elseif event.type == 'receive'
            _handle_receive_event(G, event)

return {:setup_network_functions}