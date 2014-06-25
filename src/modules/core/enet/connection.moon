enet = require 'enet'

ServerConnection = with newtype()
	.init = (port, channels) =>
		loc = "localhost:" .. port
		host, status = enet.host_create(loc, nil, channels)
		if host == nil
			error(status)
		@host = host
		@peers = {}
		-- Message queue
		@messages = {}

	.grab_messages = () =>
		msgs,@messages = @messages,{}
		return msgs

	.poll = (wait_time = 0) =>
		event = @host\service(wait_time)
		-- Continue polling until we are not receiving events
		if event
			if event.type == "connect"
				print event.peer, " has joined!"
				append @peers, event.peer
				append @messages, event
			elseif event.type == "receive"
				append @messages, event
			else
				pretty("Server got ", event)
			return true
		return false

	.send = (msg,channel=0) =>
		@host\broadcast msg, channel

	.send_unreliable = (msg,channel=0) =>
		@host\broadcast msg, channel, 'unreliable'

	.disconnect = () =>
		for peer in *@peers
			peer\disconnect()
		@host\flush()

ClientConnection = with newtype()
	.init = (ip, port, channels) =>
		loc = ip .. ":" .. port
		@host = enet.host_create()
		@connection = @host\connect(loc, channels)
		-- Message queue
		@messages = {}
		@connected = false

	.grab_messages = () =>
		msgs,@messages = @messages,{}
		return msgs

	.poll = () =>
		event = @host\service(0)
		-- Continue polling until we are not receiving events
		if event
			if event.type == "connect"
				assert not @connected
				@connected = true
				print "Client connected!"
				append @messages, event
			elseif event.type == "receive"
				append @messages, event
			else
				pretty("Client got ", event)
			return true
		return false

	.send = (msg, channel=0) =>
		@connection\send msg, channel

	.send_unreliable = (msg, channel=0) =>
		@connection\send msg, channel, 'unreliable'

	.disconnect = () =>
		@host\flush()
		@connection\disconnect()

return {:ServerConnection, :ClientConnection}