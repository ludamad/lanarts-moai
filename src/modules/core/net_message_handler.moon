import NetConnection from require 'core.net_connection'
import GameAction from require "core.game_actions"
DataBuffer = require 'DataBuffer'

-------------------------------------------------------------------------------
-- Message sending
-------------------------------------------------------------------------------

send_message_broadcast_player_list = (G) =>
    -- Inform all players about the player list:
    for peer in *@peers() do
        -- Recreate the player list, as the receiving peer (client player) would view it:
        list = {}
        for p in *G.players
            append list, {player_name: p.player_name, id_player: p.id_player, is_controlled: (peer == p.peer)}
        @send_message {type: "PlayerList", list: list}, peer

-------------------------------------------------------------------------------
-- Message handling
-------------------------------------------------------------------------------

handlers_client = {
    PlayerList: (G, msg) =>
        -- Trust the server to send all the data:
        table.clear(G.players)
        -- Rebuild the player list:
        for p in *msg.list
            append G.players, {id_player: p.id_player, player_name: p.player_name, is_controlled: p.is_controlled}
        pretty_print(G.players)
}

handlers_server = {
    JoinRequest: (G, msg) =>
        G.add_new_player msg.name, false, msg.peer -- Not controlled
        send_message_broadcast_player_list(@, G)
}

handle_message = (G, handlers, msg) =>
    handler = handlers[msg.type]
    if handler ~= nil
        handler(@, G, msg)
        return true
    return false

-------------------------------------------------------------------------------
-- Action serialization
-------------------------------------------------------------------------------

buffer_decode_actions = (buffer, msg) ->
    buffer\clear()
    buffer\write_raw(msg.data)
    n = buffer\read_int()
    -- Note: Creating a GameAction will read the buffer
    return [GameAction.create(buffer) for i=1,n]

buffer_encode_actions = (buffer, actions) ->
    buffer\clear()
    buffer\write_int(#actions)
    for action in *actions
        action\write(buffer)
    return buffer\tostring()

-- Common to both ClientMessageHandler and ServerMessageHandler
setup_handler_base = (N) ->
    N.send_message = (obj, peer = nil) =>
        pretty("SENDING", obj)
        N.connection\send_reliable(obj, peer)

    N.send_actions = (actions, peer = nil) =>
        msg = buffer_encode_actions(N.buffer, actions)
        N.connection\send_unreliable(msg, peer)

    N.poll = (wait_time = 0) =>
        N.connection\poll(wait_time)

    N.peers = () => N.connection\peers()

    N.connect = () =>
        N.connection\connect()

    N.disconnect = () =>
        N.connection\disconnect()

    N.unqueue_message = (type) =>
        N.connection\unqueue_message(type)

    return N

-------------------------------------------------------------------------------
-- Client & server message handlers
-------------------------------------------------------------------------------

ClientMessageHandler = create: (G, args) ->
    {:ip, :port} = args
    local N
    N = {
        -- Buffer for message serialization
        buffer: DataBuffer.create()
        connection: NetConnection.create {
            type: 'client'
            ip: ip
            port: port
            handle_connect: () => 
                log("ClientMessageHandler.handle_connect")
                N\send_message {type: 'JoinRequest', name: _SETTINGS.player_name}

            -- Returns false if message should be queued
            handle_reliable_message: (obj) => 
                log("ClientMessageHandler.handle_reliable_message")
                handle_message(N, G, handlers_client, obj)

            -- Action handler
            handle_unreliable_message: (msg) =>
                actions = buffer_decode_actions(N.buffer, msg)
                for action in *actions
                    G.queue_action(action)
        }
    }
    setup_handler_base(N)
    return N

ServerMessageHandler = create: (G, args) ->
    {:port} = args
    local N
    N = {
        -- Buffer for message serialization
        buffer: DataBuffer.create()
        connection: NetConnection.create {
            type: 'server'
            port: port
            handle_connect: (event) => 
                log("ServerMessageHandler.handle_connect")
                pretty "Server got connection", event

            -- Returns false if message should be queued
            handle_reliable_message: (obj) => 
                log("ServerMessageHandler.handle_reliable_message")
                handle_message(N, G, handlers_server, obj)

            -- Action handler
            handle_unreliable_message: (msg) =>
                actions = buffer_decode_actions(N.buffer, msg)
                for action in *actions
                    if G.peer_player_id(msg.peer) ~= action.id_player
                        error("Player #{G.peer_player_id(event.peer)} trying to send actions for player #{action.id_player}!")
                    G.queue_action(action)
        }
    }
    setup_handler_base(N)
    return N


return {:ClientMessageHandler, :ServerMessageHandler}
