import put_text from require "@util_draw"
import max, min from math

-- For sidebar
_trait_buffer = {}
_trait_key_buffer = {}
_trait_kinds = {"effectiveness", "damage", "resistance", "defence"}

to_camelcase = (str) ->
    parts = str\split("_")
    for i,part in ipairs(parts) do
        parts[i] = part\lower()\gsub("^%l", string.upper)
    return (" ")\join(parts)

put_value = (layer, styles, x, y, val) ->
	local text, style
	if val == 0
		style = styles[1] -- 'neutral' style
		text = ("+%g")\format(val)
	elseif val < 0
		style = styles[2] -- 'bad' style
		text = ("-%g")\format(val)
	else
		style = styles[3] -- 'good' style
		text = ("+%g")\format(val)
	textbox = put_text layer, style, text, x, y
	x1, _, x2, _ = textbox\getStringBounds(1, #text)
	return math.max((x2 - x1) + 4, 32)

put_stat_values = (layer, styles, x, y, eff, dam, res, def) ->
	x += put_value layer, styles, x, y, eff
	x += put_value layer, styles, x, y, dam
	x += put_value layer, styles, x, y, res
	x += put_value layer, styles, x, y, def

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

-- Pseudomethod. Takes a stat object.
-- Avoids memory allocation.
put_stats = (layer, styles, x, y, x_interval, y_interval, best = true, n_start = 1, n_end = 10) =>
	table.clear(_trait_buffer)
    table.clear(_trait_key_buffer)
	traits, trait_keys = _trait_buffer, _trait_key_buffer

	for category,apts in pairs(@aptitudes)
        for trait,amnt in pairs(apts)
        	traits[trait] = true

	for trait,amnt in pairs(_trait_buffer)
   		append trait_keys, trait

   	-- Ensure at consistent (alphabetical) ordering
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

    	apt_str = to_camelcase(trait)
    	text = put_text layer, styles[1], apt_str, x, y
    	put_stat_values layer, styles, x, y + y_interval, eff, dam, res, def

    	y += y_interval * 2
    -- str = ("%s %s %s %s %s")\format
    --     if_color(C.GREEN, to_camelcase(trait), C.BOLD), 
    --     apt("effectiveness"), apt("damage"), apt("resistance"), apt("defence"),

return {:put_stats}