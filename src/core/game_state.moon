import thread_create from require 'core.util'
import serialization from require 'core'
import mtwist from require ''
import ErrorReporting from require 'system'
import Display from require "ui"
import ClientMessageHandler, ServerMessageHandler from require 'core.net_message_handler'
user_io = require 'user_io'

_G.perf_time = (name, f) -> 
    before = MOAISim\getDeviceTime()
    f()
    after = MOAISim\getDeviceTime()
    print "'#{name}' took #{after - before} seconds!"

PLAYER_COLORS = {
    Display.COL_PALE_RED
    Display.COL_PALE_GREEN
    Display.COL_MAGENTA
    Display.COL_CYAN
    Display.COL_MEDIUM_PURPLE
}

GameState = newtype {
    init: () =>
        @maps = {}
        @step_number = 1
        @fork_step_number = 1
        @gametype = _SETTINGS.gametype
        @local_death = false
        @game_id = 0
        @actions = false -- : GameActionSet
        @map = false -- : Map
        @map_view = false -- : MapView

        @_init_player_state()
        @_init_network_state()

    -- Network functions -- 
    _init_network_state: () =>
        @doing_client_side_prediction = false
        if @gametype == 'client'
            @net_handler = ClientMessageHandler.create @, {ip: _SETTINGS.server_ip, port: _SETTINGS.server_port}
        elseif @gametype == 'server'
            @net_handler = ServerMessageHandler.create @, {port: _SETTINGS.server_port}
        else
            @net_handler = false

        -- Based on game type above, and _SETTINGS object for IP (for client) & port (for both client & server)
        if @net_handler
            @net_handler\connect()


    -- Player functions -- 
    _init_player_state: () =>
        @next_player_id = 1
        @players = {}
        @local_player_id = false

    add_new_player: (name, is_controlled, peer=nil) =>
        assert(@gametype ~= 'client', "Should not be called by a client!")
        for p in *@players do assert(p.peer ~= peer, "Attempting to assign two player IDs to the same peer (or server)!")
        -- Peer is remembered for servers
        append @players, {id_player: @next_player_id, player_name: name, :is_controlled, :peer, color: PLAYER_COLORS[@next_player_id % #PLAYER_COLORS + 1]}
        if is_controlled
            assert(not @local_player_id)
            @local_player_id = @next_player_id
        @next_player_id += 1

    -- Generally only used by the server:
    peer_player_id: (peer) =>
        for player in *@players
            if player.peer == peer
                return player.id_player
        return nil

    local_player: () => 
        for L in *@maps do for player in *L.player_list
            if @is_local_player(player)
                return player

    is_local_player: (obj) =>
        return obj.id_player == @local_player_id

    player_name: (obj) =>
        player = @players[obj.id_player]
        return player.player_name

    initialize_actions: () =>
        @actions = require("@game_actions").GameActionSet.create(#@players, @game_id)

    initialize_rng: (seed) =>
        logI("initialize_rng: Seed is", seed)
        @rng = mtwist.create(seed)

    clear_game_data: () =>
        @step_number = 1
        @local_death = false
        if @net_handler 
            @net_handler\reset_frame_count()
        @game_id = (@game_id + 1) % 256
        -- Make sure GameActionSet updates as well:
        @actions.game_id = @game_id
        for map in *@maps
            -- Free resources allocated on the C/C++ side of the engine, as soon as possible.
            map\free_resources()
        table.clear @maps
        @actions\reset_action_state()

    change_view: (V) =>
        if @map_view
            @map_view\make_inactive()
        @map_view = V
        @map = V.map
        @serialize_fork()
        @map_view\make_active()

    -- Setup function
    start: (on_death) => @_main_thread(on_death)

    -- Tear-down function
    stop: () => 
        @map_view\make_inactive()
        for thread in *@threads
            thread.stop()

    -- Game step function
    step: () => 
        ret = @map.step()
        @step_number += 1 
        return ret

    serialize_fork: () =>
        serialization.exclude(@)
        serialization.push_state(@map)
        @fork_step_number = @step_number
    serialize_revert: () =>
        serialization.exclude(@)
        serialization.pop_state(@map)
        @step_number = @fork_step_number

    handle_io: () =>
        if user_io.key_down "K_Q"
            serialization.push_state(@map)
            @fork_step_number = @step_number

        if user_io.key_down "K_E"
            serialization.pop_state(@map)

        if @map then @map.handle_io() 

    pre_draw: () => 
        @map_view\pre_draw()
}

-- Step event and game thread logic, declared outside of the class for organization purposes:

-- Constants used in the simulation. TODO Organize

DISABLE = 1000 -- Arbitrarily large

FORK_ADVANCE = DISABLE
PREDICT_STEPS = if _SETTINGS.network_lockstep then 0 else 60
SLOWDOWN_STEPS = 50
CHECK_TIME = 0 / 1000 -- seconds

last_time = MOAISim\getDeviceTime()

-- The main stepping 'thread' (coroutine). Called by '@start' above.
GameState._main_thread = (on_death) => profile () ->
    last_full_send_time = MOAISim\getDeviceTime()
    last_part_send_time = MOAISim\getDeviceTime()
    while true
        coroutine.yield()

        -- Should we make a local player action from user input, for the current frame?
        if not _SETTINGS.network_lockstep or not @actions\get_action(@local_player_id, @step_number)
            @handle_io()
        if @net_handler and not _SETTINGS.network_lockstep
            @net_handler\poll(1)
            -- Client side prediction
            if MOAISim\getDeviceTime() > last_full_send_time + (100/1000)
                @net_handler\send_unacknowledged_actions()
                last_full_send_time = MOAISim\getDeviceTime()

            -- if MOAISim\getDeviceTime() > last_part_send_time + (25/1000)
            --     @net_handler\send_unacknowledged_actions(2) -- Only 2 frames back in time
            --     last_part_send_time = MOAISim\getDeviceTime()
            before = MOAISim\getDeviceTime()
            _net_step(G)
            after = MOAISim\getDeviceTime()
            logV "'_net_step' took #{(after - before)*1000} milliseconds!"

            last_needed = math.min(@fork_step_number, @net_handler\min_acknowledged_frame())
            @actions\drop_old_actions(last_needed - 1)
        elseif @net_handler
            while @step_number > @actions\find_latest_complete_frame()
                @net_handler\poll(1)
            -- Lock-step
            @doing_client_side_prediction = false
            @step()
            last_needed = math.min(@step_number, @net_handler\min_acknowledged_frame())
            @actions\drop_old_actions(last_needed - 1)
        else -- Single player
            @doing_client_side_prediction = false
            @step()
            @actions\drop_old_actions(@step_number - 1)
        @pre_draw()

        if @_check_quit_conditions()
            return

-- Used in main_thread to decide how to advance time, given potentially incomplete information.
-- This is the heart of the client-side-prediction algorithm.
-- TODO Once it works well, comment it a bunch
GameState._net_step = () =>
    previous_step = @step_number
    -- Manage time passage
    new_time = MOAISim\getDeviceTime() 
    time_passed = (new_time - last_time)

    -- Incorporate new information (if any) and replay actions
    last_best = @actions\find_latest_complete_frame()
    -- Ensure we don't step past the current step
    last_best = math.min(last_best, @step_number)
    -- Could we move our fork further along?
    if time_passed > CHECK_TIME and last_best >= @fork_step_number
        last_time = new_time
        next_fork_target = math.min(previous_step, @fork_step_number + FORK_ADVANCE)

        @serialize_revert()
        -- Move our state until the point where complete information is exhausted
        -- We should move one past from the point where we had information for forking
        while last_best >= @step_number and @step_number < next_fork_target
            -- Step with complete frame information
            @doing_client_side_prediction = false
            @step()
        -- Create a new fork
        @serialize_fork()
        -- Move our state to our previous (potentially incomplete) position
        while previous_step > @step_number
            -- Step with only client-side information
            @doing_client_side_prediction = true
            @step()

    -- Check that we are as advanced as we before (and not further)
    assert(previous_step == @step_number, "Incorporated new information incorrectly!")
    if @step_number > @fork_step_number + SLOWDOWN_STEPS
        MOAISim.setStep(1 / _SETTINGS.frames_per_second_csp / 2)
    else
        MOAISim.setStep(1 / _SETTINGS.frames_per_second)
    if @step_number <= @fork_step_number + PREDICT_STEPS
        @doing_client_side_prediction = true
        @step()

-- Used in main_thread
GameState._check_quit_conditions = () =>
    if @local_death
        return true
    -- Are we initiating a restart?
    if user_io.key_pressed "K_R"
        if @net_handler 
            new_seed = @rng\random(0, 2^31)
            @net_handler\send_message {type: "Restart", :new_seed}
            @net_handler\handshake "RestartAck"
            @initialize_rng(new_seed)
        return true
    if not @net_handler
        return false -- Rest are network triggered
    -- Did the other user(s) disconnect?
    if #@net_handler\get_disconnects() > 0 or @net_handler\check_message "ByeBye"
        os.exit() -- TODO: Fix

    -- Did we get a restart message?
    msg = @net_handler\check_message "Restart"
    if msg 
        @net_handler\handshake "RestartAck"
        @initialize_rng(msg.new_seed)
        return true
    return false

return {:GameState}
