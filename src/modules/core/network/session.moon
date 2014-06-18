import host_create from require "enet"
luv = require "luv"
newthread, newfiber = luv.thread.spawn, luv.fiber.create

-- Create a zero-mq instance with one channel
Z = luv.zmq.create(1)

create_client = () ->
	host = enet.host_create()
	connection = host\connect("localhost:7890", nil, 2)
	-- Wait for connection
	while true
		event = host\service(1000)
		if event and event.type == "connect"
			break
	print "Connected"
	while true
		event = host\service(1000)
		connection\send "Hello"

create_server = () ->
	host = enet.host_create("localhost:7890", nil, 2)
	while true
		event = host\service(1000)
		if event 
			pretty(event)
		if event and event.type == "receive"
			print("Got message: ", event.data, event.peer)

ServerConnection = with newtype()
	.init = (ip, port, channels) =>
		loc = ip .. ":" .. port
		@host = enet.host_create(loc, nil, channels)
		@peers = {}
		@messages = {}

	.poll = () =>
		while true
			event = host\service(0)
			-- Continue polling until we are not receiving events
			if not event then break
			if event.type == "connect"
				append @peers, event.peer
			elseif event.type == "receive"
				append @messages, event


	.disconnect = () =>
		@host\flush()

ClientConnection = with newtype()
	.init = (ip, port, channels) =>
		loc = ip .. ":" .. port
		@host = enet.host_create()
		@connection = @host\connect(loc, nil, channels)

	.disconnect = () =>
		@host\flush()
		@connection\close()

ClientSession = with newtype()
	.init = () =>
		@messages = {}
		@actions = {}
	.actions_for_frame = () => nil

main = () ->
	if os.getenv "S"
		print 'create_server'
		create_server()
	else
		print 'create_client'
		create_client()

return {:main}