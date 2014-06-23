-------------------------------------------------------------------------------
-- Gamestate objects keep a history of their past. This enables backtracking
-- for purposes of client-side prediction. and retroactive game corrections.
--
-- For objects on the state path, we must store:
-- 	- Current simulated state
--  	- For certain objects, interpolated attributes, goes towards simulated state
--  - Last-known reality
--  - Projected reality, using stored actions for local player applied to last-known reality
-- 		- In the worst case, projected reality will lag behind simulated reality
-- 		- In this case, simulated reality will continue to be used, before a final swap
-------------------------------------------------------------------------------

BoolGridMeta = require('BoolGrid').metatable
import FieldOfView from require "core"
FOVMeta = FieldOfView.metatable

-- Stash globals as optimization
{:type, :getmetatable, :pairs} = _G
{clear: table_clear} = table

-- Lookup table for object state
-- A weak cache that associates objects with their previous states

STATE_LOOKUP_TABLE = {}

push_state = (_obj) -> 
	lookup = STATE_LOOKUP_TABLE

	-- Set up the 'saver' closure
	-- 'saver' only concerns mutable objects
	saver = (obj) ->
		if type(obj) ~= 'table' and type(obj) ~= 'userdata'
			return

		data = lookup[obj]
		if data == nil 
			data = {[0]: 1}
			lookup[obj] = data

		meta = getmetatable(obj)

		if meta == BoolGridMeta
			data[data[0]] = obj\clone()
			return
		elseif meta == FOVMeta
			-- pass
			return
		elseif type(obj) == 'userdata'
			return

		-- "Plain old Lua object"
		statelist = {}
		data[data[0]] = statelist
		i = 1
		for k,v in pairs(obj)
			saver(v)
			statelist[i] = k
			statelist[i+1] = v
			i += 2

	-- Save the object
	saver(_obj)

pop_state = (_obj) ->
	lookup = STATE_LOOKUP_TABLE

	-- Set up the 'loader' closure
	-- 'loader' only concerns mutable objects
	loader = (obj) ->
		if type(obj) ~= 'table' and type(obj) ~= 'userdata'
			return

		data = lookup[obj]

		meta = getmetatable(obj)

		if meta == BoolGridMeta
			data[data[0]]\copy(obj)
			return
		elseif meta == FOVMeta
			-- pass
			return
		elseif type(obj) == 'userdata'
			return

		-- "Plain old Lua object"
		statelist = data[data[0]] 
		i = 1
		table_clear(obj)
		while i < #statelist
			k, v = statelist[i], statelist[i+1]
			loader(v)
			rawset(obj, k,v)
			i += 2

	-- Save the object
	loader(_obj)

return {:push_state, :pop_state}