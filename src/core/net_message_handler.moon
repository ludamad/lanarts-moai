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
        append actions,GameAction.create(buffer)
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
        N\send_message {type: "ByeBye"}
        N.connection\disconnect()

    N.get_disconnects = () =>
        N.connection\get_disconnects()

    N.clear_disconnects = () =>
        N.connection\clear_disconnects()

    N.check_message = (type, unqueue) =>
        N.connection\check_message(type, unqueue)

    N.check_message_all = (type, unqueue) =>
        N.connection\check_message_all(type, unqueue)

    N.handshake = (type) =>
        N\send_message {:type}
        while true
            if N\check_message_all(type)
                return true
            N\poll(1)

    N._prep_action_buffer = (ack_to_send) =>
        @buffer\clear()
        @buffer\write_int(ack_to_send)
    N._flush_action_buffer = (channel, peer = nil) =>
        @connection\send_unsequenced(channel, @buffer\tostring(), peer)

    return N

MAX_PACKET_SIZE = 999999--1200

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
            handle_unsequenced_message: (msg) =>
                last_ack, actions = buffer_decode_actions(N.buffer, msg)
                new_actions = 0
                N.last_acknowledged_frame = math.max(last_ack, N.last_acknowledged_frame)
                for action in *actions
                    if G.queue_action(action)
                        new_actions += 1
                -- print(">> CLIENT RECEIVING #{#actions} ACTIONS, #{new_actions} NEW")
        }
    }

    N.min_acknowledged_frame = () => N.last_acknowledged_frame

    N.reset_frame_count = () =>
        N.last_acknowledged_frame = 0

    N.send_unacknowledged_actions = (lookback = nil) =>
        -- The current player
        pid = G.local_player_id
        first_to_send = if lookback then G.step_number - lookback else N.last_acknowledged_frame + 1
        -- Clear the buffer for writing
        N.buffer\clear()
        -- Acknowledge the last full frame
        ack_to_send = G.player_actions\find_latest_complete_frame()
        -- Channel to send over
        channel = if lookback then 1 else 2

        -- Clear the buffer for writing
        @_prep_action_buffer(ack_to_send)

        -- From the last acknowledge frame, to our most recent, send
        -- all the actions
        for i=first_to_send, G.player_actions\last()
            frame = G.player_actions\get_frame(i)
            if frame
                action = frame\get(pid)
                if action 
                    action\write(N.buffer)
                    if @buffer\size() >= MAX_PACKET_SIZE
                        @_flush_action_buffer(channel)
                        -- Clear the buffer for writing
                        @_prep_action_buffer(ack_to_send)

        -- print("CLIENT SENDING #{first_to_send}, to #{G.player_actions\last()}, #{n_actions} ACTIONS")

        if @buffer\size() > 4 -- Does it have an action?
            @_flush_action_buffer(channel)

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
            handle_unsequenced_message: (msg) =>
                last_ack, actions = buffer_decode_actions(N.buffer, msg)
                N.last_acknowledged_frame[msg.peer] = math.max(last_ack, N.last_acknowledged_frame[msg.peer] or 0)
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
            min = math.min(min, v)
        return (if min == math.huge then 0 else min)

    N.reset_frame_count = () =>
        N.last_acknowledged_frame = {}

    -- Basic idea: Continuously send something every frame if it was not acknowledge
    N.send_unacknowledged_actions = () =>
        for peer in *@peers()
            if peer ~= msg.peer
                N.connection\send_unsequenced msg.data, peer

    _send_unacknowledged_actions = (peer, lookback = nil) =>
        -- The current player
        pid = G.peer_player_id(peer)
        first_to_send = if lookback then G.step_number - lookback else (N.last_acknowledged_frame[peer] or 0) + 1
        -- last_ack = G.player_actions\first()
        last_action = G.seek_action(pid)
        if not last_action 
            return 
        ack_to_send = (if last_action then last_action.step_number else G.fork_step_number - 1)
        -- Channel to send over
        channel = if lookback then 1 else 2

        -- Clear the buffer for writing
        @_prep_action_buffer(ack_to_send)

        -- From the last acknowledge frame, to our most recent, send
        -- all the actions
        for i=first_to_send, G.player_actions\last()
            frame = G.player_actions\get_frame(i)
            if frame
                for action in *frame.actions
                    if action and action.id_player ~= pid
                        action\write(N.buffer)
                        if @buffer\size() >= MAX_PACKET_SIZE
                            @_flush_action_buffer(channel, peer)
                            -- Clear the buffer for writing
                            @_prep_action_buffer(ack_to_send)

        if @buffer\size() > 4 -- Does it have an action?
            @_flush_action_buffer(channel, peer)

        logV("SERVER SENDING PEER #{peer} PID #{pid} #{first_to_send}, to #{G.player_actions\last()}")

    N.send_unacknowledged_actions = (lookback = nil) =>
        for peer in *@peers()
            _send_unacknowledged_actions(@, peer, lookback)

    setup_handler_base(N)
    return N


return {:ClientMessageHandler, :ServerMessageHandler}
