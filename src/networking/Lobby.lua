local HttpRequest = require "networking.HttpRequest"

--- Lobby HTTP requests. They are all nonblocking. Instead, they call yield.
-- Valid only within coroutines.

local M = {} --submodule

function M.create_user(username, password)
    return HttpRequest.json_request(_SETTINGS.lobby_server_url, {
        type = "CreateUserMessage", 
        username = username, 
        password = password 
    })
end

function M.login(username, password)
    return HttpRequest.json_request(_SETTINGS.lobby_server_url, {
        type = "LoginMessage", 
        username = username, 
        password = password 
    })
end

function M.guest_login(username)
    return HttpRequest.json_request(_SETTINGS.lobby_server_url, {
        type = "GuestLoginMessage", 
        username = username
    })
end

function M.chat_message(username, sessionId, message)
    return HttpRequest.json_request(_SETTINGS.lobby_server_url, {
        type = "ChatMessage", 
        username = username,
        sessionId = sessionId,
        message = message
    })
end

function M.create_game(username, sessionId)
    return HttpRequest.json_request(_SETTINGS.lobby_server_url, {
        type = "CreateGameMessage", 
        username = username,
        sessionId = sessionId,
    })
end

function M.join_game(username, sessionId, gameId)
    return HttpRequest.json_request(_SETTINGS.lobby_server_url, {
        type = "JoinGameMessage", 
        username = username,
        sessionId = sessionId,
        gameId = gameId
    })
end

function M.query_game(gameId)
    return HttpRequest.json_request(_SETTINGS.lobby_server_url, {
        type = "GameStatusRequestMessage", 
        gameId = gameId
    })
end

function M.query_game_list()
    return HttpRequest.json_request(_SETTINGS.lobby_server_url, {
        type = "GameListRequestMessage" 
    })
end

return M
