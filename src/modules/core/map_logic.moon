
import camera, util_movement, util_geometry, game_actions from require "core"
import Display from require 'ui'
import StatUtils from require "stats.stats"
import StatContext from require "stats"
import default_cooldown_table, reset_rest_cooldown from require "stats.stats.CooldownTypes"

import ObjectBase, CombatObjectBase, Player, NPC, Projectile from require '@map_object_types'
import player_step, player_handle_io, player_handle_action from require "@map_logic_player"
import npc_step_all from require "@map_logic_npc"

resources = require 'resources'
modules = require 'core.data'
user_io = require 'user_io'

step_objects = (M) ->
    -- Step all stat contexts
    for obj in *M.combat_object_list
        StatUtils.stat_context_on_step(obj.stat_context)
        StatContext.on_calculate(obj.stat_context)

    for obj in *M.animation_list
        obj\step(M)

    for obj in *M.projectile_list
        obj\step(M)

    -- Set up directions of all players
    -- Handle IO for all players
    -- Handle actions for all players
    for obj in *M.player_list
        player_step(obj, M)

    npc_step_all(M)

    -- Remove any objects queued for removal
    for obj in *M.removal_list
        obj\remove(M)
    table.clear(M.removal_list)
    -- Sync up any data that requires copying after position changes
    for obj in *M.object_list
        obj\sync(M)

step = (M) ->
    -- Set the current map as a global variable:
    _G._MAP = M

    step_objects(M)

    -- Step the subsystems
    M.collision_world\step()
    M.rvo_world\step()
    if #M.player_list == 0
        return "death"

-- IO Handling

handle_io = (M) ->
    if (user_io.key_pressed "K_ESCAPE")
        os.exit()
    for player in *M.player_list
        if M.gamestate.is_local_player(player)
            player_handle_io(player, M)

start = (V) -> nil
    -- for inst in *V.map.object_list
    --     inst\register_prop(V)

_text_style = with MOAITextStyle.new()
    \setColor 1,1,1 -- Yellow
    \setFont (resources.get_font 'Gudea-Regular.ttf')
    \setSize 14

UI_PRIORITY = 200

_draw_text = (V, text, obj, dx, dy) ->
    with Display.put_text_center V.object_layer, _text_style, text, obj.x + dx, obj.y + dy
        \setPriority UI_PRIORITY
        \setColor 1,1,1,0.2

-- Takes view object
pre_draw = (V) ->
    Display.reset_draw_cache()

    for obj in *V.map.player_list
        _draw_text(V, V.gamestate.player_name(obj), obj, 0, -25)

    -- print MOAISim.getPerformance()
    if _SETTINGS.headless then return

    for obj in *V.map.object_list
        seen = false
        for p in *V.map.player_list
            if p\can_see(obj)
                seen = true
                break
        if seen
            obj\pre_draw(V)

    -- Update in-focus object
    pobj = V.map.local_player()
    if pobj ~= nil -- Do we have a local player?
        if camera.camera_is_off_center(V, pobj.x, pobj.y)
            camera.sharp_center_on(V, pobj.x, pobj.y)
        else
            camera.center_on(V, pobj.x, pobj.y)

    -- Update the sight map

    x1,y1,x2,y2 = camera.tile_region_covered(V)
    for y=y1,y2 do for x=x1,x2
        tile = 2
        for inst in *V.map.player_list
            seen = inst.vision.seen_tile_map
            fov = inst.vision.fieldofview
            if seen\get(x,y) then tile = 1
        V.fov_grid\setTile(x, y, tile)

    for inst in *V.map.player_list
       {x1,y1,x2,y2} = inst.vision.current_seen_bounds
       fov = inst.vision.fieldofview
       for y=y1,y2-1 do for x=x1,x2-1
            if fov\within_fov(x,y)
                V.fov_grid\setTile(x, y, 0) -- Currently seen

    for component in *V.ui_components
        -- Step the component
        component()

draw = (V) ->
    for obj in *V.map.object_list
        seen = false
        for p in *V.map.player_list
            if util_geometry.object_distance(obj, p) < 300 and p\can_see(obj)
                seen = true
                break
        if seen
            obj\draw(V)

return {:step, :handle_io, :start, :pre_draw, :draw}
