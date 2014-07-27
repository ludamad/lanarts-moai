import drawText, drawTexture, colorEscapeCode, COL_RED, COL_YELLOW, COL_GREEN, COL_WHITE from require 'ui.Display'
import AptitudeTypes from require 'stats.stats'
import data from require 'core'
res = require 'resources'
import max, min from math

-- For sidebar
_trait_buffer = {}
_trait_key_buffer = {}
_trait_kinds = {"effectiveness", "damage", "resistance", "defence"}

escape = (col, text) -> colorEscapeCode(col) .. text

to_camelcase = (str) ->
    parts = str\split("_")
    for i,part in ipairs(parts) do
        parts[i] = part\lower()\gsub("^%l", string.upper)
    return (" ")\join(parts)

DEFAULT_FONT = res.get_bmfont('Liberation-Mono-12.fnt')

draw_value = (allowed, x, y, val) ->
	if not allowed then return 32
	local text, color
	if val == 0
		color = COL_YELLOW -- 'neutral' color
		text = ("+%g")\format(val)
	elseif val < 0
		color = COL_RED -- 'bad' color
		text = ("%g")\format(val)
	else
		color = COL_GREEN -- 'good' color
		text = ("+%g")\format(val)
	dx, dy = drawText {:x, :y, :text, font: DEFAULT_FONT, :color}
	return math.max(dx + 4, 32)

draw_stat_values = (x, y, aeff, adam, ares, adef, eff, dam, res, def) ->
	x += draw_value aeff, x, y, eff
	x += draw_value adam, x, y, dam
	x += draw_value ares, x, y, res
	x += draw_value adef, x, y, def

-- Comparator buffer
CBType = with newtype()
	.sum = (trait) =>
    	eff, dam = @eff[trait] or 0, @dam[trait] or 0
    	-- res, def = @res[trait] or 0, @def[trait] or 0
    	-- return max(eff,dam,res,def), min(eff,dam,res,def), (eff + dam + res + def)
    	return max(eff,dam), min(eff,dam), (eff + dam)
	.compare = (trait1, trait2) =>
		if @take_best
	    	m1, _, s1 = @sum(trait1)
	    	m2, _, s2 = @sum(trait2)
	    	if s1 == s2
	    		if m1 == m2
	    			return trait1 < trait2
	    		return m1 > m2
	    	return s1 > s2
	    else
	    	_, m1, s1 = @sum(trait1)
	    	_, m2, s2 = @sum(trait2)
	    	if s1 == s2
	    		if m1 == m2
	    			return trait1 > trait2
	    		return m1 < m2
	    	return s1 < s2

CB = CBType.create()

__cmp = (trait1, trait2) -> CB\compare(trait1, trait2)

STAT_SPRITE_MAP = {}
for aptitude_name,_ in pairs(AptitudeTypes.trainable_aptitudes)
	STAT_SPRITE_MAP[aptitude_name] = data.get_sprite('skicon-' .. aptitude_name\lower())

-- Pseudomethod. Takes a stat object.
-- Avoids memory allocation.
draw_stats = (x, y, x_interval, y_interval, best = true, n_start = 1, n_end = 12) =>
	table.clear(_trait_buffer)
    table.clear(_trait_key_buffer)
	traits, trait_keys = _trait_buffer, _trait_key_buffer

	for category,apts in pairs(@aptitudes)
        for trait,amnt in pairs(apts)
        	if AptitudeTypes.trainable_aptitudes[trait]
	        	traits[trait] = true

	for trait,amnt in pairs(_trait_buffer)
   		append trait_keys, trait

   	-- Ensure a consistent (alphabetical) ordering
    apts = @aptitudes
    CB.take_best = best
	CB.eff, CB.dam = apts.effectiveness, apts.damage
	CB.res, CB.def = apts.resistance, apts.defence

	table.sort(trait_keys, __cmp)

    for i = n_start, n_end
    	trait = trait_keys[i]
    	if trait == nil
    		return
    	eff, dam = apts.effectiveness[trait] or 0, apts.damage[trait] or 0
    	res, def = apts.resistance[trait] or 0, apts.defence[trait] or 0

    	{effectiveness: aeff, damage: adam, resistance: ares, defence: adef} = AptitudeTypes.allowed_aptitudes[trait]

    	apt_str = to_camelcase(trait)
    	STAT_SPRITE_MAP[trait]\draw(x,y)
    	drawText {x: x + 35, :y, text: apt_str, font: DEFAULT_FONT, color: COL_WHITE}
    	draw_stat_values x + 35, y + y_interval, aeff, adam, ares, adef, eff, dam, res, def

    	y += 32
    -- str = ("%s %s %s %s %s")\format
    --     if_color(C.GREEN, to_camelcase(trait), C.BOLD), 
    --     apt("effectiveness"), apt("damage"), apt("resistance"), apt("defence"),

return {:draw_stats}