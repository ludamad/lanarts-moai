-- By default, tiles are 32x32

gen = require 'generate'

with tiledef file: 'floor.png', solid: false
    .define name: 'undefined', from: {1,1}, to: {2,1}
    .define name: 'grey', from: {3,1}, to: {11,1}

with tiledef file: 'wall.png', solid: true
    .define name: 'dungeon_wall', from: {1,1}, to: {32, 1}

with spritedef file: 'feat.png', size: {32,32}, tiled: true
    .define name: 'door_closed', from: {3, 2},
    .define name: 'door_open',   from: {10, 2}, 
    .define name: 'shop',        from: {11,6}, to: {21,6}

leveldef.define name: "start", generator: gen.generate_test_model