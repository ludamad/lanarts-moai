enet = require 'enet'

ServerConnection = with newtype()
	.init = (port, channels) =>
		-- Allow connection from any address:
		loc = "*:" .. port
		host, status = enet.host_create(loc, nil, channels)
		if host == nil
			error(status)
		@host = host
		@host\compress_with_range_coder()
		@peers = {}
		-- Message queue
		@messages = {}

	.get_queued_messages = () => @messages
	.clear_queued_messages = () => table.clear(@messages)

	._handle_event = (event) =>
		if event
			if event.type == "connect"
				print event.peer, "has joined!"
				append @peers, event.peer
				append @messages, event
			elseif event.type == "receive"
				append @messages, event
			else
				pretty("Client got ", event)

	.poll = (wait_time = 0) =>
		event = @host\service(wait_time)
		-- Continue polling until we are not receiving events
		if @_handle_event(event)
			while true 
				if not @_handle_event(@host\service())
					return true
		return false


	.send = (msg,channel=0, peer) =>
		if peer
			peer\send msg, channel
		else
			@host\broadcast msg, channel
		@host\flush()

	.send_unreliable = (msg,channel=0, peer) =>
		if peer
			peer\send msg, channel, 'unreliable'
		else
			@host\broadcast msg, channel, 'unreliable'
		@host\flush()

	.disconnect = () =>
		@host\flush()
		for peer in *@peers
			peer\disconnect()

ClientConnection = with newtype()
	.init = (ip, port, channels) =>
		loc = ip .. ":" .. port
		@host = enet.host_create()
		@connection = @host\connect(loc, channels)
		@host\compress_with_range_coder()
		-- Message queue
		@messages = {}

	.get_queued_messages = () => @messages
	.clear_queued_messages = () => table.clear(@messages)

	.grab_messages = () =>
		msgs,@messages = @messages,{}
		return msgs

	._handle_event = (event) =>
		if event
			if event.type == "connect"
				print "Client connected!"
				append @messages, event
			elseif event.type == "receive"
				append @messages, event
			else
				pretty("Client got ", event)
			return true
		return false

	.poll = (wait_time = 0) =>
		event = @host\service(wait_time)
		-- Continue polling until we are not receiving events
		if @_handle_event(event)
			while true 
				if not @_handle_event(@host\service())
					return true
		return false

	.send = (msg, channel=0) =>
		@connection\send msg, channel
		@host\flush()

	.send_unreliable = (msg, channel=0) =>
		@connection\send msg, channel, 'unreliable'
		@host\flush()

	.disconnect = () =>
		@host\flush()
		@connection\disconnect()

return {:ServerConnection, :ClientConnection}