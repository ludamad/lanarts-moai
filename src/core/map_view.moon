-------------------------------------------------------------------------------
-- Standard requires from Lanarts engine 
-------------------------------------------------------------------------------

BoolGrid, mtwist = require "BoolGrid", require "mtwist" 

import Display from require 'ui'

import FloodFillPaths, GameInstSet, GameTiles, GameView, util, TileMap, RVOWorld, game_actions,
    ui_minimap, menu_start from require "core"

-------------------------------------------------------------------------------
-- Other requires
-------------------------------------------------------------------------------

import ui_ingame_scroll from require "core.ui"
import ui_sidebar, map_logic from require "core"
import util_draw from require "core"

json = require 'json'
modules = require 'core.data'
user_io = require 'user_io'
res = require 'resources'
serialization = require 'core.serialization'

-------------------------------------------------------------------------------
-- Set up the major props for the map
-------------------------------------------------------------------------------
create_tile_props = (V) ->
    -- Map and tile dimensions
    w,h = V.map.tilemap_width, V.map.tilemap_height
    tw, th = V.map.tile_width, V.map.tile_height

    -- Prop lists, and grid map
    -- There :is one prop and grid for each tile texture used
    props, grids = {}, {}

    -- Get the appropriate grid for a tile ID
    _grid = (tileid) ->
        tilelist = modules.get_tilelist(tileid)
        file = tilelist.texfile

        if not grids[file] 
            grids[file] = with MOAIGrid.new()
                \setSize(w, h, tw, th)

            tex = res.get_texture(file)
            tex_w, tex_h = tex\getSize()
            -- Create the tile prop:
            append props, with MOAIProp2D.new()
                \setDeck with MOAITileDeck2D.new()
                    \setTexture(res.get_texture(file))
                    \setSize(tex_w / tw, tex_h / th)
                    \setUVQuad( -0.5, -0.5, 0.5, -0.5, 0.5, 0.5, -0.5, 0.5 )
                \setGrid(grids[file])
        return grids[file]

    -- Assign a tile to the appropriate grid
    _set_xy = (x, y, tileid) ->
        -- 0 represents an empty tile, for now
        if tileid == 0 then return
        -- Otherwise, locate the correct grid instance
        -- and set the tile grid position accordingly
        grid = _grid(tileid)
        tilelist = modules.get_tilelist(tileid)
        -- The tile number
        n = _RNG\random(1, #tilelist.tiles + 1)
        tile = tilelist.tiles[n]

        grid\setTile(x, y, tile.grid_id)

    for y=1,h do for x=1,w
        _set_xy(x, y, V.map.tilemap\get({x,y}).content)

    return props

create_fov_prop = (V) ->
    w,h = V.map.tilemap_width, V.map.tilemap_height
    tw, th = V.map.tile_width, V.map.tile_height
    tex = res.get_texture "fogofwar-dark.png"
    tex_w, tex_h = tex\getSize()
    fov_grid = with MOAIGrid.new()
        \setSize(w, h, tw, th)
    for y=1,h do for x=1,w 
        -- Set to unexplored (black)
        fov_grid\setTile(x,y, 2)
    prop = with MOAIProp2D.new()
        \setDeck with MOAITileDeck2D.new()
            \setTexture(tex)
            \setSize(tex_w / tw, tex_h / th)
        \setGrid(fov_grid)
    return prop, fov_grid

-------------------------------------------------------------------------------
-- Set up the camera & viewport
-------------------------------------------------------------------------------
setup_camera = (V) ->
    w,h = V.map.tilemap_width, V.map.tilemap_height
    tw, th = V.map.tile_width, V.map.tile_height

    cx, cy = w * tw / 2, h * th / 2
    V.camera = Display.game_camera
    V.viewport = with Display.game_viewport
        \setSize(V.cameraw - ui_sidebar.SIDEBAR_WIDTH, V.camerah)
        \setScale(V.cameraw - ui_sidebar.SIDEBAR_WIDTH, -V.camerah)
    -- TODO remove below?
    with Display.ui_viewport
        \setSize(V.cameraw, V.camerah)
        \setScale(V.cameraw, -V.camerah)

-------------------------------------------------------------------------------
-- The MapView class
-------------------------------------------------------------------------------

MapView = newtype {
    init: (map, cameraw, camerah) =>
        @gamestate = map.gamestate
        @map = map
        @cameraw, @camerah = cameraw, camerah
        @fov_prop, @fov_grid = create_fov_prop(@)
        @tile_props = create_tile_props(@)
        @sidebar = false
        @ui_components = false
        @script_prop = false
    make_active: () =>
        setup_camera(@)
        -- Add the field of view prop drawing object
        Display.game_fg_layer1\insertProp(@fov_prop)
        -- Add all the different textures to the background layer
        for p in *@tile_props do Display.game_bg_layer\insertProp(p)
        @sidebar = ui_sidebar.Sidebar.create(@)
        @ui_components = {(ui_ingame_scroll @) (-> @sidebar\predraw())}
        @script_prop = (require 'core.util_draw').setup_script_prop(Display.game_obj_layer, (() -> @draw()), @map.pix_width, @map.pix_height, 999999)
        map_logic.start(@)
    make_inactive: () =>
        if @sidebar then @sidebar\clear()
        @sidebar = false
        @ui_components = false
        @script_prop = false

    pre_draw: () =>
        map_logic.pre_draw(@)

    draw: () =>
        map_logic.draw(@)

}
-- cacheidx = MapView.__index
-- MapView.__index = (k) => 
--     print "Map got ", k
--     return cacheidx(@, k)

return {:MapView}