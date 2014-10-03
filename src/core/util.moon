import ErrorReporting from require 'system'

-- Create a simple 'thread' object that runs a custom
-- function.
thread_create = (func) ->
    thread = MOAIThread.new()
    return {
        start: () -> thread\run(ErrorReporting.wrap func)
        stop: () -> thread\stop()
    }

return {:thread_create}