import create_thread from require 'core.util'
import serialization from require 'core'
import ClientMessageHandler, ServerMessageHandler from require 'core.net_message_handler'
user_io = require 'user_io'

-------------------------------------------------------------------------------
-- The main stepping 'thread' (coroutine)
-------------------------------------------------------------------------------

main_thread = (G) -> create_thread () ->
    while true
        coroutine.yield()

        G.handle_io()
        is_menu = G.level_view.is_menu
        if G.net_handler
            G.net_handler\poll()
            if not is_menu and not G.have_all_actions_for_step()
                -- Give it some time
                G.net_handler\poll(35)

        do_step = is_menu or G.have_all_actions_for_step()

        if do_step
            G.step()

        G.pre_draw()
        -- If we did the step, are we aren't in a menu, step the frame count
        if not is_menu and do_step
            G.drop_old_actions()
            G.step_number += 1

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

    -- Set up player actions, and associated helpers
    require("@game_actions").setup_action_state(G)

    setup_network_state(G)

    -- Based on game type above, and _SETTINGS object for IP (for client) & port (for both client & server)
    if G.net_handler
        G.net_handler\connect()

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
        G.level.step() unless G.level == nil

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