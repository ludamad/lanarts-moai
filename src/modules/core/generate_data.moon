modules = require "core.data"
T =  modules.get_tilelist_id

import random_square_spawn_object from require '@util_generate'
import map_object_types from require 'core'

spawn_mons = (mons) -> (M) ->
    for mon, n in pairs mons
        for i=1,n
            assert random_square_spawn_object M, (px, py) ->
                map_object_types.NPC.create M, {
                    x: px*32+16
                    y: py*32+16
                    type: mon
                    solid: true
                }
    require("@map_logic").assertSync "step_objects (frame #{M.gamestate.frame})", M

default_poly_delta_func = (rng) -> (map, poly) ->
    center_x, center_y = map.size[1]/2, map.size[2]/2
    local vfunc 
    type = rng\random(0, 2) -- Only first two for now
    if type == 0
        return () => math.sign_of(@x - center_x)*2, math.sign_of(@y - center_y)*2
    elseif type == 1
        return () => math.sign_of(center_x - @x)*2, math.sign_of(center_y - @y)*2
    else --Unused
        return () => 0,0

ring_poly_delta_func = (rng) -> (map, poly) ->
    angle = rng\randomf(0, 2*math.pi)
    {w,h} = map.size
    rx, ry = (w/2-5),(h/2-5)
    ring_n = rng\random(1,4)
    rx /= ring_n
    ry /= ring_n
    to_x, to_y = math.cos(angle)*rx + w/2, math.sin(angle)*ry + h/2
    return () => math.sign_of(to_x - @x)*10, math.sign_of(to_y - @y)*10

-- Populate our world with the major locations that will be included
world_generation = () ->
    W = {}

return {
    OUTSIDE: (rng) -> {
        map_label: "Plain Valley"
        size: {85, 85}--if rng\random(0,2) == 0 then {135, 85} else {85, 135} 
        number_polygons: rng\random(30,40)
        outer_points: 20
        floor1: T('grass1')
        floor2: T('grass2')
        wall1: T('tree')
        wall1_seethrough: true
        wall2: T('dungeon_wall')
        line_of_sight: 8
        rect_room_num_range: {4,10}
        rect_room_size_range: {10,15}
        n_statues: 10
        rvo_iterations: 150
        n_shops: rng\random(2,4)
        n_stairs_down: 3
        n_stairs_up: 0
        connect_line_width: () -> rng\random(2,6)
        polygon_delta_func: ring_poly_delta_func(rng)
        room_radius: () ->
            r = 2
            bound = rng\random(1,20)
            for j=1,rng\random(0,bound) do r += rng\randomf(0, 1)
            return r
        generate_objects: spawn_mons {["Giant Rat"]: 10, ["Cloud Elemental"]: 10}
    }
    SMALL: (rng) -> {
        map_label: "A Dungeon"
        size: {45, 45}
        number_polygons: rng\random(8,10)
        outer_points: 20
        floor1: T('grey_floor')
        floor2: T('reddish_grey_floor')
        wall1: T('dungeon_wall')
        wall2: T('crypt_wall')
        line_of_sight: 6
        rect_room_num_range: {4,9}
        rect_room_size_range: {3,8}
        n_statues: 3
        n_shops: 1
        rvo_iterations: 20
        n_stairs_down: 3
        n_stairs_up: 0
        polygon_delta_func: default_poly_delta_func(rng)
        connect_line_width: () -> 2 + (if rng\random(5) == 4 then 1 else 0)
        room_radius: () ->
            r = 2
            for j=1,rng\random(0,4) do r += rng\randomf(0, 1)
            return r
        generate_objects: spawn_mons {["Giant Rat"]: 15, ["Cloud Elemental"]: 5}
    }

    MEDIUM: (rng) -> {
        map_label: "A Dungeon"
        size: {80,80}
        number_polygons: rng\random(10,32)
        outer_points: 20
        floor1: T('grey_floor')
        floor2: T('reddish_grey_floor')
        wall1: T('dungeon_wall')
        wall2: T('crypt_wall')
        line_of_sight: 6
        rect_room_num_range: {5,10}
        rect_room_size_range: {3,20}
        n_statues: 10
        rvo_iterations: 20
        n_shops: 2
        n_stairs_down: 3
        n_stairs_up: 3
        polygon_delta_func: default_poly_delta_func(rng)
        connect_line_width: () -> 2 + (if rng\random(5) == 4 then 1 else 0)
        room_radius: () ->
            r = 2
            for j=1,rng\random(0,8) do r += rng\randomf(0, 1)
            return r
        generate_objects: spawn_mons {["Giant Rat"]: 20, ["Cloud Elemental"]: 20}
    }
}
