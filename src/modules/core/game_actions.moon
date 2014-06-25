
-------------------------------------------------------------------------------
-- Stores all the types of actions that can be done in a uniform structure.
-- This must be predictable and smallish, because it is sent often in packets.
-------------------------------------------------------------------------------

-- Action type enumeration
ACTION_NONE, ACTION_MOVE = unpack [i for i=1,2]

GameAction = with newtype()
    -- Use with either .create(buffer)
    -- or .create(id, type, target, x, y)
    .init = (id_player_or_buffer, action_type, gb1, gb2, step_number, id_target, x, y) =>
        if type(id_player_or_buffer) ~= 'number'
            -- Not the ID, read from 
            @read(id_player_or_buffer)
            return

        -- The player sending the action, 8bit integer
        @id_player = id_player_or_buffer
        -- 8bit integer
        @action_type = action_type
        @step_number = step_number
        -- 2 one-byte numbers for general purpose
        @genericbyte1,@genericbyte2 = gb1,gb2
        -- 32bit integer (semi-general purpose)
        @id_target = id_target
        -- Two 64bit floats (semi-general purpose)
        @x, @y = x, y

    .read = (buffer) =>
        -- For use with DataBuffer
        @id_player = buffer\read_byte()
        @action_type = buffer\read_byte()
        @step_number = buffer\read_int()
        @genericbyte1 = buffer\read_byte()
        @genericbyte2 = buffer\read_byte()
        @id_target = buffer\read_int()
        @x = buffer\read_double()
        @y = buffer\read_double()

    .write = (buffer) => with buffer
        -- For use with DataBuffer
        \write_byte @id_player
        \write_byte @action_type
        \write_int @step_number
        \write_byte @genericbyte1
        \write_byte @genericbyte2
        \write_int @id_target
        \write_double @x
        \write_double @y


-------------------------------------------------------------------------------
-- Helpers for representing various actions
-------------------------------------------------------------------------------

make_none_action = (pobj, step_number) ->
    return GameAction.create pobj.id_player, ACTION_NONE,
        0,0, step_number, 0, pobj.x, pobj.y

make_move_action = (pobj, step_number, dirx, diry) -> 
    -- Add 3 to directions to force them into the 0-255 range
    return GameAction.create pobj.id_player, ACTION_MOVE, 
        dirx + 3, diry + 3, step_number, 0, pobj.x, pobj.y

unbox_move_action = (action) ->
    assert(action.action_type == ACTION_MOVE)
    {:id_player, :step_number, :genericbyte1, :genericbyte2} = action
    -- Subtract 3 to recreate the directions from make_move_action
    return id_player, step_number, genericbyte1 - 3, genericbyte2 - 3

-------------------------------------------------------------------------------
-- Implementation of GameActionFrameSet and related helpers that form a buffer
-- of recent game actions sent from the network -- or, from local player
-- interaction.
-------------------------------------------------------------------------------

_EMPTY_LIST = {} -- Slight optimization

_ArrayWithOffset = with newtype()
    .init = () =>
        @array = {}
        @offset = 0
    .first = () => (1 + @offset)
    .last  = () => (#@array + @offset)
    .ensure_index = (i) =>
        while @last() < i
            -- Fill unused slots with 'false'
            append @array, false

    .get = (i) =>
        assert(i >= @first() and i <= @last())
        return @array[i - @offset]

    .set = (i, val) =>
        @ensure_index(i)
        @array[i - @offset] = val

    .drop_until = (drop_i) =>
        old_last = @last()
        drop_n = (drop_i - @offset)
        for i = @last(), @first(), -1
            @set(i - drop_n + 1, @get(i))
            @set(i, nil)
        @offset += drop_n
        assert(@first() == drop_i + 1)
        assert(@last() == old_last)

-- One frame of game actions
GameActionFrame = with newtype()
    .init = (num_players) =>
        @actions = [false for i=1,num_players]
    .get = (id_player) =>
        assert(id_player >= 1 and id_player <= #@actions)
        return @actions[id_player]
    .set = (id_player, action) =>
        assert(id_player >= 1 and id_player <= #@actions)
        @actions[id_player] = action
    .is_complete = () =>
        for action in *@actions
            if not action
                return false
        return true

-- The set of game actions that have been received
GameActionFrameSet = with newtype()
    .init = (num_players) =>
        assert(num_players > 0, "Cannot start a game with 0 players!")
        log("Creating", num_players, "players")
        -- List of lists, indexed first by step number, then player id, produces a GameAction (or false)
        @frames = _ArrayWithOffset.create() -- Action list
        @num_players = num_players
        @queue_start = 1 -- Where do actions start from?

    -- Note, to qualify, every frame BEFORE it must be complete
    .find_latest_complete_frame = () =>
        best = nil
        for frame in *@frames
            if frame\is_complete()
                best = frame
            else
                return best
        return best

    .add = (action) =>
        frame = @get_frame(action.step_number) 
        frame\set(action.id_player, action)

    .drop_until = (step_number) =>
        @frames\drop_until(step_number)

    -- Get by step number, and optionally also player ID
    .get_frame = (step_number) =>
        if step_number < @queue_start
            error("Steps for before #{queue_start} (#{step_number}) not possible, already cleared!")
        @frames\ensure_index(step_number)
        frame = @frames\get(step_number)
        if not frame
            frame = GameActionFrame.create(@num_players)
            @frames\set(step_number, frame)
        return frame

_ensure_player_actions = (G) ->
    G.player_actions = G.player_actions or GameActionFrameSet.create(#G.players)

setup_action_state = (G) ->
    G.player_actions = nil

    G.queue_action = (action) ->
        log('Queuing action for step:', action.step_number, 'player:', action.id_player)
        _ensure_player_actions(G)
        G.player_actions\add(action)

    G.drop_old_actions = () ->
        _ensure_player_actions(G)
        G.player_actions\drop_until(G.step_number)

    -- Returns 'false' if no action yet queued (should never be the case for local player!)
    G.get_action = (id_player) ->
        _ensure_player_actions(G)
        frame = G.player_actions\get_frame(G.step_number)
        return frame\get(id_player)

    G.have_all_actions_for_step = () ->
        _ensure_player_actions(G)
        return G.player_actions\get_frame(G.step_number)\is_complete()

return {
    :GameAction, :GameActionFrame, :GameActionFrameSet, 
    :setup_action_state, :make_move_action, :make_none_action, :unbox_move_action,
    :ACTION_NONE, :ACTION_MOVE
}