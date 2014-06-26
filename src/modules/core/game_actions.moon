
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

    .equals = (O) =>
        if @id_player ~= O.id_player then return false
        if @action_type ~= O.action_type then return false
        if @step_number ~= O.step_number then return false
        if @genericbyte1 ~= O.genericbyte1 then return false
        if @genericbyte2 ~= O.genericbyte2 then return false
        if @id_target ~= O.id_target then return false
        if @x ~= O.x then return false
        if @y ~= O.y then return false
        return true

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
        return @array[i - @offset]

    .set = (i, val) =>
        if i < @first()
            -- Ignore 
            return false
        @ensure_index(i)
        @array[i - @offset] = val
        return true

    .drop_until = (drop_i) =>
        old_last = @last()
        if drop_i < @offset
            return
        _drop = (drop_i - @offset)
        A=@array
        for i=_drop+1,#A
            A[i - _drop] = A[i]
        for i=(#A - _drop+1),#A
            A[i] = nil
        @offset = drop_i
        assert(@first() == drop_i + 1, "First != drop_i + 1")
        assert(@last() == old_last or #@array == 0, "Last != old_last")

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
    .is_complete = (step_number) =>
        for action in *@actions
            if not action
                return false
            assert(step_number == nil or (action.step_number == step_number))
        return true
    ._step_number = () =>
        for action in *@actions
            if action
                return action.step_number
        

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
        best = @frames.offset
        for i=@frames\first(),@frames\last()
            if @frames\get(i)\is_complete(i)
                best = i
            else
                return best
        return best

    .add = (action) =>
        if action.step_number < @first()
            return false
        frame = @get_frame(action.step_number) 
        previous_action = frame\get(action.id_player)
        if previous_action
            if previous_action.step_number ~= action.step_number
                pretty_print(@frames)
                error "Previous action not appropriate!"
            if not previous_action\equals(action)
                error("A conflicting action was sent! Confused and bailing out, previously:\n #{pretty_tostring(previous_action)}\n vs new:\n #{pretty_tostring(action)}.")
            return false
        frame\set(action.id_player, action)
        return true

    .first = () => @frames\first()
    .last = () => @frames\last()

    .drop_until = (step_number) =>
        -- print "-- BEFORE --"
        -- print "Offset", @frames.offset
        -- for i=@frames\first(),@frames\last()
        --     print "Step #{i}:", @frames\get(i)\_step_number()
        -- print "-------------"
        @frames\drop_until(step_number)
        -- for i=@frames\first(),@frames\last()
        --     @frames\get(i)\is_complete(i)
        -- print "-- AFTER --"
        -- print "Offset", @frames.offset
        -- for i=@frames\first(),@frames\last()
        --     print "Step #{i}:", @frames\get(i)\_step_number()
        -- print "-------------"

    -- Get by step number, and optionally also player ID
    .get_frame = (step_number) =>
        if step_number < @queue_start
            return -- Now possible, below are lies. But, can be safely ignored.
            -- error("Steps for before #{queue_start} (#{step_number}) not possible, already cleared!")
        @frames\ensure_index(step_number)
        frame = @frames\get(step_number)
        if not frame
            frame = GameActionFrame.create(@num_players)
            @frames\set(step_number, frame)
        return frame

setup_action_state = (G) ->
    G.player_actions = GameActionFrameSet.create(#G.players)

    G.queue_action = (action) ->
        return G.player_actions\add(action)

    G.drop_old_actions = (step_number) ->
        G.player_actions\drop_until(step_number)

    -- Returns 'false' if no action yet queued (should never be the case for local player!)
    G.get_action = (id_player, step_number = G.step_number) ->
        frame = G.player_actions\get_frame(step_number)
        return frame\get(id_player)

    -- Find the next action, even in the future
    -- debug only
    G.seek_action = (id_player) ->
        A = G.player_actions
        best = nil
        for i=A\first(),A\last()
            frame = A\get_frame(i)
            action = frame\get(id_player)
            if not action return best
            else best = action
        return best
    -- Find next action, starting from the end
    -- debug only
    G.bseek_action = (id_player) ->
        A = G.player_actions
        for i=A\last(),A\first(),-1
            frame = A\get_frame(i)
            action = frame\get(id_player)
            if action return action

    G.have_all_actions_for_step = () ->
        return G.player_actions\get_frame(G.step_number)\is_complete(G.step_number)

return {
    :GameAction, :GameActionFrame, :GameActionFrameSet, 
    :setup_action_state, :make_move_action, :make_none_action, :unbox_move_action,
    :ACTION_NONE, :ACTION_MOVE
}
