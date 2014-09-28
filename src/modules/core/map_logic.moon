
import util_movement, util_geometry, game_actions from require "core"
import Display from require 'ui'
import REST_COOLDOWN from require "statsystem"
import ErrorReporting from require "system"

import ObjectBase, CombatObjectBase, Player, NPC, Feature, Projectile from require '@map_object_types'
import player_step, player_handle_io, player_handle_action from require "@map_logic_player"
import npc_step_all from require "@map_logic_npc"

resources = require 'resources'
modules = require 'core.data'
user_io = require 'user_io'

assertSync = (msg, M) ->
    if logS == do_nothing then return
    if M.gamestate.doing_client_side_prediction then return
    payload = {}
    to_ids = (l) -> [o.id for o in *l]
    for k in *{
        "combat_object_list", "npc_list", "player_list",
        "projectile_list", "animation_list", "item_list", "feature_list"
    } 
        payload[k] = to_ids(M[k])
    payload.objects = {}
    obj_subset = {"x", "y", "radius", "priority", "id_col", "frame", "remove_queued"}
    for obj in *M.object_list
        append payload.objects, {k, obj[k] for k in *obj_subset}
    logS(msg, payload)

step_objects = (M) ->
    assertSync "step_objects (frame #{M.gamestate.step_number})", M
    --Step all stat contexts
    for obj in *M.combat_object_list
        obj.stats\calculate()
        obj.stats\step()

    for obj in *M.combat_object_list
        obj\check_delayed_action(M)

    for obj in *M.animation_list
        obj\step(M)

    for obj in *M.projectile_list
        obj\step(M)

    -- Set up directions of all players
    -- Handle IO for all players
    -- Handle actions for all players
    for obj in *M.player_list
        player_step(M, obj)

    npc_step_all(M)

    for obj in *M.combat_object_list
        -- Set the priority, for the draw event
        obj\set_priority()
        -- Process dead objects
        if obj.stats.raw_hp <= 0
            obj\on_death(M)

    -- Remove any objects queued for removal
    for obj in *M.removal_list
        obj\remove(M)
    table.clear(M.removal_list)
    -- Sync up any data that requires copying after position changes
    for obj in *M.object_list
        obj\sync(M)

step = (M) ->
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
            player_handle_io(M, player)

start = (V) -> nil
    -- for inst in *V.map.object_list
    --     inst\register_prop(V)

_text_style = with MOAITextStyle.new()
    \setColor 1,1,1 -- Yellow
    \setFont (resources.get_font 'Gudea-Regular.ttf')
    \setSize 14

UI_PRIORITY = 200

_draw_text = (V, text, obj, dx, dy) ->
    with Display.put_text_center Display.game_obj_layer, _text_style, text, obj.x + dx, obj.y + dy
        \setPriority UI_PRIORITY
        \setColor 1,1,0.5,0.4

-- Takes view object
pre_draw = (V) ->
    Display.reset_draw_cache()

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
    if pobj ~= nil and not user_io.mouse_right_down() -- Do we have a local player?
        if Display.camera_is_off_center(pobj.x, pobj.y)
            Display.camera_sharp_center_on(pobj.x, pobj.y)
        else
            Display.camera_center_on(pobj.x, pobj.y)

    -- Update the sight map

    x1,y1,x2,y2 = Display.camera_tile_region_covered()
    for y=y1,y2 do for x=x1,x2
        tile = 2
        for inst in *V.map.player_list
            seen = V.map.player_seen_map(inst.id_player)
            fov = inst.vision.fieldofview
            if seen\get(x,y) then tile = 1
        V.fov_grid\setTile(x, y, tile)

    for inst in *V.map.player_list
       fov, bounds = inst.vision\get_fov_and_bounds(V.map)
       {x1,y1,x2,y2} = bounds
       for y=y1,y2-1 do for x=x1,x2-1
            if fov\within_fov(x,y)
                V.fov_grid\setTile(x, y, 0) -- Currently seen

    for component in *V.ui_components
        -- Step the component
        component()


should_draw_object = (V, obj) ->
    in_sight = false
    for p in *V.map.player_list
        if util_geometry.object_distance(obj, p) < 300 and p\can_see(obj)
            in_sight = true
            break
    -- Special logic for features, draw them as the last thing we saw them:
    if getmetatable(obj) == Feature
        if in_sight
            obj\mark_seen()
        return obj\was_seen()
    -- For other objects, only draw them when they are in sight:
    return in_sight

PLAYER_NAME_FONT = resources.get_font 'Gudea-Regular.ttf'

OBJECT_LIST_CACHE = {}
priority_compare = (a, b) -> (a.priority > b.priority)
draw = ErrorReporting.wrap (V) ->
    table.clear(OBJECT_LIST_CACHE)
    for obj in *V.map.object_list
        append OBJECT_LIST_CACHE, obj
    table.sort(OBJECT_LIST_CACHE, priority_compare)

    for obj in *OBJECT_LIST_CACHE
        if should_draw_object(V, obj)
            obj\draw(V)
    -- Draw overlay information
    for obj in *V.map.player_list
        -- pinfo = V.gamestate.players[obj.id_player]
        -- color = {unpack(pinfo.color)}
        -- color[4] = 0.8
        Display.drawTextCenter(PLAYER_NAME_FONT, V.gamestate.player_name(obj), obj.x, obj.y-25, Display.COL_RED, 14)

return {:step, :handle_io, :start, :pre_draw, :draw, :assertSync}
