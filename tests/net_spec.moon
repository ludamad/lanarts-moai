import ErrorReporting from require 'system'

import RawNetConnection from require 'core.net_connection'

TEST_PORT = 3000

describe "net_connection test", () ->
  it "simple messsage handshake", () ->
    server_connected = false
    client_connected = false
    got_server_connect = false
    got_client_connect = false

    server = RawNetConnection.create {
      type: 'server'
      port: TEST_PORT
      handle_connect: () =>
        print 'server handle connect'
        server_connected = true
        @send_reliable "server"

      handle_reliable_message: (msg) =>
        if msg.data == "client"
          got_client_connect = true
        else 
          error(msg.data)

      handle_unreliable_message: () => nil
    }

    client = RawNetConnection.create {
      type: 'client'
      port: TEST_PORT
      ip: 'localhost'
      handle_connect: () =>
        print 'client handle connect'
        client_connected = true
        @send_reliable "client"

      handle_reliable_message: (msg) =>
        if msg.data == "server"
          got_server_connect = true

      handle_unreliable_message: () => nil
    }

    server\connect()
    client\connect()

    polls_till_fail = 100

    while not server_connected or not client_connected
      client\poll(1)
      server\poll(1)

      polls_till_fail -= 1
      if polls_till_fail < 0 then error "Too many polls during connection!"

    while not got_server_connect or not got_client_connect
      client\poll(1)
      server\poll(1)

      polls_till_fail -= 1
      if polls_till_fail < 0 then error "Too many polls during handshake!"

    assert(server_connected and client_connected and got_server_connect and got_client_connect)

    server\disconnect()
    client\disconnect()
    -- Ensure next test uses a different port:
    TEST_PORT += 1

  it "game action serialization", () ->
    -- Test the fundamentals

    import GameAction from require "core.game_actions"
    DataBuffer = require 'DataBuffer'

    buffer = DataBuffer.create()
    actions = {}
    actiondata = {}

    for playerid=1,2
      action = GameAction.create(playerid, 2, 3, 4, 5, 6, 7, 8)
      buffer\clear()
      action\write(buffer)
      append actiondata, buffer\tostring()

    server_got_action = false
    client_got_action = false

    server = RawNetConnection.create {
      type: 'server'
      port: TEST_PORT
      handle_connect: () =>
        print 'server handle connect'
        @send_reliable actiondata[1]

      handle_reliable_message: (msg) =>
        buffer\clear()
        buffer\write_raw(msg.data)
        action = GameAction.create(buffer)
        pretty(action)
        server_got_action = true

      handle_unreliable_message: () => nil
    }

    client = RawNetConnection.create {
      type: 'client'
      port: TEST_PORT
      ip: 'localhost'
      handle_connect: () =>
        print 'client handle connect'
        @send_reliable actiondata[2]

      handle_reliable_message: (msg) =>
        buffer\clear()
        buffer\write_raw(msg.data)
        action = GameAction.create(buffer)
        pretty(action)
        client_got_action = true

      handle_unreliable_message: () => nil
    }

    server\connect()
    client\connect()

    polls_till_fail = 100

    while not server_got_action or not client_got_action
      client\poll(1)
      server\poll(1)

      polls_till_fail -= 1
      if polls_till_fail < 0 then error "Too many polls during connection!"

    server\disconnect()
    client\disconnect()
    -- Ensure next test uses a different port:
    TEST_PORT += 1
