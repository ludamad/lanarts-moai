import put_text, put_prop from require "@util_draw"
import max, min from math
res = require 'resources'
import data from require "core"

import COL_YELLOW, COL_DARK_GREEN from require "ui.Display"
import statsystem from require ''

FONT = res.get_bmfont 'Liberation-Mono-12.fnt'

STAT_SPRITE_MAP = {}
for attr in *statsystem.SKILL_ATTRIBUTES
    STAT_SPRITE_MAP[attr] = data.get_sprite('skicon-' .. attr)

SkillsUI = newtype {
    init: (stats, x, y) =>
        @stats = stats
        @x, @y = x - 72, y + 32
        @start, @_end = 1, 5

    draw_text: (textString, x, y) =>
        MOAIGfxDevice.setPenColor(1,1,1)
        MOAIDraw.drawText FONT, 12, textString, x, y, 1, 0, 0, 0, 0

    draw_sprite: (key, gridx, gridy) => 
        x, y = @grid_xy(gridx, gridy)
        return data.get_sprite(key)\draw(x, y)

    _count_skills: () => 
        cnt = 0
        for attr in *statsystem.SKILL_ATTRIBUTES
            if @stats.skill_levels[attr] > 0
                cnt += 1
        return cnt

    -- Performs either a predraw (object setup) or a draw (primitives only)
    draw: () =>
        x,y = @x, @y
        cnt = 0
        for attr in *statsystem.SKILL_ATTRIBUTES
            if @stats.skill_levels[attr] >= 0.1
                cnt += 1
            else
                continue
            if cnt > @_end
                break
            if cnt < @start
                continue
            name = statsystem.SKILL_ATTRIBUTE_NAMES[attr]

            STAT_SPRITE_MAP[attr]\draw(x,y)
            @draw_text name, x+34, y
            level = @stats.skill_levels[attr]
            level = math.floor(level*10)/10 -- Truncate past one decimal place
            @draw_text level, x+34, y+16
            y += 34
}

return {:SkillsUI}
