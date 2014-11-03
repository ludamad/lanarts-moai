import ErrorReporting from require 'system'

import util_test from require 'core'
import RawNetConnection from require 'core.net_connection'

TEST_PORT = 3000
GIVE_UP_POLLS = 1000 -- One second

-- 's' is a GameState
make_step = (s) ->
    s.fork_step_number = s.step_number
    s.actions\queue_action(util_test.mock_action(s, s.local_player_id, s.step_number))
    pretty "make_step () :: LastAck", s.net_handler.last_acknowledged_frame
    s.net_handler\send_unacknowledged_actions()
    s.step_number += 1

sync_players = (states) ->
    for s in *states
        while #s.players < #states
            s.net_handler\poll(1)
            for G in *states do G.net_handler\poll()

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

    polls_till_fail = GIVE_UP_POLLS

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
      action = GameAction.create(playerid, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12)
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

    polls_till_fail = GIVE_UP_POLLS 

    while not server_got_action or not client_got_action
      client\poll(1)
      server\poll(1)

      polls_till_fail -= 1
      if polls_till_fail < 0 then error "Too many polls during connection!"

    server\disconnect()
    client\disconnect()
    -- Ensure next test uses a different port:
    TEST_PORT += 1

  it "Action sync test for N_TEST_PLAYERS players", () ->
    -- Test the fundamentals

    import GameAction from require "core.game_actions"
    N_PLAYERS = tonumber(os.getenv "N_TEST_PLAYERS") or 3
    if os.getenv "TEST_LAG"
        return 

    -- The player states:
    states = util_test.mock_player_network(TEST_PORT, N_PLAYERS)
    server = states[1]

    print "pre connect"
    -- Ensure initialization:
    sync_players (states)
    print "post connect - everyone is aware of all the players"
    util_test.mock_player_network_post_connect(states)
    -- Sanity check: 
    print "sanity check, sending one action to everyone"
    for s in *states do make_step(s)

    for s in *states 
        print "Complete for player #{s.local_player_id}"
        -- Complete the action for everyone
        while not s.actions\have_all_actions_for_step(s.step_number - 1)
            s.net_handler\poll(1)
            for G in *states 
                G.net_handler\poll()
    print "action received by everyone"
    print "frame completion lag"

    -- Ensure next test uses a different port:
    TEST_PORT += 1

  it "Client Side Prediction test", () ->
    -- Test statistics about client side prediction, simulate for 180 steps (use with netem to simulate lag)

    import GameAction from require "core.game_actions"
    N_PLAYERS = tonumber(os.getenv "N_TEST_PLAYERS") or 2

    -- The player states:
    states = util_test.mock_player_network(TEST_PORT, N_PLAYERS)
    server = states[1]

    print "pre connect"
    -- Ensure initialization:
    sync_players (states)
    print "post connect - everyone is aware of all the players"
    util_test.mock_player_network_post_connect(states)

    allowed_moveahead = tonumber(os.getenv("NET_MOVEAHEAD")) or 5
    ensure_step = (step) ->
        for s in *states
            while not s.actions\have_all_actions_for_step(step)
               s.net_handler\poll(1)
               for G in *states 
                   G.net_handler\poll()
                   G.net_handler\send_unacknowledged_actions()
    prev_time = MOAISim.getDeviceTime()
    -- Sanity check: 
    print "sanity check, sending one action to everyone"
    for i = 1,180
        for s in *states 
            make_step(s)
        if i > allowed_moveahead 
            print "Delta for #{i}: #{(MOAISim.getDeviceTime() - prev_time)*1000}ms"
            ensure_step(i-allowed_moveahead)
            prev_time = MOAISim.getDeviceTime()
    ensure_step(180)
    print "Delta for final step:", MOAISim.getDeviceTime() - prev_time

    print "actions received by everyone"

    -- Ensure next test uses a different port:
    TEST_PORT += 1
