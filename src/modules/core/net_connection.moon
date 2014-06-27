-- Implements the game networking connection object.
--
--   channel 0 is used reliably for control messages, such as notifications and full-state sync's 
--   The remaining channels are used for unreliably for low-latency communications, intended for sending actions
--
-- Purposely separate from any game logic, or representation concerns.

import ClientConnection, ServerConnection from require "core.enet.connection"

N_CHANNELS = 3

RawNetConnection = create: (args) ->
    N = {
        -- Network configuration --
        type: assert(args.type, "Connection type not provided!")
        port: assert(args.port, "Port not provided!")
        ip: args.ip -- Only necessary if type == 'client' client specified

        handle_reliable_message: args.handle_reliable_message
        handle_unsequenced_message: args.handle_unsequenced_message
        handle_connect: args.handle_connect

        -- Network state --
        connection: false
    }

	N.connect = () =>
	    if N.type == 'server'
	        N.connection = ServerConnection.create(N.port, N_CHANNELS)
	    elseif N.type == 'client'
	        N.connection = ClientConnection.create(N.ip, N.port, N_CHANNELS)

    _send = (channel, data, reliable = true, peer = nil) ->
        -- Note: We send reliable messages over channel 1
        if peer -- Did we specify a peer? (server-only)
            if reliable
                N.connection\send(data, channel, peer)
            else
                N.connection\send_unsequenced(data, channel, peer)
        else -- Broadcast (if server) or send to server (if client)
            if reliable
                N.connection\send(data, channel)
            else
                N.connection\send_unsequenced(data, channel)

    N.send_unsequenced = (channel, data, peer = nil) =>
        -- log("RawNetConnection.send_unsequenced", data)
        -- Send an unsequenced message over the specified channel
        assert(channel > 0)
        _send(channel, data, false, peer)

    N.send_reliable = (data, peer = nil) =>
        -- Send a reliable message over channel 0
        log("RawNetConnection.send_reliable", data)
        _send(0, data, true, peer)

    -- Network message handler
    _handle_network_event = (event) ->
        if event.type == 'connect'
            N\handle_connect(event)
        elseif event.type == 'receive' and event.channel == 0
            N\handle_reliable_message(event)
        elseif event.type == 'receive' and event.channel > 0
            N\handle_unsequenced_message(event)
        else
            error("Network logic error!")

    N.peers = () =>
        return N.connection.peers

    N.poll = (wait_time = 0) =>
        N.connection\poll(wait_time)
        for event in *N.connection\get_queued_messages()
            _handle_network_event(event)
        N.connection\clear_queued_messages()

    N.disconnect = () =>
        N.connection\disconnect()

    return N


-- Provide a simple JSON-based convenience wrapper over RawNetConnection
-- and a fallback message queue, and a concept of a message 'type'

json = require 'json'

-- Ad-hoc inheritance of RawNetConnection:
NetConnection = create: (args) ->
    _msgqueue = {} -- Network message queue

    -- Delegates for message handling
    _rel_f = args.handle_reliable_message

    N = RawNetConnection.create {
        type: args.type
        ip: args.ip -- For server only
        port: args.port
        handle_connect: args.handle_connect
        handle_reliable_message: (msg) =>
            status, obj = json.parse(msg.data)
            if not status then error(obj)
            obj.peer = msg.peer
            -- Try to handle message, otherwise add to the queue
            if not _rel_f(@, obj)
                append _msgqueue, obj

        handle_unsequenced_message: args.handle_unsequenced_message
    }

    raw_send_reliable = N.send_reliable

    N.send_reliable = (obj, peer = nil) =>
        data = json.generate(obj)
        raw_send_reliable(@, data, peer)

    N.unqueue_message = (type) =>
        assert(_G.type(type) == 'string', "Unqueue type must be a string!")
        -- TODO: Prevent simple attacks where memory is hogged up by unexpected messages
        for obj in *_msgqueue
            if obj.type == type
                log("NetConnection.unqueue_message: unqueuing", type)
                table.remove_occurrences _msgqueue, obj
                return obj
        return nil

    -- Server only, used for a many-to-one confirmation
    -- Eg, if server must receive a message from every client to initiate an action
    N.unqueue_message_all = (type) =>
        assert(_G.type(type) == 'string', "Unqueue type must be a string!")
        messages = {}
        for peer in *N\peers()
            for obj in *_msgqueue
                if obj.type == type and obj.peer == peer
                    append messages, obj
        -- Did we get a message from every peer?
        if #messages == #N\peers()
            for obj in *messages
                table.remove_occurrences _msgqueue, obj
            log("NetConnection.unqueue_message_all: unqueuing", type)
            return messages
        -- All or nothing
        return nil

    return N

return {:RawNetConnection, :NetConnection}