import thread_create from require 'core.util'
import serialization from require 'core'
import mtwist from require ''
import ErrorReporting from require 'system'
import ClientMessageHandler, ServerMessageHandler from require 'core.net_message_handler'
user_io = require 'user_io'

_G.perf_time = (name, f) -> 
    before = MOAISim\getDeviceTime()
    f()
    after = MOAISim\getDeviceTime()
    print "'#{name}' took #{after - before} seconds!"

-------------------------------------------------------------------------------
-- The main stepping 'thread' (coroutine)
-------------------------------------------------------------------------------

DISABLE = 1000 -- Arbitrarily large

FORK_ADVANCE = DISABLE
PREDICT_STEPS = if _SETTINGS.network_lockstep then 0 else 60
SLOWDOWN_STEPS = 50
CHECK_TIME = 0 / 1000 -- seconds

last_time = MOAISim\getDeviceTime()

_net_step = (G) ->
    previous_step = G.step_number
    -- Manage time passage
    new_time = MOAISim\getDeviceTime()
    time_passed = (new_time - last_time)

    -- Incorporate new information (if any) and replay actions
    last_best = G.player_actions\find_latest_complete_frame()
    -- Ensure we don't step past the current step
    last_best = math.min(last_best, G.step_number)
    -- Could we move our fork further along?
    if time_passed > CHECK_TIME and last_best >= G.fork_step_number
        last_time = new_time
        next_fork_target = math.min(previous_step, G.fork_step_number + FORK_ADVANCE)

        G.serialize_revert()
        -- Move our state until the point where complete information is exhausted
        -- We should move one past from the point where we had information for forking
        while last_best >= G.step_number and G.step_number < next_fork_target
            -- Step with complete frame information
            G.doing_client_side_prediction = false
            G.step()
        -- Create a new fork
        G.serialize_fork()
        -- Move our state to our previous (potentially incomplete) position
        while previous_step > G.step_number
            -- Step with only client-side information
            G.doing_client_side_prediction = true
            G.step()

    -- Check that we are as advanced as we before (and not further)
    assert(previous_step == G.step_number, "Incorporated new information incorrectly!")
    if G.step_number > G.fork_step_number + SLOWDOWN_STEPS
        MOAISim.setStep(1 / _SETTINGS.frames_per_second_csp / 2)
    else
        MOAISim.setStep(1 / _SETTINGS.frames_per_second)
    if G.step_number <= G.fork_step_number + PREDICT_STEPS
        G.doing_client_side_prediction = true
        G.step()

check_quit_conditions = (G) ->
    if G.local_death
        return true
    -- Are we initiating a restart?
    if user_io.key_pressed "K_R"
        if G.net_handler 
            new_seed = G.rng\random(0, 2^31)
            G.net_handler\send_message {type: "Restart", :new_seed}
            G.net_handler\handshake "RestartAck"
            G.initialize_rng(new_seed)
        return true
    if not G.net_handler
        return false -- Rest are network triggered
    -- Did the other user(s) disconnect?
    if #G.net_handler\get_disconnects() > 0 or G.net_handler\check_message "ByeBye"
        os.exit() -- TODO: Fix

    -- Did we get a restart message?
    msg = G.net_handler\check_message "Restart"
    if msg 
        G.net_handler\handshake "RestartAck"
        G.initialize_rng(msg.new_seed)
        return true
    return false

