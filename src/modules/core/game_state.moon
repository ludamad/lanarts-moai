import create_thread from require 'core.util'
import serialization from require 'core'
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

FORK_ADVANCE = 1000
PREDICT_STEPS = 250
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
            G.step()
        -- Create a new fork
        G.serialize_fork()
        -- Move our state to our previous (potentially incomplete) position
        while previous_step > G.step_number
            -- Step with only client-side information
            G.step()

    -- Check that we are as advanced as we before (and not further)
    assert(previous_step == G.step_number, "Incorporated new information incorrectly!")
    if G.step_number <= G.fork_step_number + PREDICT_STEPS
        G.step()

main_thread = (G) -> create_thread () -> profile () ->
    while true
        coroutine.yield()

        G.handle_io()
        is_menu = G.level_view.is_menu
        if G.net_handler
            G.net_handler\poll()
            -- while not is_menu and G.step_number > G.player_actions\find_latest_complete_frame()
            --     G.net_handler\poll(1)

        if is_menu 
            G.step()
        elseif not G.net_handler
            G.step()
            G.drop_old_actions(G.step_number)
        else
            before = MOAISim\getDeviceTime()

            _net_step(G)

            after = MOAISim\getDeviceTime()
            -- print "'STEP' took #{(after - before)*1000} milliseconds!"

            G.drop_old_actions(G.fork_step_number - 1)

        G.pre_draw()

setup_network_state = (G) ->
    if G.gametype == 'client'
        G.net_handler = ClientMessageHandler.create G, {ip: _SETTINGS.server_ip, port: _SETTINGS.server_port}
    elseif G.gametype == 'server'
        G.net_handler = ServerMessageHandler.create G, {port: _SETTINGS.server_port}

create_game_state = () ->
    G = {}

    G.step_number = 1
    G.gametype = _SETTINGS.gametype

    require("@player_state").setup_player_state(G)

    setup_network_state(G)

    -- Based on game type above, and _SETTINGS object for IP (for client) & port (for both client & server)
    if G.net_handler
        G.net_handler\connect()

    G.change_view = (V) ->
        if G.level_view then
            G.level_view\stop()
        G.level_view = V
        G.level = V.level
        if not V.is_menu
            -- Set up player actions, and associated helpers
            require("@game_actions").setup_action_state(G)

            G.serialize_fork()
        G.level_view.start()

    -- Setup function
    G.start = () -> 
        G.level_view.start() unless G.level_view == nil

        thread = main_thread(G)
        thread.start()
        return thread

    -- Tear-down function
    G.stop = () -> 
        G.level_view.stop() unless G.level_view == nil
        for thread in *G.threads
            thread.stop()

    -- Game step function
    G.step = () -> 
        G.level.step() unless G.level == nil
        G.step_number += 1 unless G.level.is_menu

    G.serialize_fork = () ->
        serialization.exclude(G)
        serialization.push_state(G.level)
        G.fork_step_number = G.step_number
    G.serialize_revert = () ->
        serialization.exclude(G)
        serialization.pop_state(G.level)
        G.step_number = G.fork_step_number

    G.handle_io = () ->
        if user_io.key_down "K_Q"
            serialization.push_state(G.level)
            G.fork_step_number = G.step_number

        if user_io.key_down "K_E"
            serialization.pop_state(G.level)

        G.level.handle_io() unless G.level == nil

    G.pre_draw = () -> G.level_view.pre_draw() unless G.level_view == nil

        -- print "Pre-draw took ", (MOAISim.getDeviceTime() - before) * 1000, 'ms'

    return G

return {:create_game_state}