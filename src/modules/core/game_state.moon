import create_thread from require 'core.util'
import serialization from require 'core'
user_io = require 'user_io'

-------------------------------------------------------------------------------
-- The main stepping 'thread' (coroutine)
-------------------------------------------------------------------------------

main_thread = (G) -> create_thread () ->
    while true
        coroutine.yield()

        is_menu = not G.level_view.is_menu
        before = MOAISim.getDeviceTime()
        G.handle_io()
        G.step()
        G.pre_draw()
        if not is_menu
            G.drop_old_actions()
            G.step_number += 1

create_game_state = () ->
    G = {}

    G.step_number = 1
    G.gametype = _SETTINGS.gametype

    require("@player_state").setup_player_state(G)

    -- Set up player actions, and associated helpers
    require("@game_actions").setup_action_state(G)

    require('@network_logic').setup_network_state(G)

    -- Based on game type above, and _SETTINGS object for IP (for client) & port (for both client & server)
    G.start_connection()

    G.change_view = (V) ->
        if G.level_view then
            G.level_view\stop()
        G.level_view = V
        G.level = V.level
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
        if G.connection 
            G.poll()
            while not G.have_all_actions_for_step()
                G.poll(1)

        G.level.step() unless G.level == nil
        G.level_view.pre_draw() unless G.level_view == nil

    G.handle_io = () ->
        if user_io.key_down "K_Q"
            serialization.push_state(G.level)

        if user_io.key_down "K_E"
            serialization.pop_state(G.level)

        G.level.handle_io() unless G.level == nil

    G.pre_draw = () -> G.level_view.pre_draw() unless G.level_view == nil

        -- print "Pre-draw took ", (MOAISim.getDeviceTime() - before) * 1000, 'ms'

    return G

return {:create_game_state}