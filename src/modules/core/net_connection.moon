-- Implements the game networking connection object.
--
-- 2 channels are used:
--   channel 0 is used unreliably for low-latency communications, intended for sending actions
--   channel 1 is used reliably for control messages, such as notifications and full-state sync's
--
-- Purposely separate from any game logic, or representation concerns.

import ClientConnection, ServerConnection from require "core.enet.connection"

create_connection = (args) ->
    N = {
        -- Network configuration --
        type: args.type
        port: args.port
        ip: args.ip

        handle_reliable_message: args.handle_reliable_message
        handle_unreliable_message: args.handle_unreliable_message
        handle_connect: args.handle_connect

        -- Network state --
        connection: false
    }

	N.connect = () ->
	    if N.type == 'server'
	        N.connection = connection.ServerConnection.create(N.port, 2)
	    elseif N.type == 'client'
	        N.connection = connection.ClientConnection.create(N.ip, N.port, 2)

    _send = (channel, data, reliable = true, peer = nil) ->
        -- Note: We send reliable messages over channel 1
        if peer -- Did we specify a peer? (server-only)
            if reliable
                peer\send(data, channel)
            else
                peer\send_unreliable(data, channel)
        else -- Broadcast (if server) or send to server (if client)
            if reliable
                N.connection\send(data, channel)
            else
                N.connection\send_unreliable(data, channel)

    N.send_unreliable = (data, peer = nil) ->
        -- Send an unreliable message over channel 0
        _send(0, data, true, peer)

    N.send_reliable = (obj, peer = nil) ->
        -- Send a reliable message over channel 1
        _send(1, data, true, peer)

    -- Network message handler
    _handle_network_event = (event) ->
        if event.type == 'connect'
            N.handle_connect(event)
        elseif event.type == 'receive' and event.channel == 0
            N.handle_unreliable_message(event)
        elseif event.type == 'receive' and event.channel == 1
            N.handle_reliable_message(event)
        else
            error("Network logic error!")

    N.poll = (wait_time = 0) ->
        N.connection\poll(wait_time)
        for event in *N.connection\grab_messages()
            _handle_network_event(event)

return {:create_connection}