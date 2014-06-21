-------------------------------------------------------------------------------
-- Object lookahead pseudo-methods 
-- (pseudo-method == method-like functions not attached to an object)
-------------------------------------------------------------------------------

-- 'px' and 'py' are the 'projection' displacements
-- Projections are collision checks to determine how best to skirt around walls we may eventually pass
_check_for_slide = (L, dx, dy, px, py, checkdx, checkdy) =>
    if (not L.solid_check @, checkdx + dx, checkdy + dy) and (not L.solid_check @, checkdx + px, checkdy + py) 
        return true
    return false

-- Expectation: checkdx & checkdy are dx & dy passed through _biased_round
-- Returns real dx, dy if step succeeded; nil if step failed.
_look_ahead_step  = (L, dist, dir_pref, dx, dy, currdx, currdy) =>
    -- Control 'p' -- the 'projection' factor
    -- Projections are collision checks to determine how best to skirt around walls we may eventually pass
    PROJECT_STEP = 8
    PROJECT_MAX = 32

    -- This logic is slightly 'duplicated', but there isn't an efficient
    -- way I could think of for handling different dimensions uniformly
    if not L.solid_check @, currdx + dx, currdy + dy
        return dx, dy
    if dx == 0
        p = PROJECT_MAX
        while p > 0
            if dir_pref == 0 and _check_for_slide(@, L, dy, 0, p*dy, p*dy, currdx, currdy)
                return dy, 0
            if dir_pref == 1 and _check_for_slide(@, L, -dy, 0, -p*dy, p*dy, currdx, currdy)
                return -dy, 0
            p -= PROJECT_STEP
    if dy == 0
        p = PROJECT_MAX
        while p > 0
            if dir_pref == 0 and _check_for_slide(@, L, 0, dx, p*dx, p*dx, currdx, currdy, p)
                return 0, dx
            if dir_pref == 1 and _check_for_slide(@, L, 0, -dx ,p*dx, -p*dx, currdx, currdy, p)
                return 0, -dx
            p -= PROJECT_STEP
    if dx ~= 0 
        dx = (if dx > 0 then dist else -dist)
        if not L.solid_check @, currdx + dx, currdy 
            return dx, 0
    if dy ~= 0
        dy = (if dy > 0 then dist else -dist)
        if not L.solid_check @, currdx, currdy + dy
            return 0, dy
    return nil

-- Returns total distance travelled, total dirx & diry
look_ahead = (L, dir_pref, dirx, diry) =>
    distance = 0
    speed_int = math.floor(@speed)
    speed_rest = @speed - speed_int
    total_dx, total_dy = 0,0
    for i=1,speed_int
        dx, dy = _look_ahead_step(@, L, 1, dir_pref, dirx, diry, total_dx, total_dy)
        if dx == nil -- Failed?
            return total_dx, total_dy, distance
        total_dx += dx
        total_dy += dy
        distance += 1

    -- Handle remainder (non-integral speed component):
    if speed_rest ~= 0
        dx, dy = _look_ahead_step(@, L, speed_rest, dir_pref, dirx * speed_rest, diry * speed_rest, total_dx, total_dy)
        if dx ~= nil -- Succeeded?
            total_dx += dx
            total_dy += dy
            distance = speed -- Make (very) sure they are comparable afterwards

    return total_dx, total_dy, distance

return {:look_ahead}