main_thread = (G, on_death) -> profile () ->
    last_full_send_time = MOAISim\getDeviceTime()
    last_part_send_time = MOAISim\getDeviceTime()
    while true
        coroutine.yield()

        last_best = G.player_actions\find_latest_complete_frame()
        if G.net_handler then G.net_handler\poll(1)
        -- Should we make a local player action from user input, for the current frame?
        if not _SETTINGS.network_lockstep or not G.get_action(G.local_player_id, G.step_number)
            G.handle_io()
        if G.net_handler and not _SETTINGS.network_lockstep
            -- Client side prediction
            if MOAISim\getDeviceTime() > last_full_send_time + (100/1000)
                G.net_handler\send_unacknowledged_actions()
                last_full_send_time = MOAISim\getDeviceTime()

            -- if MOAISim\getDeviceTime() > last_part_send_time + (25/1000)
            --     G.net_handler\send_unacknowledged_actions(2) -- Only 2 frames back in time
            --     last_part_send_time = MOAISim\getDeviceTime()
            before = MOAISim\getDeviceTime()
            _net_step(G)
            after = MOAISim\getDeviceTime()
            logV "'_net_step' took #{(after - before)*1000} milliseconds!"

            last_needed = math.min(G.fork_step_number, G.net_handler\min_acknowledged_frame())
            G.drop_old_actions(last_needed - 1)
        elseif G.net_handler
            if G.step_number <= last_best
                -- Lock-step
                G.doing_client_side_prediction = false
                G.step()
                last_needed = math.min(G.fork_step_number, G.net_handler\min_acknowledged_frame())
                G.drop_old_actions(last_needed - 1)
        else -- Single player
            G.doing_client_side_prediction = false
            G.step()
            G.drop_old_actions(G.step_number - 1)
        G.pre_draw()

        if check_quit_conditions(G)
            return

setup_network_state = (G) ->
    if G.gametype == 'client'
        G.net_handler = ClientMessageHandler.create G, {ip: _SETTINGS.server_ip, port: _SETTINGS.server_port}
    elseif G.gametype == 'server'
        G.net_handler = ServerMessageHandler.create G, {port: _SETTINGS.server_port}

create_game_state = () ->
    G = {}

    G.maps = {}
    G.step_number = 1
    G.gametype = _SETTINGS.gametype
    G.local_death = false
    G.doing_client_side_prediction = false
    G.game_id = 0

    require("@player_state").setup_player_state(G)

    setup_network_state(G)

    -- Based on game type above, and _SETTINGS object for IP (for client) & port (for both client & server)
    if G.net_handler
        G.net_handler\connect()

    G.initialize_rng = (seed) ->
        logI("initialize_rng: Seed is", seed)
        G.rng = mtwist.create(seed)

    G.clear_game_data = () ->
        G.step_number = 1
        G.local_death = false
        if G.net_handler 
            G.net_handler\reset_frame_count()
        G.game_id = (G.game_id + 1) % 256
        for map in *G.maps
            -- Free resources allocated on the C/C++ side of the engine, as soon as possible.
            map\free_resources()
        table.clear G.maps
        G.reset_action_state()

    G.change_view = (V) ->
        if G.map_view and G.map_view.stop then
            G.map_view\stop()
        G.map_view = V
        G.map = V.map
        G.serialize_fork()
        G.map_view.start()

    -- Setup function
    G.start = (on_death) -> 
        G.map_view.start() unless G.map_view == nil

        return main_thread(G, on_death)

    -- Tear-down function
    G.stop = () -> 
        G.map_view.stop() unless G.map_view == nil
        for thread in *G.threads
            thread.stop()

    -- Game step function
    G.step = () -> 
        ret = G.map.step()
        G.step_number += 1 unless G.map.is_menu
        return ret

    G.serialize_fork = () ->
        serialization.exclude(G)
        serialization.push_state(G.map)
        G.fork_step_number = G.step_number
    G.serialize_revert = () ->
        serialization.exclude(G)
        serialization.pop_state(G.map)
        G.step_number = G.fork_step_number

    G.handle_io = () ->
        if user_io.key_down "K_Q"
            serialization.push_state(G.map)
            G.fork_step_number = G.step_number

        if user_io.key_down "K_E"
            serialization.pop_state(G.map)

        G.map.handle_io() unless G.map == nil

    G.pre_draw = () -> G.map_view.pre_draw() unless G.map_view == nil

        -- print "Pre-draw took ", (MOAISim.getDeviceTime() - before) * 1000, 'ms'

    return G

return {:create_game_state}
