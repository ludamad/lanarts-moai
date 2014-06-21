
BoolGrid = require 'BoolGrid'
user_io = require 'user_io'
import modules, camera, moveutil, geometryutil from require 'game'
import FieldOfView, FloodFillPaths from require "core"

Vision = with newtype()
    .init = (L, line_of_sight) =>
        @line_of_sight = line_of_sight
        @seen_tile_map = BoolGrid.create(L.tilemap_width, L.tilemap_height, false)
        @fieldofview = FieldOfView.create(L.tilemap, @line_of_sight)
        @prev_seen_bounds = {0,0,0,0}
        @current_seen_bounds = {0,0,0,0}
    .update = (x, y) =>
        @fieldofview\calculate(x, y)
        @fieldofview\update_seen_map(@seen_tile_map)
        @prev_seen_bounds = @current_seen_bounds
        @current_seen_bounds = @fieldofview\tiles_covered()

-- Used with _advance_if_can
_biased_round = (num) -> if num < 0 then math.floor(num) else math.ceil(num)

Player = with newtype {parent: CombatObject}
	.init = (args) =>
		CombatObject.init(@, args)
        @vision = 7
        @player_path_radius = 300
    .register = (L) =>
        CombatObject.register(@, L)
        -- Seen tile map, defaulted to false
        @vision = Vision.create(L, @vision)
        @paths_to_player = FloodFillPaths.create(L.tilemap)
        L.players\add(@)
    .unregister = (L) =>
        L.players\remove(@)

	-- Missing piece for 'register'
	._create_prop = (L) => 
		quad = modules.get_sprite("player")\create_quad()
		return with MOAIProp2D.new()
            \setDeck(quad)
            \setLoc(@x, @y)
    .state_sync = (L) => 
        CombatObject.state_sync(@, L)
        @vision\update(@x/L.tile_width, @y/L.tile_height)
        @paths_to_player\update(@x, @y, @player_path_radius)

    ._action_move = (L, dirx, diry, dist) =>
        -- Decide on the path the maximizes distance:
        -- Multiply by '0.72' -- adjustment for directional movement
        total_dx, total_dy, distance = 0,0,0
        correction = if dirx ~= 0 and diry ~= 0 then 0.75 else 1.0
        for dir_pref=0,1
            altdx, altdy, altdist = moveutil.look_ahead(@, L, dir_pref, dirx * correction, diry * correction)
            if altdist > distance
                total_dx, total_dy, distance = altdx, altdy, altdist
        if dirx ~= 0 and diry ~= 0 and distance ~= @speed
            for dir_pref=0,1
                altdx, altdy, altdist = moveutil.look_ahead(@, L, dir_pref, 0, diry)
                if altdist > distance
                    total_dx, total_dy, distance = altdx, altdy, altdist

        -- Finally, take that path:
        @x += total_dx
        @y += total_dy

    .handle_io = (L) =>
        dx,dy=0,0
        if (user_io.key_down "K_UP") or (user_io.key_down "K_W") 
            dy = -1
        elseif (user_io.key_down "K_DOWN") or (user_io.key_down "K_S") 
            dy = 1
        if (user_io.key_down "K_RIGHT") or (user_io.key_down "K_D") 
            dx = 1
        elseif (user_io.key_down "K_LEFT") or (user_io.key_down "K_A") 
            dx = -1
        @_action_move(L, dx, dy, @speed)

    .pre_draw = (V) =>
        CombatObject.pre_draw(@, V)
        if @is_focus
            if camera.camera_is_off_center(V, @x, @y)
                camera.sharp_center_on(V, @x, @y)
            else
                camera.center_on(V, @x, @y)

    .update_prop = (V) =>
        CombatObject.update_prop(@, V)

setup_player_state = (L) ->
    L.players = ObjectGroup.create()

return {:Player, :setup_player_state}