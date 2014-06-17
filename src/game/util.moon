import ErrorReporting from require 'system'

-- Create a simple 'thread' object that runs a custom
-- function.
create_thread = (func) ->
    thread = MOAIThread.new()
    return {
        start: ErrorReporting.wrap () -> thread\run(func)
        stop: () -> thread\stop()
    }

return {:create_thread}