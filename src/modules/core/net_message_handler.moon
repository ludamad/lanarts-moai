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
            if p.is_controlled
                G.local_player_id = p.id_player
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
    last_ack = buffer\read_int()
    actions = {}
    while buffer\can_read()
        append actions, GameAction.create(buffer)
    -- Note: Creating a GameAction will read the buffer
    return last_ack, actions

buffer_encode_actions = (last_ack, buffer, actions) ->
    buffer\clear()
    buffer\write_int(last_ack)
    buffer\write_int(#actions)
    for action in *actions
        action\write(buffer)
    return buffer\tostring()

-- Common to both ClientMessageHandler and ServerMessageHandler
setup_handler_base = (N) ->
    N.send_message = (obj, peer = nil) =>
        N.connection\send_reliable(obj, peer)

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
        -- Sent from server
        last_acknowledged_frame: 0
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
                last_ack, actions = buffer_decode_actions(N.buffer, msg)
                new_actions = 0
                N.last_acknowledged_frame = math.max(last_ack, 0 or N.last_acknowledged_frame)
                for action in *actions
                    if G.queue_action(action)
                        new_actions += 1
                -- print(">> CLIENT RECEIVING #{#actions} ACTIONS, #{new_actions} NEW")
        }
    }

    N.min_acknowledged_frame = () => N.last_acknowledged_frame

    N.send_unacknowledged_actions = () =>
        -- The current player
        pid = G.local_player_id
        last_ack = N.last_acknowledged_frame
        -- Clear the buffer for writing
        N.buffer\clear()
        -- Acknowledge the last full frame
        last_full = G.player_actions\find_latest_complete_frame()
        N.buffer\write_int(last_full)

        n_actions = 0
        -- From the last acknowledge frame, to our most recent, send
        -- all the actions
        for i=last_ack, G.player_actions\last()
            frame = G.player_actions\get_frame(i)
            if frame
                action = frame\get(pid)
                if action 
                    action\write(N.buffer)
                    n_actions +=1

        -- print("CLIENT PRINTING #{n_actions} ACTIONS")

        N.connection\send_unreliable(N.buffer\tostring())

    setup_handler_base(N)
    return N

ServerMessageHandler = create: (G, args) ->
    {:port} = args
    local N
    N = {
        -- One for each peer
        last_acknowledged_frame: {}
        -- Buffer for message serialization
        buffer: DataBuffer.create()
        connection: NetConnection.create {
            type: 'server'
            port: port
            handle_connect: (event) => 
                log("ServerMessageHandler.handle_connect")

            -- Returns false if message should be queued
            handle_reliable_message: (obj) => 
                log("ServerMessageHandler.handle_reliable_message")
                handle_message(N, G, handlers_server, obj)

            -- Action handler
            handle_unreliable_message: (msg) =>
                last_ack, actions = buffer_decode_actions(N.buffer, msg)
                N.last_acknowledged_frame[msg.peer] = math.max(last_ack, 0 or N.last_acknowledged_frame[msg.peer])
                new_actions = 0
                for action in *actions
                    if G.peer_player_id(msg.peer) ~= action.id_player
                        error("Player #{G.peer_player_id(msg.peer)} trying to send actions for player #{action.id_player}!")
                    if G.queue_action(action)
                        new_actions += 1
                -- print(">> SERVER RECEIVING #{#actions} ACTIONS, #{new_actions} NEW")
        }
    }

    N.min_acknowledged_frame = () => 
        min = math.huge
        for k,v in pairs(N.last_acknowledged_frame)
            min = math.min(math.huge, v)
        return (if min == math.huge then 0 else min)

    -- Basic idea: Continuously send something every frame if it was not acknowledge
    N.send_unacknowledged_actions = () =>
        for peer in *@peers()
            if peer ~= msg.peer
                N.connection\send_unreliable msg.data, peer

    _send_unacknowledged_actions = (peer) ->
        -- The current player
        pid = G.peer_player_id(peer)
        last_ack = N.last_acknowledged_frame[peer] or 0
        -- Clear the buffer for writing
        N.buffer\clear()
        -- Acknowledge the last full frame
        last_action = G.seek_action(pid)
        N.buffer\write_int(if last_action then last_action.step_number else G.fork_step_number)

        n_actions = 0
        -- From the last acknowledge frame, to our most recent, send
        -- all the actions
        for i=last_ack, G.player_actions\last()
            frame = G.player_actions\get_frame(i)
            if frame and frame\is_complete()
                for action in *frame.actions
                    if action.id_player ~= pid
                        action\write(N.buffer)
                        n_actions +=1

        -- print("SERVER PRINTING #{n_actions} ACTIONS")
        N.connection\send_unreliable(N.buffer\tostring())

    N.send_unacknowledged_actions = () =>
        for peer in *@peers()
            _send_unacknowledged_actions(peer)

    N.unqueue_message_all = (type) =>
        N.connection\unqueue_message_all(type)

    setup_handler_base(N)
    return N


return {:ClientMessageHandler, :ServerMessageHandler}
