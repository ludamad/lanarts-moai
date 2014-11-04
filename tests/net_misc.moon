import ErrorReporting from require 'system'

import util_test from require 'core'
import RawNetConnection from require 'core.net_connection'

TEST_PORT = 3000
GIVE_UP_POLLS = 1000 -- One second

-- 's' is a GameState
make_step = (G) ->
    G.actions\queue_action(util_test.mock_action(G, G.local_player_id, G.step_number))
    pretty "make_step () :: LastAck", G.net_handler.last_acknowledged_frame
    G.net_handler\send_unacknowledged_actions()
    G.step_number += 1

sync_on_players = (G, n_players) ->
    while #G.players < n_players
        G.net_handler\poll(1)

sync_on_message = (G, msg) ->
    net_send = (type, data = nil) ->
        G.net_handler\send_message {:type, :data}
    net_recv = (type) -> G.net_handler\check_message_all(type)
    net_send(msg)
    while true
        responses = net_recv(msg)
        if responses
            for r in *responses
                print "received msg #{r}"
            break
        G.net_handler\poll(1)

action_lag_test = () ->
    -- Test statistics about client side prediction, simulate for 180 steps (use with netem to simulate lag)

    import GameAction from require "core.game_actions"

    N_PLAYERS = os.getenv("TEST_PLAYERS") or 4
    IS_SERVER = (os.getenv("TEST_SERVER") ~= nil)  
    -- The player Gs:
    G = (if IS_SERVER then util_test.mock_server() else util_test.mock_client())
        
    print "pre connect"
    -- Ensure initialization:
    sync_on_players(G, N_PLAYERS)
    pid = G.local_player_id
    print "post connect - everyone is aware of all the players"
    G\initialize_actions()
    sync_on_message(G, "post connect")
    print "post post connect #{pid} - everyone is ready to receive actions"

    allowed_moveahead = tonumber(os.getenv("NET_MOVEAHEAD")) or 20
    ensure_step = (step) ->
        while not G.actions\have_all_actions_for_step(step)
           G.net_handler\poll(1)
           G.net_handler\send_unacknowledged_actions()
        G.fork_step_number = step
    prev_time = MOAISim.getDeviceTime()
    -- Sanity check: 
    print "sanity check, sending one action to everyone"
    for i = 1,180
        make_step(G)
        if i > allowed_moveahead 
            print "Delta for #{i}: #{(MOAISim.getDeviceTime() - prev_time)*1000}ms"
            ensure_step(i-allowed_moveahead)
            prev_time = MOAISim.getDeviceTime()
    ensure_step(180)
    print "Delta for final step:", (MOAISim.getDeviceTime() - prev_time)*1000

    print "actions received by everyone"

action_lag_test()
